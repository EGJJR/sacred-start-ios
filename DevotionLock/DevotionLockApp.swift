//
//  DevotionLockApp.swift
//  DevotionLock
//

import SwiftUI

@main
struct DevotionLockApp: App {
    init() {
        // Eager init so AuthClient picks up `emitLocalSessionAsInitialSession: true` before any listeners attach.
        _ = SupabaseManager.client
        AppFont.logAvailability()
        #if DEBUG
        DesignTour.activateFromLaunchArgumentIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
