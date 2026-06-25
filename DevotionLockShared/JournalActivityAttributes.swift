//
//  JournalActivityAttributes.swift
//  DevotionLockShared
//

import ActivityKit
import Foundation

enum SanctuaryLiveSession: String, Codable, Hashable {
    case morningDevotion
    case prayerBreath
}

struct JournalActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var session: SanctuaryLiveSession
        var stepIndex: Int
        var stepTitle: String
        var totalSteps: Int
        var elapsedSeconds: Int
        var breathsRemaining: Int
        var breathPhaseLabel: String
    }

    var sessionTitle: String
}
