//
//  DevotionOfflineQueue.swift
//  DevotionLock
//

import Foundation

struct DevotionSyncPayload: Codable, Equatable {
    let userId: UUID
    let sessionDate: String
    let mood: String
    let emotion: String?
    let reason: String?
    let onMind: String?
    let plans: String?
    let gratitude: [String]
    let affirmation: String?
    let savedVersePhrase: String?
    let verseReference: String?
    let focusTags: [String]
    let voiceTranscript: String?
    let summaryInsight: String
    let journalPreview: String
    let timeLabel: String
    let enqueuedAt: Date

    static func from(
        userId: UUID,
        draft: JournalDraft,
        verseReference: String?,
        summary: DaySummary
    ) -> DevotionSyncPayload {
        let gratitude = draft.gratitudeItems
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return DevotionSyncPayload(
            userId: userId,
            sessionDate: DaySummary.todayKey,
            mood: draft.mood,
            emotion: draft.emotion.nilIfBlank,
            reason: draft.reason.nilIfBlank,
            onMind: draft.onMind.nilIfBlank,
            plans: draft.plans.nilIfBlank,
            gratitude: gratitude,
            affirmation: draft.affirmation.nilIfBlank,
            savedVersePhrase: draft.savedVersePhrase.nilIfBlank,
            verseReference: verseReference,
            focusTags: draft.focusTags,
            voiceTranscript: draft.reflectionText.nilIfBlank,
            summaryInsight: summary.insight,
            journalPreview: summary.journalPreview,
            timeLabel: summary.timeLabel,
            enqueuedAt: Date()
        )
    }
}

struct DevotionSyncOperation: Codable, Identifiable, Equatable {
    let id: UUID
    let payload: DevotionSyncPayload
}

@MainActor
final class DevotionOfflineQueue {
    static let shared = DevotionOfflineQueue()

    private enum Keys {
        static let pending = "devotionSyncPendingOps"
        static let cache = "devotionSyncCache"
    }

    private(set) var pendingCount = 0

    func enqueue(
        draft: JournalDraft,
        verseReference: String?,
        summary: DaySummary
    ) {
        guard let userId = AuthManager.shared.userId else { return }

        let payload = DevotionSyncPayload.from(
            userId: userId,
            draft: draft,
            verseReference: verseReference,
            summary: summary
        )
        cacheLatest(payload)

        var ops = loadPending()
        ops.removeAll { $0.payload.sessionDate == payload.sessionDate && $0.payload.userId == payload.userId }
        ops.append(DevotionSyncOperation(id: UUID(), payload: payload))
        savePending(ops)
    }

    func cacheLatest(_ payload: DevotionSyncPayload) {
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: Keys.cache)
        }
    }

    func cachedLatest() -> DevotionSyncPayload? {
        guard let data = UserDefaults.standard.data(forKey: Keys.cache),
              let payload = try? JSONDecoder().decode(DevotionSyncPayload.self, from: data) else {
            return nil
        }
        return payload
    }

    func pendingOperations() -> [DevotionSyncOperation] {
        loadPending()
    }

    func remove(_ id: UUID) {
        var ops = loadPending()
        ops.removeAll { $0.id == id }
        savePending(ops)
    }

    private func loadPending() -> [DevotionSyncOperation] {
        guard let data = UserDefaults.standard.data(forKey: Keys.pending),
              let ops = try? JSONDecoder().decode([DevotionSyncOperation].self, from: data) else {
            pendingCount = 0
            return []
        }
        pendingCount = ops.count
        return ops
    }

    private func savePending(_ ops: [DevotionSyncOperation]) {
        pendingCount = ops.count
        if let data = try? JSONEncoder().encode(ops) {
            UserDefaults.standard.set(data, forKey: Keys.pending)
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
