//
//  GuidedPrayerComposer.swift
//  DevotionLock
//
//  Template-first guided prayers with optional Chaplain enrichment.
//

import Foundation
import Combine

@MainActor
final class GuidedPrayerComposer: ObservableObject {
    static let shared = GuidedPrayerComposer()

    @Published private(set) var beats: [LiturgyBeat] = []
    @Published private(set) var isEnriching = false
    @Published private(set) var didEnrich = false

    private var sessionCache: [String: [LiturgyBeat]] = [:]

    func load(prayer: GuidedPrayer?, context: LiturgyWeaveContext) {
        let fallback: [LiturgyBeat]
        if let prayer {
            fallback = LiturgyWeaveBuilder.wovenBeats(prayer: prayer, context: context)
        } else {
            fallback = LiturgyWeaveBuilder.wovenBeats(context: context)
        }

        beats = fallback
        didEnrich = false

        let key = cacheKey(prayer: prayer, context: context)
        if let cached = sessionCache[key] {
            beats = cached
            didEnrich = true
            return
        }

        Task { await enrichIfPossible(key: key, fallback: fallback, prayer: prayer, context: context) }
    }

    func reset() {
        beats = []
        isEnriching = false
        didEnrich = false
    }

    private func cacheKey(prayer: GuidedPrayer?, context: LiturgyWeaveContext) -> String {
        let prayerID = prayer?.id ?? "morning-weave"
        let focus = context.focus?.rawValue ?? "none"
        let day = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        return "\(prayerID)|\(context.mood)|\(focus)|\(day)"
    }

    private func enrichIfPossible(
        key: String,
        fallback: [LiturgyBeat],
        prayer: GuidedPrayer?,
        context: LiturgyWeaveContext
    ) async {
        guard AuthManager.shared.isAuthenticated else { return }
        isEnriching = true
        defer { isEnriching = false }

        do {
            let enriched = try await requestEnrichedBeats(prayer: prayer, context: context, fallback: fallback)
            guard !enriched.isEmpty else { return }
            sessionCache[key] = enriched
            beats = enriched
            didEnrich = true
        } catch {
            #if DEBUG
            print("GuidedPrayerComposer enrich failed: \(error)")
            #endif
        }
    }

    private func requestEnrichedBeats(
        prayer: GuidedPrayer?,
        context: LiturgyWeaveContext,
        fallback: [LiturgyBeat]
    ) async throws -> [LiturgyBeat] {
        let sections = prayer?.liturgicalSections ?? fallback.map(\.section)
        let count = max(sections.count, fallback.count)
        let name = context.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let focus = context.focus?.label ?? "this day"

        let prompt = """
        Write a guided prayer as JSON only — no markdown, no commentary.
        Return an array of exactly \(count) objects: {"section":"...","line":"..."}.
        Mood: \(context.mood). Focus: \(focus).
        Each line must be a short spoken prayer the user repeats aloud in first person, addressing God directly (Lord/Father/Thank you).
        Never narrate about the user in third person. No coaching language like "you are held."
        Sections in order: \(sections.joined(separator: ", ")).
        \(name.isEmpty ? "" : "The person's name is \(name) — weave gently into one line only if natural.")
        Keep each line under 130 characters. Personal, gentle, not preachy.
        """

        let message = ChaplainMessage(role: .user, text: prompt)
        let chaplainContext = ChaplainContextBuilder.build(intent: "guided_prayer", ephemeral: true)
        let stream = try await ChaplainService.shared.streamReply(
            conversationID: nil,
            messages: [message],
            context: chaplainContext
        )

        var response = ""
        var leakedConversationID: UUID?
        for try await event in stream {
            switch event {
            case .conversationID(let id):
                leakedConversationID = id
            case .token(let token):
                response += token
            default:
                break
            }
        }

        if let leakedConversationID {
            await ConversationRepository.shared.deleteConversation(id: leakedConversationID)
        }

        return try parseBeats(from: response, fallback: fallback, context: context)
    }

    private func parseBeats(
        from response: String,
        fallback: [LiturgyBeat],
        context: LiturgyWeaveContext
    ) throws -> [LiturgyBeat] {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = trimmed.firstIndex(of: "["),
              let end = trimmed.lastIndex(of: "]") else {
            return fallback
        }

        let jsonSlice = String(trimmed[start...end])
        guard let data = jsonSlice.data(using: .utf8) else { return fallback }

        struct Payload: Decodable {
            let section: String
            let line: String
        }

        let payloads = try JSONDecoder().decode([Payload].self, from: data)
        guard payloads.count >= 2 else { return fallback }

        return payloads.map { item in
            let line = item.line.trimmingCharacters(in: .whitespacesAndNewlines)
            let highlight: String?
            if line.localizedCaseInsensitiveContains(context.mood) {
                highlight = context.mood.lowercased()
            } else if let focus = context.focus?.label.lowercased(),
                      line.localizedCaseInsensitiveContains(focus) {
                highlight = focus
            } else {
                highlight = nil
            }
            return LiturgyBeat(
                section: item.section.trimmingCharacters(in: .whitespacesAndNewlines),
                fullText: line,
                highlight: highlight
            )
        }
    }
}
