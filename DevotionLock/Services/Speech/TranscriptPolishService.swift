//
//  TranscriptPolishService.swift
//  DevotionLock
//
//  Gentle transcript shaping — on-device first, optional ephemeral AI refinement.
//

import Foundation

@MainActor
enum TranscriptPolishService {
    /// Fast, private tidy — always available offline.
    static func tidyOnDevice(_ raw: String) -> String {
        JournalTranscriptOrganizer.organize(raw)
    }

    /// On-device tidy, then optional AI pass for longer reflections when signed in.
    static func tidyGently(_ raw: String) async -> String {
        let baseline = tidyOnDevice(raw)
        return await tidyWithAIRefinement(baseline: baseline, raw: raw)
    }

    /// AI refinement only — use when the UI already has an on-device baseline.
    static func tidyWithAIRefinement(baseline: String, raw: String) async -> String {
        guard raw.count >= 48, AuthManager.shared.isAuthenticated else { return baseline }

        do {
            let refined = try await requestAIFormat(raw: raw)
            let cleaned = ChaplainMessageFormatter.plainText(refined)
            return cleaned.isEmpty ? baseline : cleaned
        } catch {
            return baseline
        }
    }

    private static func requestAIFormat(raw: String) async throws -> String {
        let prompt = """
        Format this spoken journal reflection for readability only.
        Keep every idea the person expressed. Only add punctuation, capitalization, and paragraph breaks.
        Remove filler words like um and uh. Do not add advice, questions, or new content.
        Return plain text only — no markdown, no commentary.

        Transcript:
        \(raw)
        """

        let message = ChaplainMessage(role: .user, text: prompt)
        let context = ChaplainContextBuilder.build(intent: "transcript_polish", ephemeral: true)
        let stream = try await ChaplainService.shared.streamReply(
            conversationID: nil,
            messages: [message],
            context: context
        )

        var response = ""
        var leakedID: UUID?
        for try await event in stream {
            switch event {
            case .conversationID(let id):
                leakedID = id
            case .token(let token):
                response += token
            default:
                break
            }
        }

        if let leakedID {
            await ConversationRepository.shared.deleteConversation(id: leakedID)
        }

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
