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

    var label: String {
        switch self {
        case .request: "Prayer request"
        case .testimony: "Testimony"
        case .reminder: "Reminder"
        }
    }

    var icon: String {
        switch self {
        case .request: "hands.sparkles.fill"
        case .testimony: "checkmark.seal.fill"
        case .reminder: "bell.fill"
        }
    }

    var tint: Color {
        switch self {
        case .request: ABY.Color.pillPurple
        case .testimony: ABY.Color.orbSage
        case .reminder: ABY.Color.pillOrange
        }
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

struct PrayerCircle: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var inviteCode: String
    let createdAt: Date
    var memberIds: [UUID]
    var coverPaletteIndex: Int

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
