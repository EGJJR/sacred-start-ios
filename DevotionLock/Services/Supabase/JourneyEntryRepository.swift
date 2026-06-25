//
//  JourneyEntryRepository.swift
//  DevotionLock
//

import Foundation
import Supabase

struct JourneyEntryMetadata: Codable, Equatable {
    var mood: String?
    var moodEmoji: String?
    var focusTags: [String]?
    var verseReference: String?
    var source: String?

    enum CodingKeys: String, CodingKey {
        case mood
        case moodEmoji = "mood_emoji"
        case focusTags = "focus_tags"
        case verseReference = "verse_reference"
        case source
    }

    static func from(_ entry: JourneyTimelineEntry) -> JourneyEntryMetadata {
        let moodLabel = entry.moodEmoji.flatMap { emoji in
            MoodCatalog.options.first { $0.emoji == emoji }?.label
        }
        return JourneyEntryMetadata(
            mood: moodLabel,
            moodEmoji: entry.moodEmoji,
            focusTags: entry.focusTags.isEmpty ? nil : entry.focusTags,
            verseReference: entry.verseReference,
            source: entry.kind.rawValue
        )
    }
}

struct JourneyEntrySyncPayload: Codable, Equatable {
    let id: UUID
    let userId: UUID
    let kind: String
    let title: String
    let body: String
    let metadata: JourneyEntryMetadata
    let createdAt: Date

    static func from(entry: JourneyTimelineEntry, userId: UUID) -> JourneyEntrySyncPayload {
        JourneyEntrySyncPayload(
            id: entry.id,
            userId: userId,
            kind: entry.kind.rawValue,
            title: entry.title,
            body: entry.body ?? "",
            metadata: .from(entry),
            createdAt: entry.createdAt
        )
    }
}

struct JourneyEntrySyncOperation: Codable, Identifiable, Equatable {
    let id: UUID
    let payload: JourneyEntrySyncPayload
}

private struct JourneyEntryInsertRow: Encodable {
    let id: UUID
    let userId: UUID
    let kind: String
    let title: String
    let body: String
    let metadata: JourneyEntryMetadata
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case kind, title, body, metadata
        case createdAt = "created_at"
    }

    init(payload: JourneyEntrySyncPayload) {
        id = payload.id
        userId = payload.userId
        kind = payload.kind
        title = payload.title
        body = payload.body
        metadata = payload.metadata
        createdAt = payload.createdAt
    }
}

@MainActor
final class JourneyEntryOfflineQueue {
    static let shared = JourneyEntryOfflineQueue()

    private enum Keys {
        static let pending = "journeyEntrySyncPendingOps"
        static let syncedIDs = "journeyEntrySyncedIDs"
    }

    private(set) var pendingCount = 0

    func enqueue(_ entry: JourneyTimelineEntry) {
        guard let userId = AuthManager.shared.userId else { return }

        let payload = JourneyEntrySyncPayload.from(entry: entry, userId: userId)
        var ops = loadPending()
        ops.removeAll { $0.id == payload.id }
        ops.append(JourneyEntrySyncOperation(id: payload.id, payload: payload))
        savePending(ops)
    }

    func enqueueUnsynced(from entries: [JourneyTimelineEntry]) {
        guard AuthManager.shared.userId != nil else { return }

        let synced = loadSyncedIDs()
        let pending = Set(loadPending().map(\.id))
        for entry in entries where !synced.contains(entry.id) && !pending.contains(entry.id) {
            enqueue(entry)
        }
    }

    func pendingOperations() -> [JourneyEntrySyncOperation] {
        loadPending()
    }

    func markSynced(_ id: UUID) {
        var synced = loadSyncedIDs()
        synced.insert(id)
        saveSyncedIDs(synced)

        var ops = loadPending()
        ops.removeAll { $0.id == id }
        savePending(ops)
    }

    private func loadPending() -> [JourneyEntrySyncOperation] {
        guard let data = UserDefaults.standard.data(forKey: Keys.pending),
              let ops = try? JSONDecoder().decode([JourneyEntrySyncOperation].self, from: data)
        else {
            pendingCount = 0
            return []
        }
        pendingCount = ops.count
        return ops
    }

    private func savePending(_ ops: [JourneyEntrySyncOperation]) {
        pendingCount = ops.count
        if let data = try? JSONEncoder().encode(ops) {
            UserDefaults.standard.set(data, forKey: Keys.pending)
        }
    }

    private func loadSyncedIDs() -> Set<UUID> {
        guard let data = UserDefaults.standard.data(forKey: Keys.syncedIDs),
              let ids = try? JSONDecoder().decode([UUID].self, from: data)
        else { return [] }
        return Set(ids)
    }

    private func saveSyncedIDs(_ ids: Set<UUID>) {
        if let data = try? JSONEncoder().encode(Array(ids)) {
            UserDefaults.standard.set(data, forKey: Keys.syncedIDs)
        }
    }
}

@MainActor
final class JourneyEntryRepository {
    static let shared = JourneyEntryRepository()

    func enqueue(_ entry: JourneyTimelineEntry) {
        guard AuthManager.shared.isAuthenticated else { return }
        JourneyEntryOfflineQueue.shared.enqueue(entry)
        Task { await flushPending() }
    }

    func flushPending() async {
        guard AuthManager.shared.isAuthenticated else { return }

        JourneyEntryOfflineQueue.shared.enqueueUnsynced(
            from: JourneyTimelineStore.shared.entries
        )

        for op in JourneyEntryOfflineQueue.shared.pendingOperations() {
            do {
                try await pushPayload(op.payload)
                JourneyEntryOfflineQueue.shared.markSynced(op.id)
            } catch {
                #if DEBUG
                print("JourneyEntryRepository sync failed: \(error)")
                #endif
                break
            }
        }
    }

    func pullRemote() async {
        guard AuthManager.shared.isAuthenticated else { return }

        do {
            let journeyRows: [RemoteJourneyEntry] = try await SupabaseManager.client
                .from("journey_entries")
                .select("id, kind, title, body, metadata, created_at")
                .order("created_at", ascending: false)
                .limit(200)
                .execute()
                .value

            JourneyTimelineStore.shared.mergeRemoteEntries(journeyRows.map(\.timelineEntry))
        } catch {
            SyncErrorFilter.logPullFailure("JourneyEntryRepository", error)
        }
    }

    private func pushPayload(_ payload: JourneyEntrySyncPayload) async throws {
        let row = JourneyEntryInsertRow(payload: payload)
        try await SupabaseManager.client
            .from("journey_entries")
            .upsert(row, onConflict: "id")
            .execute()
    }
}

// MARK: - Remote pull models

struct RemoteJourneyEntry: Decodable {
    let id: UUID
    let kind: String
    let title: String
    let body: String?
    let metadata: JourneyEntryMetadata?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, kind, title, body, metadata
        case createdAt = "created_at"
    }

    var timelineEntry: JourneyTimelineEntry {
        let emoji = metadata?.moodEmoji
            ?? metadata?.mood.map { MoodCatalog.emoji(for: $0) }

        return JourneyTimelineEntry(
            id: id,
            createdAt: createdAt,
            kind: JourneyEntryKind(rawValue: kind) ?? .devotion,
            title: title,
            body: body,
            moodEmoji: emoji,
            focusTags: metadata?.focusTags ?? [],
            verseReference: metadata?.verseReference
        )
    }
}
