//
//  PrayerWallRepository.swift
//  DevotionLock
//

import Foundation
import Supabase

private struct PrayerWallNoteRow: Codable {
    let id: UUID
    let userId: UUID
    let kind: String
    let text: String
    let focusTag: String?
    let rotation: Double
    let tintIndex: Int
    let answeredAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case kind, text
        case focusTag = "focus_tag"
        case rotation
        case tintIndex = "tint_index"
        case answeredAt = "answered_at"
        case createdAt = "created_at"
    }

    init(note: PrayerWallNote, userId: UUID) {
        id = note.id
        self.userId = userId
        kind = note.kind.rawValue
        text = note.text
        focusTag = nil
        rotation = note.rotation
        tintIndex = note.tintIndex
        answeredAt = note.answeredAt
        createdAt = note.createdAt
    }

    var localNote: PrayerWallNote {
        PrayerWallNote(
            id: id,
            kind: PrayerNoteKind(rawValue: kind) ?? .request,
            text: text,
            createdAt: createdAt,
            answeredAt: answeredAt,
            rotation: rotation,
            tintIndex: tintIndex
        )
    }
}

@MainActor
final class PrayerWallOfflineQueue {
    static let shared = PrayerWallOfflineQueue()

    private enum Keys {
        static let pending = "prayerWallSyncPendingIDs"
        static let synced = "prayerWallSyncedIDs"
    }

    func enqueue(_ noteID: UUID) {
        var pending = loadPending()
        if !pending.contains(noteID) { pending.append(noteID) }
        savePending(pending)
    }

    func markSynced(_ noteID: UUID) {
        var synced = loadSynced()
        synced.insert(noteID)
        saveSynced(synced)
        var pending = loadPending()
        pending.removeAll { $0 == noteID }
        savePending(pending)
    }

    func pendingIDs() -> [UUID] { loadPending() }

    func enqueueUnsynced(from notes: [PrayerWallNote]) {
        let synced = loadSynced()
        let pending = Set(loadPending())
        for note in notes where !synced.contains(note.id) && !pending.contains(note.id) {
            enqueue(note.id)
        }
    }

    private func loadPending() -> [UUID] {
        guard let data = UserDefaults.standard.data(forKey: Keys.pending),
              let ids = try? JSONDecoder().decode([UUID].self, from: data) else { return [] }
        return ids
    }

    private func savePending(_ ids: [UUID]) {
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: Keys.pending)
        }
    }

    private func loadSynced() -> Set<UUID> {
        guard let data = UserDefaults.standard.data(forKey: Keys.synced),
              let ids = try? JSONDecoder().decode([UUID].self, from: data) else { return [] }
        return Set(ids)
    }

    private func saveSynced(_ ids: Set<UUID>) {
        if let data = try? JSONEncoder().encode(Array(ids)) {
            UserDefaults.standard.set(data, forKey: Keys.synced)
        }
    }
}

@MainActor
final class PrayerWallRepository {
    static let shared = PrayerWallRepository()

    func enqueue(_ note: PrayerWallNote) {
        guard AuthManager.shared.isAuthenticated else { return }
        PrayerWallOfflineQueue.shared.enqueue(note.id)
        Task { await flushPending() }
    }

    func flushPending() async {
        guard AuthManager.shared.isAuthenticated, let userId = AuthManager.shared.userId else { return }

        PrayerWallOfflineQueue.shared.enqueueUnsynced(from: PrayerWallStore.shared.notes)

        for noteID in PrayerWallOfflineQueue.shared.pendingIDs() {
            guard let note = PrayerWallStore.shared.notes.first(where: { $0.id == noteID }) else { continue }
            do {
                let row = PrayerWallNoteRow(note: note, userId: userId)
                try await SupabaseManager.client
                    .from("prayer_wall_notes")
                    .upsert(row, onConflict: "id")
                    .execute()
                PrayerWallOfflineQueue.shared.markSynced(noteID)
            } catch {
                #if DEBUG
                print("PrayerWallRepository sync failed: \(error)")
                #endif
                break
            }
        }
    }

    func pullRemote() async {
        guard AuthManager.shared.isAuthenticated else { return }

        do {
            let rows: [PrayerWallNoteRow] = try await SupabaseManager.client
                .from("prayer_wall_notes")
                .select("id, user_id, kind, text, focus_tag, rotation, tint_index, answered_at, created_at")
                .order("created_at", ascending: false)
                .limit(200)
                .execute()
                .value

            PrayerWallStore.shared.mergeRemoteNotes(rows.map(\.localNote))
        } catch {
            #if DEBUG
            print("PrayerWallRepository pull failed: \(error)")
            #endif
        }
    }

    func deleteRemote(_ id: UUID) async {
        guard AuthManager.shared.isAuthenticated else { return }
        try? await SupabaseManager.client
            .from("prayer_wall_notes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
