//
//  CircleMilestoneStore.swift
//  DevotionLock
//

import Foundation
import Observation

@Observable
@MainActor
final class CircleMilestoneStore {
    static let shared = CircleMilestoneStore()

    private enum Keys {
        static let celebrated = "circleCelebratedMilestones"
    }

    private var celebrated: [String: Set<String>] = [:]

    init() {
        load()
    }

    func newlyReached(
        circleId: UUID,
        stats: CircleCollectiveStats,
        previousStats: CircleCollectiveStats
    ) -> [CircleMilestoneKind] {
        CircleMilestoneKind.allCases.filter { kind in
            kind.isReached(by: stats)
                && !kind.isReached(by: previousStats)
                && !hasCelebrated(kind, circleId: circleId)
        }
    }

    func uncelebratedReached(circleId: UUID, stats: CircleCollectiveStats) -> [CircleMilestoneKind] {
        CircleMilestoneKind.allCases.filter { kind in
            kind.isReached(by: stats) && !hasCelebrated(kind, circleId: circleId)
        }
    }

    func hasCelebrated(_ kind: CircleMilestoneKind, circleId: UUID) -> Bool {
        celebrated[circleId.uuidString]?.contains(kind.rawValue) ?? false
    }

    func markCelebrated(_ kind: CircleMilestoneKind, circleId: UUID) {
        var set = celebrated[circleId.uuidString] ?? []
        set.insert(kind.rawValue)
        celebrated[circleId.uuidString] = set
        persist()
    }

    func hasUncelebratedMilestones(circleId: UUID, stats: CircleCollectiveStats) -> Bool {
        !uncelebratedReached(circleId: circleId, stats: stats).isEmpty
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Keys.celebrated),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return }
        celebrated = decoded.mapValues { Set($0) }
    }

    private func persist() {
        let encoded = celebrated.mapValues { Array($0) }
        guard let data = try? JSONEncoder().encode(encoded) else { return }
        UserDefaults.standard.set(data, forKey: Keys.celebrated)
    }
}
