//
//  WidgetSnapshot.swift
//  DevotionLockShared
//

import Foundation

struct WidgetPrayerNoteSnapshot: Codable, Identifiable, Hashable {
    let id: String
    let kind: String
    let text: String
    let tintIndex: Int
    let rotation: Double
}

struct WidgetSnapshot: Codable {
    var currentStreak: Int
    var isCompletedToday: Bool
    var weekCompletionFlags: [Bool]
    var shieldEnabled: Bool
    var quoteText: String
    var quoteReference: String
    var prayerRequestCount: Int
    var prayerAnsweredCount: Int
    var prayerNotes: [WidgetPrayerNoteSnapshot]
    var rhythmCompletionFlags: [Bool]
    var answeredCelebrationText: String?
    var answeredCelebrationActive: Bool
    var updatedAt: Date

    static let placeholder = WidgetSnapshot(
        currentStreak: 3,
        isCompletedToday: false,
        weekCompletionFlags: [true, true, true, false, false, false, false],
        shieldEnabled: true,
        quoteText: "Be still, and know that I am God.",
        quoteReference: "Psalm 46:10",
        prayerRequestCount: 2,
        prayerAnsweredCount: 1,
        prayerNotes: [
            WidgetPrayerNoteSnapshot(id: "1", kind: "request", text: "Peace for my family.", tintIndex: 0, rotation: -2),
            WidgetPrayerNoteSnapshot(id: "2", kind: "reminder", text: "God is closer than my next breath.", tintIndex: 2, rotation: 1.5),
        ],
        rhythmCompletionFlags: [true, true, false, false],
        answeredCelebrationText: nil,
        answeredCelebrationActive: false,
        updatedAt: Date()
    )
}

enum WidgetSnapshotStore {
    static func load() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: DevotionAppGroup.identifier),
              let data = defaults.data(forKey: SharedStorageKey.widgetSnapshot),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .placeholder }
        return snapshot
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: DevotionAppGroup.identifier),
              let data = try? JSONEncoder().encode(snapshot)
        else { return }
        defaults.set(data, forKey: SharedStorageKey.widgetSnapshot)
    }
}

enum SharedQuoteProvider {
    static let quotes: [(text: String, reference: String)] = [
        ("Be still, and know that I am God.", "Psalm 46:10"),
        ("The Lord is my shepherd; I shall not want.", "Psalm 23:1"),
        ("Come to me, all you who are weary, and I will give you rest.", "Matthew 11:28"),
        ("You will keep in perfect peace those whose minds are steadfast.", "Isaiah 26:3"),
        ("Cast all your anxiety on him because he cares for you.", "1 Peter 5:7"),
        ("May the God of hope fill you with all joy and peace as you trust in him.", "Romans 15:13"),
        ("The sacred is woven into the ordinary.", "Tish Harrison Warren"),
        ("Peace I leave with you; my peace I give you.", "John 14:27"),
    ]

    static var today: (text: String, reference: String) {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let quote = quotes[day % quotes.count]
        return quote
    }
}
