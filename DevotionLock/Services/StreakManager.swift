//
//  StreakManager.swift
//  DevotionLock
//

import Foundation
import Observation

@Observable
@MainActor
final class StreakManager {
    static let shared = StreakManager()

    private enum Keys {
        static let completionDates = "devotionCompletionDates"
        static let entryCount = "devotionEntryCount"
        static let moodByDate = "devotionMoodByDate"
        static let didSeedDemo = "devotionStreakDidSeedDemo"
        static let daySummaries = "devotionDaySummaries"
        static let seenMilestoneDays = "devotionSeenMilestoneDays"
    }

    private(set) var completionDates: Set<String> = []
    private(set) var entryCount: Int = 0
    private(set) var moodByDate: [String: String] = [:]
    private(set) var daySummaries: [String: DaySummary] = [:]

    private let calendar = Calendar.current

    init() {
        load()
        seedDemoDataIfNeeded()
    }

    var currentStreak: Int {
        var streak = 0
        var date = calendar.startOfDay(for: Date())

        if !isCompleted(on: date) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date),
                  isCompleted(on: yesterday) else { return 0 }
            date = yesterday
        }

        while isCompleted(on: date) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return streak
    }

    var isCompletedToday: Bool {
        isCompleted(on: calendar.startOfDay(for: Date()))
    }

    var todaySummary: DaySummary? {
        daySummaries[DaySummary.todayKey]
    }

    var daysJournaled: Int { completionDates.count }

    var challengeProgress: Int {
        min(currentStreak, 7)
    }

    var streakIdentity: StreakIdentity {
        StreakIdentity.identity(for: currentStreak)
    }

    func shouldCelebrateMilestone(days: Int) -> Bool {
        StreakIdentity.milestoneThresholds.contains(days) && !hasSeenMilestone(days)
    }

    func markMilestoneSeen(_ days: Int) {
        var seen = seenMilestoneDays
        seen.insert(days)
        UserDefaults.standard.set(Array(seen), forKey: Keys.seenMilestoneDays)
    }

    private var seenMilestoneDays: Set<Int> {
        Set(UserDefaults.standard.array(forKey: Keys.seenMilestoneDays) as? [Int] ?? [])
    }

    private func hasSeenMilestone(_ days: Int) -> Bool {
        seenMilestoneDays.contains(days)
    }

    var weekCompletionFlags: [Bool] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today) - calendar.firstWeekday
        let normalized = weekday < 0 ? weekday + 7 : weekday
        guard let weekStart = calendar.date(byAdding: .day, value: -normalized, to: today) else {
            return Array(repeating: false, count: 7)
        }
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return false }
            return isCompleted(on: day)
        }
    }

    func moodEmoji(for date: Date) -> String? {
        moodByDate[dateKey(date)]
    }

    func completeDevotion(mood: String) {
        _ = recordDevotion(mood: mood, summary: nil)
    }

    @discardableResult
    func recordDevotion(mood: String, summary: DaySummary?) -> DevotionFinishResult {
        let today = calendar.startOfDay(for: Date())
        let key = dateKey(today)
        let wasCompletedToday = completionDates.contains(key)
        let isFirstCompletionEver = !UserDefaults.standard.bool(forKey: "hasRecordedDevotionCompletion")

        completionDates.insert(key)
        moodByDate[key] = MoodCatalog.emoji(for: mood)
        if let summary {
            daySummaries[key] = summary
        }
        if !wasCompletedToday {
            entryCount += 1
        }
        UserDefaults.standard.set(true, forKey: "hasRecordedDevotionCompletion")
        save()

        return DevotionFinishResult(
            streak: currentStreak,
            mood: mood,
            isFirstCompletionEver: isFirstCompletionEver,
            summary: summary ?? todaySummary ?? DaySummary(
                dateKey: key,
                mood: mood,
                moodEmoji: MoodCatalog.emoji(for: mood),
                timeLabel: "Today",
                insight: DaySummary.insight(for: JournalDraft(mood: mood)),
                journalPreview: "Morning devotion",
                verseReference: nil,
                focusTags: nil,
                affirmation: nil,
                savedVersePhrase: nil
            )
        )
    }

    func wrappedStats() -> MorningWrappedStats {
        let weekFlags = weekCompletionFlags
        let morningsThisWeek = weekFlags.filter { $0 }.count
        let moodCounts = moodByDate.values.reduce(into: [String: Int]()) { counts, emoji in
            counts[emoji, default: 0] += 1
        }
        let topEmoji = moodCounts.max(by: { $0.value < $1.value })?.key ?? "🍃"
        let topMood = MoodCatalog.options.first { $0.emoji == topEmoji }?.label ?? "Peaceful"
        let highlight = LocalInsightEngine.primaryHighlight()

        return MorningWrappedStats(
            morningsThisWeek: morningsThisWeek,
            topMood: topMood,
            topMoodEmoji: topEmoji,
            currentStreak: currentStreak,
            totalDays: daysJournaled,
            highlightInsight: highlight,
            weeklyNarrative: nil,
            weekLabels: [],
            weekCompleted: weekFlags
        )
    }

    func calendarDays(for month: Date) -> [StreakCalendarDay] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }

        let today = calendar.startOfDay(for: Date())
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingBlanks = firstWeekday - calendar.firstWeekday
        let adjustedLeading = leadingBlanks < 0 ? leadingBlanks + 7 : leadingBlanks

        var days: [StreakCalendarDay] = (0..<adjustedLeading).map { _ in
            StreakCalendarDay(
                day: 0,
                isInMonth: false,
                isToday: false,
                isFuture: false,
                isMissed: false,
                isCompleted: false,
                moodEmoji: nil
            )
        }

        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            let normalized = calendar.startOfDay(for: date)
            let completed = isCompleted(on: normalized)
            let isFuture = normalized > today
            days.append(
                StreakCalendarDay(
                    day: day,
                    isInMonth: true,
                    isToday: normalized == today,
                    isFuture: isFuture,
                    isMissed: !completed && normalized < today,
                    isCompleted: completed,
                    moodEmoji: moodByDate[dateKey(normalized)]
                )
            )
        }

        let trailing = (7 - (days.count % 7)) % 7
        days.append(contentsOf: (0..<trailing).map { _ in
            StreakCalendarDay(
                day: 0,
                isInMonth: false,
                isToday: false,
                isFuture: false,
                isMissed: false,
                isCompleted: false,
                moodEmoji: nil
            )
        })

        return days
    }

    func isCompleted(on date: Date) -> Bool {
        completionDates.contains(dateKey(date))
    }

    func mergeRemoteCompletions(_ rows: [(dateKey: String, mood: String?, summary: DaySummary?)]) {
        guard !rows.isEmpty else { return }

        for row in rows {
            completionDates.insert(row.dateKey)
            if let mood = row.mood {
                moodByDate[row.dateKey] = MoodCatalog.emoji(for: mood)
            }
            if let summary = row.summary {
                daySummaries[row.dateKey] = summary
            }
        }
        entryCount = max(entryCount, completionDates.count)
        save()
    }

    func mergeRemoteSession(
        dateKey: String,
        mood: String?,
        journalPreview: String,
        verseReference: String?,
        focusTags: [String]?,
        affirmation: String?,
        savedVersePhrase: String?
    ) {
        completionDates.insert(dateKey)
        if let mood {
            moodByDate[dateKey] = MoodCatalog.emoji(for: mood)
        }

        let preview = journalPreview.trimmingCharacters(in: .whitespacesAndNewlines)
        if !preview.isEmpty {
            daySummaries[dateKey] = DaySummary(
                dateKey: dateKey,
                mood: mood ?? "Peaceful",
                moodEmoji: MoodCatalog.emoji(for: mood ?? "Peaceful"),
                timeLabel: dateKey,
                insight: daySummaries[dateKey]?.insight ?? "Morning devotion completed.",
                journalPreview: preview,
                verseReference: verseReference,
                focusTags: focusTags,
                affirmation: affirmation,
                savedVersePhrase: savedVersePhrase
            )
        }
        entryCount = max(entryCount, completionDates.count)
        save()
    }

    func clearDemoData() {
        guard UserDefaults.standard.bool(forKey: Keys.didSeedDemo) else { return }
        completionDates.removeAll()
        moodByDate.removeAll()
        daySummaries.removeAll()
        entryCount = 0
        UserDefaults.standard.set(false, forKey: Keys.didSeedDemo)
        save()
    }

    #if DEBUG
    /// Clears only today's devotion completion so shield + home "locked" UI can be tested.
    func clearTodayForTesting() {
        let key = dateKey(calendar.startOfDay(for: Date()))
        completionDates.remove(key)
        moodByDate.removeValue(forKey: key)
        daySummaries.removeValue(forKey: key)
        save()
    }
    #endif

    private func dateKey(_ date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private func load() {
        if let dates = UserDefaults.standard.stringArray(forKey: Keys.completionDates) {
            completionDates = Set(dates)
        }
        entryCount = UserDefaults.standard.integer(forKey: Keys.entryCount)
        if let data = UserDefaults.standard.data(forKey: Keys.moodByDate),
           let moods = try? JSONDecoder().decode([String: String].self, from: data) {
            moodByDate = moods
        }
        if let data = UserDefaults.standard.data(forKey: Keys.daySummaries),
           let summaries = try? JSONDecoder().decode([String: DaySummary].self, from: data) {
            daySummaries = summaries
        }
    }

    private func save() {
        UserDefaults.standard.set(Array(completionDates), forKey: Keys.completionDates)
        UserDefaults.standard.set(entryCount, forKey: Keys.entryCount)
        if let data = try? JSONEncoder().encode(moodByDate) {
            UserDefaults.standard.set(data, forKey: Keys.moodByDate)
        }
        if let data = try? JSONEncoder().encode(daySummaries) {
            UserDefaults.standard.set(data, forKey: Keys.daySummaries)
        }
        SharedDataSync.scheduleRefresh(streakManager: self)
    }

    private func seedDemoDataIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Keys.didSeedDemo), completionDates.isEmpty else { return }

        let today = calendar.startOfDay(for: Date())
        let moods = ["🍃", "😊", "🌅", "🙏", "😊"]
        for offset in 1...5 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = dateKey(date)
            completionDates.insert(key)
            moodByDate[key] = moods[(offset - 1) % moods.count]
        }
        entryCount = 8
        UserDefaults.standard.set(true, forKey: Keys.didSeedDemo)
        save()
    }
}

enum MoodCatalog {
    static let options: [(label: String, icon: String, emoji: String)] = [
        ("Peaceful", "leaf.fill", "🍃"),
        ("Overwhelmed", "cloud.rain.fill", "🌧️"),
        ("Grateful", "heart.fill", "😊"),
        ("Restless", "wind", "💨"),
        ("Hopeful", "sun.horizon.fill", "🌅"),
    ]

    static func icon(for mood: String) -> String {
        switch mood.lowercased() {
        case "peaceful": "leaf.fill"
        case "overwhelmed": "cloud.rain.fill"
        case "grateful": "heart.fill"
        case "restless": "wind"
        case "hopeful": "sun.horizon.fill"
        default: "hands.sparkles.fill"
        }
    }

    static func emoji(for mood: String) -> String {
        options.first { $0.label.lowercased() == mood.lowercased() }?.emoji ?? "🙏"
    }
}

struct StreakCalendarDay: Identifiable {
    let id = UUID()
    let day: Int
    let isInMonth: Bool
    let isToday: Bool
    let isFuture: Bool
    let isMissed: Bool
    let isCompleted: Bool
    let moodEmoji: String?
}

struct JournalDraft {
    var mood: String = MoodCatalog.options[0].label
    var emotion: String = ""
    var reason: String = ""
    var onMind: String = ""
    var plans: String = ""
    var focusTags: [String] = []
    var gratitudeItems: [String] = ["", "", ""]
    var affirmation: String = ""
    var savedVersePhrase: String = ""
    var reflectionText: String = ""

    var isMadLibsComplete: Bool {
        !emotion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !onMind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !plans.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isGratitudeComplete: Bool {
        gratitudeItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count >= 2
    }

    var isAffirmationComplete: Bool {
        !affirmation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var selectedFocusTags: [FocusTag] {
        FocusTag.from(rawValues: focusTags)
    }

    mutating func applyMoodDefaults() {
        if emotion.isEmpty {
            emotion = mood.lowercased()
        }
    }

    var completionInsight: String {
        let feeling = emotion.trimmingCharacters(in: .whitespacesAndNewlines)
        let because = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        if !feeling.isEmpty, !because.isEmpty {
            return "Today you named feeling \(feeling) because \(because). Showing up with honesty is already a sacred start."
        }
        return "Today you paused before the noise. That quiet honesty is the heart of a morning devotion."
    }
}
