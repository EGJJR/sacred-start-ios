//
//  StreakIdentity.swift
//  DevotionLock
//

import Foundation

enum SanctuaryGrowthStage: String, CaseIterable, Identifiable, Codable {
    case seed
    case sprout
    case bloom
    case sanctuary

    var id: String { rawValue }

    var milestoneDays: Int? {
        switch self {
        case .seed: nil
        case .sprout: 7
        case .bloom: 30
        case .sanctuary: 100
        }
    }
}

struct StreakIdentity: Equatable {
    static let milestoneThresholds = [7, 30, 100]

    let streakDays: Int
    let stage: SanctuaryGrowthStage
    let statusName: String
    let nextMilestone: Int?
    let progressToNext: Double

    static func identity(for streakDays: Int) -> StreakIdentity {
        let stage: SanctuaryGrowthStage
        let statusName: String

        switch streakDays {
        case 100...:
            stage = .sanctuary
            statusName = "Sanctuary Keeper"
        case 30...:
            stage = .bloom
            statusName = "Steady in the Word"
        case 7...:
            stage = .sprout
            statusName = "Morning Anchor"
        default:
            stage = .seed
            statusName = "Morning devotee"
        }

        let nextMilestone = milestoneThresholds.first { streakDays < $0 }
        let progressToNext: Double
        if let next = nextMilestone {
            let previous = milestoneThresholds.last { $0 < next } ?? 0
            let span = max(1, next - previous)
            progressToNext = min(1, Double(streakDays - previous) / Double(span))
        } else {
            progressToNext = 1
        }

        return StreakIdentity(
            streakDays: streakDays,
            stage: stage,
            statusName: statusName,
            nextMilestone: nextMilestone,
            progressToNext: progressToNext
        )
    }

    static func milestoneCelebrationCopy(days: Int) -> String {
        switch days {
        case 7: "One full week of showing up. That's a real sanctuary rhythm taking root."
        case 30: "A month of devotion. Notice how your journal already holds a shape."
        case 100: "One hundred mornings. What a witness to patience and presence."
        default: "\(days) days of showing up. Keep honoring this practice."
        }
    }
}
