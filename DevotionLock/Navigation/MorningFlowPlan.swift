//
//  MorningFlowPlan.swift
//  DevotionLock
//
//  Choreography for morning devotion — which steps run per tier/path,
//  stable progress, and human-readable phase labels.
//

import Foundation

enum MorningStep: Equatable {
    case arrival
    case pulse
    case prompt
    case reveal
    case depth
    case complete
}

enum MorningPath: String, Codable, Equatable {
    case reflect
    case pray
}

/// Resolves the step sequence and progress model for a morning session.
struct MorningFlowPlan: Equatable {
    let tier: MorningTier
    let path: MorningPath

    var steps: [MorningStep] {
        var result: [MorningStep] = [.arrival, .pulse]
        if path == .reflect {
            result.append(.prompt)
        }
        result.append(.reveal)
        if tier.includesDepth {
            result.append(.depth)
        }
        result.append(.complete)
        return result
    }

    /// Longest path for this tier — used before the user commits pray vs reflect.
    static func maxStepCount(tier: MorningTier) -> Int {
        MorningFlowPlan(tier: tier, path: .reflect).steps.count
    }

    func phaseLabel(for step: MorningStep) -> String {
        switch step {
        case .arrival: "Arrive"
        case .pulse: "Check in"
        case .prompt: "Reflect"
        case .reveal: "Word"
        case .depth: "Go deeper"
        case .complete: "Complete"
        }
    }

    func progress(stepIndex: Int) -> CGFloat {
        let total = steps.count
        guard total > 0 else { return 0 }
        return CGFloat(min(stepIndex + 1, total)) / CGFloat(total)
    }

    func displayIndex(stepIndex: Int) -> (current: Int, total: Int) {
        (min(stepIndex + 1, steps.count), steps.count)
    }
}
