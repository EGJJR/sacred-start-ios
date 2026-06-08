//
//  JournalActivityAttributes.swift
//  DevotionLockShared
//

import ActivityKit
import Foundation

struct JournalActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var stepIndex: Int
        var stepTitle: String
        var totalSteps: Int
        var elapsedSeconds: Int
    }

    var sessionTitle: String
}
