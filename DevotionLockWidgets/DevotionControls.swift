//
//  DevotionControls.swift
//  DevotionLockWidgets
//

import AppIntents
import SwiftUI
import WidgetKit

struct BeginDevotionIntent: AppIntent {
    static var title: LocalizedStringResource = "Begin Devotion"
    static var description = IntentDescription("Start today's guided devotion.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        if let url = DevotionDeepLink.url(host: .journal) {
            return .result(opensIntent: OpenURLIntent(url))
        }
        return .result()
    }
}

struct AddPrayerControlIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Prayer"
    static var description = IntentDescription("Pin a prayer request to your wall.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        PendingWidgetActionStore.set(.addPrayerRequest)
        if let url = DevotionDeepLink.url(host: .addPrayer, query: ["kind": "request"]) {
            return .result(opensIntent: OpenURLIntent(url))
        }
        return .result()
    }
}

struct TodaysVerseIntent: AppIntent {
    static var title: LocalizedStringResource = "Today's Verse"
    static var description = IntentDescription("Open today's verse for reflection.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        let snapshot = WidgetSnapshotStore.load()
        if let url = DevotionDeepLink.url(host: .chaplain, query: ["prompt": snapshot.quoteText]) {
            return .result(opensIntent: OpenURLIntent(url))
        }
        return .result()
    }
}

@available(iOS 18.0, *)
struct BeginDevotionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "BeginDevotionControl") {
            ControlWidgetButton(action: BeginDevotionIntent()) {
                Label("Begin devotion", systemImage: "sun.horizon.fill")
            }
        }
        .displayName("Begin Devotion")
        .description("Start today's guided devotion without hunting for the app.")
    }
}

@available(iOS 18.0, *)
struct AddPrayerControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "AddPrayerControl") {
            ControlWidgetButton(action: AddPrayerControlIntent()) {
                Label("Add prayer", systemImage: "hands.sparkles.fill")
            }
        }
        .displayName("Add Prayer")
        .description("Pin a new request on your prayer wall.")
    }
}

@available(iOS 18.0, *)
struct TodaysVerseControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "TodaysVerseControl") {
            ControlWidgetButton(action: TodaysVerseIntent()) {
                Label("Today's verse", systemImage: "text.quote")
            }
        }
        .displayName("Today's Verse")
        .description("Open today's passage for reflection.")
    }
}
