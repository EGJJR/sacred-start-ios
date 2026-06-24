//
//  AppModels.swift
//  test1
//

import Foundation
import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case home
    case conversations
    case insights
    case profile

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .home: "Home"
        case .conversations: "Journal"
        case .insights: "Chaplain"
        case .profile: "You"
        }
    }

    /// Mobbin-informed tab icons — thin stroke inactive, filled active
    /// Home: timeline/today (Alan Today, ABY Timeline)
    /// Journal: open book (Liven Journey, ABY Journal)
    /// Chaplain: companion chat (Liven Companion)
    /// Profile: avatar circle (Alan profile slot)
    var icon: String {
        switch self {
        case .home: "clock"
        case .conversations: "book.pages"
        case .insights: "ellipsis.bubble"
        case .profile: "person.crop.circle"
        }
    }

    var iconSelected: String {
        switch self {
        case .home: "clock.fill"
        case .conversations: "book.pages.fill"
        case .insights: "ellipsis.bubble.fill"
        case .profile: "person.crop.circle.fill"
        }
    }

    var activeTint: Color {
        switch self {
        case .home: ABY.Color.pillOrange
        case .conversations: ABY.Color.pillPink
        case .insights: ABY.Color.meshAmber
        case .profile: ABY.Color.meshGold
        }
    }
}

struct Conversation: Identifiable, Hashable {
    let id: UUID
    let remoteID: UUID?
    let tag: String
    let timeAgo: String
    let timelineTime: String
    let emoji: String
    let moodEmoji: String
    let moodLabel: String
    let title: String
    let preview: String
    let duration: String
    let isToday: Bool
    let transcript: [TranscriptSegment]
    let recordedAt: Date?

    init(
        id: UUID = UUID(),
        remoteID: UUID? = nil,
        tag: String,
        timeAgo: String,
        timelineTime: String,
        emoji: String,
        moodEmoji: String,
        moodLabel: String,
        title: String,
        preview: String,
        duration: String,
        isToday: Bool,
        transcript: [TranscriptSegment],
        recordedAt: Date? = nil
    ) {
        self.id = id
        self.remoteID = remoteID
        self.tag = tag
        self.timeAgo = timeAgo
        self.timelineTime = timelineTime
        self.emoji = emoji
        self.moodEmoji = moodEmoji
        self.moodLabel = moodLabel
        self.title = title
        self.preview = preview
        self.duration = duration
        self.isToday = isToday
        self.transcript = transcript
        self.recordedAt = recordedAt
    }

    static let samples: [Conversation] = designTourSamples

    static var designTourSamples: [Conversation] {
        let calendar = Calendar.current
        let now = Date()
        return [
            Conversation(
                tag: "Scripture",
                timeAgo: "23 min ago",
                timelineTime: "7:18 AM",
                emoji: "🙏",
                moodEmoji: "😊",
                moodLabel: "Grateful",
                title: "Morning Devotion — Cast Your Cares",
                preview: "There's something grounded about how you're moving through this moment — noticing what feels good and reflecting on what matters.",
                duration: "7m 22s",
                isToday: true,
                transcript: [
                    TranscriptSegment(speaker: "You", text: "I'm feeling overwhelmed about the week ahead.", timestamp: "0:04"),
                    TranscriptSegment(speaker: "Chaplain", text: "Cast all your anxiety on him because he cares for you. Let's sit with that together.", timestamp: "0:18"),
                    TranscriptSegment(speaker: "You", text: "I want to trust that more deeply today.", timestamp: "0:42"),
                ],
                recordedAt: calendar.date(byAdding: .minute, value: -23, to: now)
            ),
            Conversation(
                tag: "Voice",
                timeAgo: "Yesterday",
                timelineTime: "6:42 AM",
                emoji: "🍃",
                moodEmoji: "🍃",
                moodLabel: "Peaceful",
                title: "Voice Journal — Grateful Heart",
                preview: "Morning voice journaling on family, health, and quiet moments of grace before the day began.",
                duration: "12m 08s",
                isToday: false,
                transcript: [
                    TranscriptSegment(speaker: "You", text: "Today I'm grateful for the stillness before everyone wakes up.", timestamp: "0:02"),
                    TranscriptSegment(speaker: "Chaplain", text: "Gratitude opens the heart. What else is stirring in you this morning?", timestamp: "0:15"),
                ],
                recordedAt: calendar.date(byAdding: .day, value: -1, to: now)
            ),
            Conversation(
                tag: "Reflection",
                timeAgo: "Yesterday",
                timelineTime: "7:05 AM",
                emoji: "✨",
                moodEmoji: "🌅",
                moodLabel: "Hopeful",
                title: "Morning Intentions & Gratitude",
                preview: "A quiet moment of reflection on priorities, presence, and what matters most today.",
                duration: "4m 51s",
                isToday: false,
                transcript: [
                    TranscriptSegment(speaker: "You", text: "Today I want to be fully present in every conversation.", timestamp: "0:00"),
                    TranscriptSegment(speaker: "Chaplain", text: "That's a beautiful intention. Presence is a practice, not a destination.", timestamp: "0:12"),
                ],
                recordedAt: calendar.date(byAdding: .hour, value: -30, to: now)
            ),
            Conversation(
                tag: "Prayer",
                timeAgo: "2 days ago",
                timelineTime: "6:30 PM",
                emoji: "🕯️",
                moodEmoji: "🙏",
                moodLabel: "Reflective",
                title: "Evening Examen & Prayer",
                preview: "Reviewing the day with gentle awareness and closing prayer.",
                duration: "8m 12s",
                isToday: false,
                transcript: [
                    TranscriptSegment(speaker: "You", text: "Where did I feel closest to God today?", timestamp: "0:00"),
                ],
                recordedAt: calendar.date(byAdding: .day, value: -2, to: now)
            ),
        ]
    }
}

struct TranscriptSegment: Identifiable, Hashable {
    let id = UUID()
    let speaker: String
    let text: String
    let timestamp: String
}

struct AIInsight: Identifiable {
    let id: UUID
    let title: String
    let body: String
    let icon: String
    let accent: Color

    init(id: UUID = UUID(), title: String, body: String, icon: String, accent: Color) {
        self.id = id
        self.title = title
        self.body = body
        self.icon = icon
        self.accent = accent
    }

    static let samples: [AIInsight] = [
        AIInsight(
            title: "Morning Intention",
            body: "You've returned to devotion 5 mornings this week. Your language is growing more intentional and grounded.",
            icon: "sun.horizon.fill",
            accent: DevotionTheme.sage
        ),
        AIInsight(
            title: "Season of Peace",
            body: "You've mentioned feeling overwhelmed twice — your reflections are turning toward rest and trust.",
            icon: "leaf.fill",
            accent: DevotionTheme.teal
        ),
        AIInsight(
            title: "Gratitude Thread",
            body: "Voice journaling is revealing a pattern of thankfulness, especially around family and quiet moments.",
            icon: "heart.fill",
            accent: DevotionTheme.deepBlue
        ),
    ]
}

struct DailyFocus {
    let mood: String
    let verse: String
    let reference: String
    let author: String?

    init(mood: String, verse: String, reference: String, author: String? = nil) {
        self.mood = mood
        self.verse = verse
        self.reference = reference
        self.author = author
    }

    static var today: DailyFocus {
        let passage = SpiritualPassageCatalog.today
        return DailyFocus(
            mood: "Today's focus",
            verse: passage.text,
            reference: passage.reference,
            author: passage.author
        )
    }

    static let sample = today
}

struct StreakData {
    let currentStreak: Int
    let completedDays: [Bool]

    static let sample = StreakData(
        currentStreak: 5,
        completedDays: [true, true, true, true, true, false, false]
    )
}

enum SpiritualDepth: String {
    case deepening = "Deepening"
    case emerging = "Emerging"
    case new = "New"
}

struct SpiritualTheme: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let strength: CGFloat
    let depth: SpiritualDepth
    let color: Color

    static let samples: [SpiritualTheme] = [
        SpiritualTheme(label: "Presence", icon: "leaf.fill", strength: 0.85, depth: .deepening, color: DevotionTheme.sage),
        SpiritualTheme(label: "Gratitude", icon: "heart.fill", strength: 0.62, depth: .emerging, color: DevotionTheme.teal),
        SpiritualTheme(label: "Scripture", icon: "book.fill", strength: 0.38, depth: .new, color: DevotionTheme.deepBlue),
    ]
}
