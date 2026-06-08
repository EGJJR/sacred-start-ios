//
//  DevotionSessionRepository.swift
//  DevotionLock
//

import Foundation
import Supabase

private struct DevotionSessionRow: Encodable {
    let userId: UUID
    let sessionDate: String
    let mood: String?
    let emotion: String?
    let reason: String?
    let onMind: String?
    let plans: String?
    let gratitude: [String]
    let affirmation: String?
    let savedVersePhrase: String?
    let verseReference: String?
    let focusTags: [String]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sessionDate = "session_date"
        case mood
        case emotion
        case reason
        case onMind = "on_mind"
        case plans
        case gratitude
        case affirmation
        case savedVersePhrase = "saved_verse_phrase"
        case verseReference = "verse_reference"
        case focusTags = "focus_tags"
    }
}

private struct DevotionCompletionRow: Encodable {
    let userId: UUID
    let completedDate: String
    let mood: String?
    let summary: SummaryPayload

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case completedDate = "completed_date"
        case mood
        case summary
    }

    struct SummaryPayload: Encodable {
        let insight: String
        let journalPreview: String
        let verseReference: String?
        let focusTags: [String]?
        let affirmation: String?
        let savedVersePhrase: String?
        let voiceTranscript: String?
        let timeLabel: String

        enum CodingKeys: String, CodingKey {
            case insight
            case journalPreview = "journal_preview"
            case verseReference = "verse_reference"
            case focusTags = "focus_tags"
            case affirmation
            case savedVersePhrase = "saved_verse_phrase"
            case voiceTranscript = "voice_transcript"
            case timeLabel = "time_label"
        }
    }
}

@MainActor
final class DevotionSessionRepository {
    static let shared = DevotionSessionRepository()

    func syncCompletion(
        draft: JournalDraft,
        verseReference: String?,
        summary: DaySummary
    ) async {
        guard AuthManager.shared.isAuthenticated else { return }

        DevotionOfflineQueue.shared.enqueue(
            draft: draft,
            verseReference: verseReference,
            summary: summary
        )
        await flushPending()
    }

    func flushPending() async {
        guard AuthManager.shared.isAuthenticated else { return }

        for op in DevotionOfflineQueue.shared.pendingOperations() {
            do {
                try await pushPayload(op.payload)
                DevotionOfflineQueue.shared.remove(op.id)
            } catch {
                #if DEBUG
                print("DevotionSessionRepository sync failed: \(error)")
                #endif
                break
            }
        }
    }

    func pullRemote() async {
        guard AuthManager.shared.isAuthenticated else { return }

        do {
            let completions: [RemoteCompletion] = try await SupabaseManager.client
                .from("devotion_completions")
                .select("completed_date, mood, summary")
                .order("completed_date", ascending: false)
                .limit(120)
                .execute()
                .value

            if !completions.isEmpty {
                let mapped = completions.map { row in
                    (
                        dateKey: row.completedDate,
                        mood: row.mood,
                        summary: row.summary?.daySummary(for: row.completedDate, mood: row.mood)
                    )
                }
                StreakManager.shared.mergeRemoteCompletions(mapped)
            }

            await pullRemoteSessions()
        } catch {
            #if DEBUG
            print("DevotionSessionRepository pull failed: \(error)")
            #endif
        }
    }

    func pullRemoteSessions() async {
        guard AuthManager.shared.isAuthenticated else { return }

        do {
            let sessions: [RemoteDevotionSession] = try await SupabaseManager.client
                .from("devotion_sessions")
                .select("session_date, mood, emotion, on_mind, affirmation, saved_verse_phrase, verse_reference, focus_tags, gratitude")
                .order("session_date", ascending: false)
                .limit(120)
                .execute()
                .value

            for session in sessions {
                StreakManager.shared.mergeRemoteSession(
                    dateKey: session.sessionDate,
                    mood: session.mood,
                    journalPreview: session.journalPreview,
                    verseReference: session.verseReference,
                    focusTags: session.focusTags,
                    affirmation: session.affirmation,
                    savedVersePhrase: session.savedVersePhrase
                )
            }
        } catch {
            #if DEBUG
            print("DevotionSessionRepository session pull failed: \(error)")
            #endif
        }
    }

    private func pushPayload(_ payload: DevotionSyncPayload) async throws {
        let sessionRow = DevotionSessionRow(
            userId: payload.userId,
            sessionDate: payload.sessionDate,
            mood: payload.mood,
            emotion: payload.emotion,
            reason: payload.reason,
            onMind: payload.onMind,
            plans: payload.plans,
            gratitude: payload.gratitude,
            affirmation: payload.affirmation,
            savedVersePhrase: payload.savedVersePhrase,
            verseReference: payload.verseReference,
            focusTags: payload.focusTags
        )

        let completionRow = DevotionCompletionRow(
            userId: payload.userId,
            completedDate: payload.sessionDate,
            mood: payload.mood,
            summary: .init(
                insight: payload.summaryInsight,
                journalPreview: payload.journalPreview,
                verseReference: payload.verseReference,
                focusTags: payload.focusTags.isEmpty ? nil : payload.focusTags,
                affirmation: payload.affirmation,
                savedVersePhrase: payload.savedVersePhrase,
                voiceTranscript: payload.voiceTranscript,
                timeLabel: payload.timeLabel
            )
        )

        try await SupabaseManager.client
            .from("devotion_sessions")
            .upsert(sessionRow, onConflict: "user_id,session_date")
            .execute()

        try await SupabaseManager.client
            .from("devotion_completions")
            .upsert(completionRow, onConflict: "user_id,completed_date")
            .execute()
    }
}

// MARK: - Remote pull models

private struct RemoteCompletion: Decodable {
    let completedDate: String
    let mood: String?
    let summary: RemoteSummary?

    enum CodingKeys: String, CodingKey {
        case completedDate = "completed_date"
        case mood
        case summary
    }
}

private struct RemoteSummary: Decodable {
    let insight: String?
    let journalPreview: String?
    let verseReference: String?
    let focusTags: [String]?
    let affirmation: String?
    let savedVersePhrase: String?
    let timeLabel: String?

    enum CodingKeys: String, CodingKey {
        case insight
        case journalPreview = "journal_preview"
        case verseReference = "verse_reference"
        case focusTags = "focus_tags"
        case affirmation
        case savedVersePhrase = "saved_verse_phrase"
        case timeLabel = "time_label"
    }

    func daySummary(for dateKey: String, mood: String?) -> DaySummary {
        DaySummary(
            dateKey: dateKey,
            mood: mood ?? "Peaceful",
            moodEmoji: MoodCatalog.emoji(for: mood ?? "Peaceful"),
            timeLabel: timeLabel ?? dateKey,
            insight: insight ?? "Morning devotion completed.",
            journalPreview: journalPreview ?? "Morning devotion completed",
            verseReference: verseReference,
            focusTags: focusTags,
            affirmation: affirmation,
            savedVersePhrase: savedVersePhrase
        )
    }
}

private struct RemoteDevotionSession: Decodable {
    let sessionDate: String
    let mood: String?
    let emotion: String?
    let onMind: String?
    let affirmation: String?
    let savedVersePhrase: String?
    let verseReference: String?
    let focusTags: [String]?
    let gratitude: [String]?

    enum CodingKeys: String, CodingKey {
        case sessionDate = "session_date"
        case mood, emotion
        case onMind = "on_mind"
        case affirmation
        case savedVersePhrase = "saved_verse_phrase"
        case verseReference = "verse_reference"
        case focusTags = "focus_tags"
        case gratitude
    }

    var journalPreview: String {
        let parts = [
            affirmation,
            emotion,
            onMind,
            gratitude?.filter { !$0.isEmpty }.joined(separator: " · "),
            savedVersePhrase
        ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return parts.isEmpty ? "Morning devotion completed" : parts.joined(separator: " · ")
    }
}

