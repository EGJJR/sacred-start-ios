//
//  DailyRhythmRepository.swift
//  DevotionLock
//

import Foundation
import Supabase

private struct DailyRhythmRow: Encodable {
    let userId: UUID
    let completionDate: String
    let ringKind: String
    let completedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case completionDate = "completion_date"
        case ringKind = "ring_kind"
        case completedAt = "completed_at"
    }
}

private struct RemoteDailyRhythmRow: Decodable {
    let completionDate: String
    let ringKind: String

    enum CodingKeys: String, CodingKey {
        case completionDate = "completion_date"
        case ringKind = "ring_kind"
    }
}

@MainActor
final class DailyRhythmRepository {
    static let shared = DailyRhythmRepository()

    func syncCompletion(ring: DailyRhythmRing, on date: Date = Date()) {
        guard AuthManager.shared.isAuthenticated, let userId = AuthManager.shared.userId else { return }
        let row = DailyRhythmRow(
            userId: userId,
            completionDate: dateKey(for: date),
            ringKind: ring.rawValue,
            completedAt: Date()
        )
        Task {
            try? await SupabaseManager.client
                .from("daily_rhythm_completions")
                .upsert(row, onConflict: "user_id,completion_date,ring_kind")
                .execute()
        }
    }

    func pullRemote() async {
        guard AuthManager.shared.isAuthenticated else { return }

        do {
            let rows: [RemoteDailyRhythmRow] = try await SupabaseManager.client
                .from("daily_rhythm_completions")
                .select("completion_date, ring_kind")
                .order("completion_date", ascending: false)
                .limit(120)
                .execute()
                .value

            DailyRhythmStore.shared.mergeRemoteCompletions(
                rows.map { (completionDate: $0.completionDate, ringKind: $0.ringKind) }
            )
        } catch {
            #if DEBUG
            print("DailyRhythmRepository pull failed: \(error)")
            #endif
        }
    }

    private func dateKey(for date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
