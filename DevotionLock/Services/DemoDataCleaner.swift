//
//  DemoDataCleaner.swift
//  DevotionLock
//

import Foundation

enum DemoDataCleaner {
    @MainActor
    static func clearIfAuthenticated() {
        guard AuthManager.shared.isAuthenticated else { return }

        UserDefaults.standard.set(true, forKey: "devotionStreakDidSeedDemo")
        UserDefaults.standard.set(true, forKey: "prayerWallDidSeed")
        UserDefaults.standard.set(true, forKey: "prayerCircleDidSeed")

        StreakManager.shared.clearDemoData()
        PrayerWallStore.shared.clearDemoData()
        PrayerCircleStore.shared.clearDemoData()
    }
}
