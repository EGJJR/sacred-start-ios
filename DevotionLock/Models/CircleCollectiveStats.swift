//
//  CircleCollectiveStats.swift
//  DevotionLock
//

import Foundation

struct CircleCollectiveStats: Equatable {
    let prayersLifted: Int
    let testimoniesCelebrated: Int

    static func compute(from posts: [CirclePost]) -> CircleCollectiveStats {
        CircleCollectiveStats(
            prayersLifted: posts.reduce(0) { $0 + $1.prayingCount },
            testimoniesCelebrated: posts.filter { $0.kind == .testimony }.count
        )
    }
}

enum CircleMilestoneKind: String, Codable, CaseIterable, Identifiable {
    case prayers25
    case prayers50
    case prayers100
    case testimonies5
    case testimonies10
    case testimonies25

    var id: String { rawValue }

    var threshold: Int {
        switch self {
        case .prayers25: 25
        case .prayers50: 50
        case .prayers100: 100
        case .testimonies5: 5
        case .testimonies10: 10
        case .testimonies25: 25
        }
    }

    var isPrayerMilestone: Bool {
        switch self {
        case .prayers25, .prayers50, .prayers100: true
        default: false
        }
    }

    func isReached(by stats: CircleCollectiveStats) -> Bool {
        if isPrayerMilestone {
            return stats.prayersLifted >= threshold
        }
        return stats.testimoniesCelebrated >= threshold
    }

    func celebrationMessage(circleName: String) -> String {
        switch self {
        case .prayers25: "Your circle lifted 25 prayers together"
        case .prayers50: "Your circle lifted 50 prayers together"
        case .prayers100: "Your circle lifted 100 prayers together"
        case .testimonies5: "\(circleName) celebrated 5 answered prayers"
        case .testimonies10: "\(circleName) celebrated 10 answered prayers"
        case .testimonies25: "\(circleName) celebrated 25 answered prayers"
        }
    }

    func proximityMessage(stats: CircleCollectiveStats) -> String? {
        if isPrayerMilestone {
            let remaining = threshold - stats.prayersLifted
            guard remaining > 0, remaining <= 5 else { return nil }
            return "You're \(remaining) prayer\(remaining == 1 ? "" : "s") from \(threshold) together — keep lifting"
        }
        let remaining = threshold - stats.testimoniesCelebrated
        guard remaining > 0, remaining <= 2 else { return nil }
        return "\(remaining) more testimony\(remaining == 1 ? "" : "ies") until \(threshold) celebrated together"
    }
}
