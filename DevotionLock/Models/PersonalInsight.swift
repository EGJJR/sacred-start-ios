//
//  PersonalInsight.swift
//  DevotionLock
//

import SwiftUI

enum PersonalInsightKind: String, Codable, CaseIterable {
    case moodTrend
    case recurringTheme
    case streakNudge
    case streakMilestone
    case weeklyPattern
    case encouragement

    var icon: String {
        switch self {
        case .moodTrend: "chart.line.uptrend.xyaxis"
        case .recurringTheme: "text.magnifyingglass"
        case .streakNudge: "flame.fill"
        case .streakMilestone: "star.fill"
        case .weeklyPattern: "calendar"
        case .encouragement: "leaf.fill"
        }
    }

    var accent: Color {
        switch self {
        case .moodTrend: ABY.Color.pillTeal
        case .recurringTheme: ABY.Color.pillPurple
        case .streakNudge: ABY.Color.pillOrange
        case .streakMilestone: ABY.Color.accentDot
        case .weeklyPattern: ABY.Color.pillPink
        case .encouragement: ABY.Color.orbSage
        }
    }
}

struct PersonalInsight: Identifiable, Equatable {
    let id: String
    let kind: PersonalInsightKind
    let title: String
    let body: String
    let priority: Int

    var icon: String { kind.icon }
    var accent: Color { kind.accent }

    func asAIInsight() -> AIInsight {
        AIInsight(title: title, body: body, icon: icon, accent: accent)
    }
}

struct ThemeSignal: Equatable {
    let id: String
    let label: String
    let count: Int
}

struct MoodTrendSnapshot: Equatable {
    let dominantMood: String
    let count: Int
    let windowDays: Int
    let totalEntries: Int
}

struct LocalUserPatternSnapshot: Equatable {
    let insights: [PersonalInsight]
    let moodTrend: MoodTrendSnapshot?
    let topThemes: [ThemeSignal]
    let streakDays: Int
    let completedToday: Bool
    let morningsThisWeek: Int

    var headlineInsight: PersonalInsight? {
        insights.max(by: { $0.priority < $1.priority })
    }

    var contextLines: [String] {
        insights.prefix(4).map(\.body)
    }
}
