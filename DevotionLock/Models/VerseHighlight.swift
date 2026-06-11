//
//  VerseHighlight.swift
//  DevotionLock
//

import SwiftUI

/// Fable-style categorized highlight colors (Mobbin: Important, Quote, Favorite, Poetic).
enum ScriptureHighlightColor: String, CaseIterable, Identifiable, Codable {
    case peace
    case promise
    case favorite
    case courage

    var id: String { rawValue }

    var label: String {
        switch self {
        case .peace: "Peace"
        case .promise: "Promise"
        case .favorite: "Favorite"
        case .courage: "Courage"
        }
    }

    var swatch: Color {
        switch self {
        case .peace: ABY.Color.pillTeal
        case .promise: Color(red: 0.95, green: 0.82, blue: 0.38)
        case .favorite: ABY.Color.pillPurple
        case .courage: ABY.Color.pillOrange
        }
    }

    var background: Color {
        swatch.opacity(0.22)
    }
}

struct VerseHighlight: Identifiable, Codable, Equatable {
    let id: UUID
    let bookSlug: String
    let chapter: Int
    let startVerse: Int
    let endVerse: Int
    let colorID: String
    let createdAt: Date

    var color: ScriptureHighlightColor {
        ScriptureHighlightColor(rawValue: colorID) ?? .peace
    }

    func contains(_ verse: Int) -> Bool {
        verse >= startVerse && verse <= endVerse
    }
}
