//
//  DaySummary.swift
//  DevotionLock
//

import Foundation

struct DaySummary: Codable, Identifiable, Equatable {
    var id: String { dateKey }
    let dateKey: String
    let mood: String
    let moodEmoji: String
    let timeLabel: String
    let insight: String
    let journalPreview: String
    let verseReference: String?
    let focusTags: [String]?
    let affirmation: String?
    let savedVersePhrase: String?

    static func from(draft: JournalDraft, verseReference: String?) -> DaySummary {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeLabel = formatter.string(from: Date())
        let previewParts = [
            draft.affirmation.trimmingCharacters(in: .whitespacesAndNewlines),
            draft.emotion.trimmingCharacters(in: .whitespacesAndNewlines),
            draft.onMind.trimmingCharacters(in: .whitespacesAndNewlines),
        ].filter { !$0.isEmpty }

        return DaySummary(
            dateKey: DaySummary.todayKey,
            mood: draft.mood,
            moodEmoji: MoodCatalog.emoji(for: draft.mood),
            timeLabel: timeLabel,
            insight: DaySummary.insight(for: draft),
            journalPreview: previewParts.isEmpty ? "Morning devotion completed" : previewParts.joined(separator: " · "),
            verseReference: verseReference,
            focusTags: draft.focusTags.isEmpty ? nil : draft.focusTags,
            affirmation: draft.affirmation.isEmpty ? nil : draft.affirmation,
            savedVersePhrase: draft.savedVersePhrase.isEmpty ? nil : draft.savedVersePhrase
        )
    }

    static var todayKey: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    static func insight(for draft: JournalDraft) -> String {
        let mood = draft.mood.lowercased()
        let onMind = draft.onMind.trimmingCharacters(in: .whitespacesAndNewlines)
        let affirmation = draft.affirmation.trimmingCharacters(in: .whitespacesAndNewlines)
        let tagLabel = draft.selectedFocusTags.first?.label.lowercased()

        if !affirmation.isEmpty, let tagLabel {
            return "A \(mood) morning with \(tagLabel) in view — \"\(affirmation)\" is a gentle intention to carry."
        }
        if !affirmation.isEmpty {
            return "You named your intention: \"\(affirmation)\" — a \(mood) way to begin."
        }
        if onMind.isEmpty {
            return "You showed up \(mood) today — a gentle beginning before the world rushes in."
        }
        if let tagLabel {
            return "A \(mood) morning, with \(onMind.lowercased()) on your heart and \(tagLabel) in focus."
        }
        return "A \(mood) morning, with \(onMind.lowercased()) on your heart. Your Chaplain is walking with you in this."
    }
}

struct DevotionFinishResult: Equatable, Identifiable {
    var id: String { summary.dateKey }
    let streak: Int
    let mood: String
    let isFirstCompletionEver: Bool
    let summary: DaySummary
}

struct MorningWrappedStats: Equatable {
    let morningsThisWeek: Int
    let topMood: String
    let topMoodEmoji: String
    let currentStreak: Int
    let totalDays: Int
    let highlightInsight: String
    let weeklyNarrative: String?
    let weekLabels: [String]
    let weekCompleted: [Bool]
}
