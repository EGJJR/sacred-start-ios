//
//  WidgetIntents.swift
//  DevotionLockWidgets
//

import AppIntents
import WidgetKit

struct AddPrayerRequestIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Prayer Request"
    static var description = IntentDescription("Pin a new prayer request to your wall.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        PendingWidgetActionStore.set(.addPrayerRequest)
        WidgetCenter.shared.reloadAllTimelines()
        if let url = DevotionDeepLink.url(host: .addPrayer, query: ["kind": "request"]) {
            return .result(opensIntent: OpenURLIntent(url))
        }
        return .result()
    }
}

struct AddPrayerReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Reminder"
    static var description = IntentDescription("Pin a reminder to yourself on your prayer wall.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        PendingWidgetActionStore.set(.addReminder)
        WidgetCenter.shared.reloadAllTimelines()
        if let url = DevotionDeepLink.url(host: .addPrayer, query: ["kind": "reminder"]) {
            return .result(opensIntent: OpenURLIntent(url))
        }
        return .result()
    }
}

struct OpenPrayerWallIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Prayer Wall"
    static var description = IntentDescription("Open your prayer wall.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        PendingWidgetActionStore.set(.openPrayerWall)
        if let url = DevotionDeepLink.url(host: .prayerWall) {
            return .result(opensIntent: OpenURLIntent(url))
        }
        return .result()
    }
}
