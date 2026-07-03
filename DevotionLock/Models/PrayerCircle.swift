//
//  PrayerCircle.swift
//  DevotionLock
//

import Foundation
import SwiftUI

enum CirclePostKind: String, Codable, CaseIterable {
    case request
    case testimony
    case reminder
    case reflection

    var label: String {
        switch self {
        case .request: "Prayer request"
        case .testimony: "Testimony"
        case .reminder: "Reminder"
        case .reflection: "Reflection"
        }
    }

    var icon: String {
        switch self {
        case .request: "hands.sparkles.fill"
        case .testimony: "checkmark.seal.fill"
        case .reminder: "bell.fill"
        case .reflection: "text.quote"
        }
    }

    var tint: Color {
        switch self {
        case .request: ABY.Color.pillPurple
        case .testimony: ABY.Color.orbSage
        case .reminder: ABY.Color.pillOrange
        case .reflection: ABY.Color.pillTeal
        }
    }
}

enum CircleChallengeKind: String, Codable, CaseIterable, Identifiable {
    case gratitude
    case scripture

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gratitude: "Gratitude"
        case .scripture: "Scripture"
        }
    }
}

struct CircleChallengeTemplate: Identifiable {
    let id: String
    let kind: CircleChallengeKind
    let title: String
    let prompt: String
    let verseReference: String?

    static let curated: [CircleChallengeTemplate] = [
        CircleChallengeTemplate(
            id: "gratitude-week",
            kind: .gratitude,
            title: "Gratitude challenge",
            prompt: "Share one thing you noticed God doing this week.",
            verseReference: nil
        ),
        CircleChallengeTemplate(
            id: "philippians",
            kind: .scripture,
            title: "Peace in anxiety",
            prompt: "Share one line from this passage that landed for you.",
            verseReference: "Philippians 4:6-7"
        ),
        CircleChallengeTemplate(
            id: "psalm23",
            kind: .scripture,
            title: "The Lord is my shepherd",
            prompt: "What phrase from Psalm 23 speaks to you right now?",
            verseReference: "Psalm 23"
        ),
        CircleChallengeTemplate(
            id: "romans828",
            kind: .scripture,
            title: "All things work together",
            prompt: "Share one insight from Romans 8:28 for your circle.",
            verseReference: "Romans 8:28"
        ),
    ]
}

struct CircleChallenge: Identifiable, Codable, Equatable {
    let id: UUID
    let circleId: UUID
    var title: String
    var prompt: String
    var verseReference: String?
    let kind: CircleChallengeKind
    let startsAt: Date
    let endsAt: Date
    let createdAt: Date

    var isActive: Bool {
        let now = Date()
        return now >= startsAt && now <= endsAt
    }

    var isEnded: Bool {
        Date() > endsAt
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endsAt).day ?? 0)
    }
}

struct CircleMember: Identifiable, Codable, Equatable {
    let id: UUID
    var displayName: String
    var avatarHue: Double
    var isCurrentUser: Bool

    var avatarColor: Color {
        Color(hue: avatarHue, saturation: 0.45, brightness: 0.88)
    }

    var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }
}

struct CircleThoughtTemplate: Identifiable, Equatable {
    let id: String
    let kind: CirclePostKind
    let title: String
    let prompt: String
    let madLibPrefix: String?
    let madLibSuffix: String?

    static let starters: [CircleThoughtTemplate] = [
        CircleThoughtTemplate(
            id: "request-heart",
            kind: .request,
            title: "Prayer request",
            prompt: "What would you like your circle to pray for?",
            madLibPrefix: "Please pray for ",
            madLibSuffix: ". I'm carrying this in my heart."
        ),
        CircleThoughtTemplate(
            id: "request-family",
            kind: .request,
            title: "Family",
            prompt: "Share a family need your circle can lift up.",
            madLibPrefix: "My family needs prayer for ",
            madLibSuffix: "."
        ),
        CircleThoughtTemplate(
            id: "reminder-verse",
            kind: .reminder,
            title: "Encouragement",
            prompt: "Drop a verse or reminder for the group.",
            madLibPrefix: "A verse on my heart today: ",
            madLibSuffix: nil
        ),
        CircleThoughtTemplate(
            id: "gratitude",
            kind: .request,
            title: "Gratitude",
            prompt: "What are you thankful for right now?",
            madLibPrefix: "I'm grateful for ",
            madLibSuffix: " today."
        ),
        CircleThoughtTemplate(
            id: "testimony",
            kind: .testimony,
            title: "Answered prayer",
            prompt: "Celebrate something God did, big or small.",
            madLibPrefix: "God answered my prayer about ",
            madLibSuffix: "."
        ),
    ]
}

struct PrayerCircle: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var inviteCode: String
    let createdAt: Date
    var memberIds: [UUID]
    var coverPaletteIndex: Int
    /// Auth user id of the circle creator (from remote `created_by` or local create).
    var creatorUserId: UUID?

    static let coverPalettes: [[Color]] = [
        [Color(red: 0.98, green: 0.88, blue: 0.72), Color(red: 0.72, green: 0.82, blue: 0.96), Color(red: 0.96, green: 0.78, blue: 0.62)],
        [Color(red: 0.88, green: 0.94, blue: 0.98), Color(red: 0.62, green: 0.78, blue: 0.92), Color(red: 0.78, green: 0.88, blue: 0.96)],
        [Color(red: 0.94, green: 0.90, blue: 0.98), Color(red: 0.76, green: 0.68, blue: 0.90), Color(red: 0.90, green: 0.82, blue: 0.96)],
    ]

    var coverColors: [Color] {
        Self.coverPalettes[coverPaletteIndex % Self.coverPalettes.count]
    }
}

struct CircleEncouragement: Identifiable, Codable, Equatable {
    let id: UUID
    let authorName: String
    let text: String
    let createdAt: Date
}

struct CirclePost: Identifiable, Codable, Equatable {
    let id: UUID
    let circleId: UUID
    let authorId: UUID
    var authorName: String
    var isAnonymous: Bool
    let kind: CirclePostKind
    let text: String
    let createdAt: Date
    var focusTag: String?
    var sourceNoteId: UUID?
    var verseReference: String?
    var challengeId: UUID?
    var prayingMemberIds: [UUID]
    var encouragements: [CircleEncouragement]

    var displayAuthor: String {
        isAnonymous ? "Someone in your circle" : authorName
    }

    var prayingCount: Int { prayingMemberIds.count }

    var focusLabel: String? {
        guard let focusTag, let tag = FocusTag(rawValue: focusTag) else { return nil }
        return tag.label
    }
}

enum CircleFeedSort: String, CaseIterable, Identifiable {
    case newest
    case testimonies

    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest: "Newest posts"
        case .testimonies: "Testimonies"
        }
    }
}

enum CircleShareVisibility: String, CaseIterable, Identifiable {
    case named
    case anonymous

    var id: String { rawValue }

    var label: String {
        switch self {
        case .named: "Share as me"
        case .anonymous: "Share anonymously"
        }
    }
}
