//
//  DemoDataCleaner.swift
//  DevotionLock
//

import Foundation

enum DemoDataCleaner {
    private static let clearedAfterAuthKey = "demoDataClearedForAuthenticatedUser"

    /// Strips one-time guest/demo seed data the first time a real session is established.
    /// Must not run on every `tokenRefreshed` — that was wiping real local streak & prayer data.
    @MainActor
    static func clearIfAuthenticated() {
        guard AuthManager.shared.isAuthenticated else { return }
        guard !UserDefaults.standard.bool(forKey: clearedAfterAuthKey) else { return }

        StreakManager.shared.clearDemoData()
        PrayerWallStore.shared.clearDemoData()
        PrayerCircleStore.shared.clearDemoData()

        UserDefaults.standard.set(true, forKey: clearedAfterAuthKey)
    }
}
