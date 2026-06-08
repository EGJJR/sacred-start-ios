//
//  LocalInsightEngine.swift
//  DevotionLock
//
//  On-device pattern detection — no cloud, no model training.
//  Reads journal, mood, streak, and focus-tag history from local stores.
//

import Foundation

enum LocalInsightEngine {
    private struct ThemeLexicon {
        let id: String
        let label: String
        let keywords: [String]
    }

    private static let themes: [ThemeLexicon] = [
        ThemeLexicon(id: "family", label: "Family", keywords: ["family", "kids", "child", "parent", "marriage", "spouse", "home"]),
        ThemeLexicon(id: "work", label: "Work", keywords: ["work", "job", "office", "career", "meeting", "boss", "colleague"]),
        ThemeLexicon(id: "anxiety", label: "Anxiety & worry", keywords: ["anxious", "anxiety", "worry", "worried", "stress", "overwhelm", "overwhelmed", "fear"]),
        ThemeLexicon(id: "gratitude", label: "Gratitude", keywords: ["grateful", "thankful", "gratitude", "blessed", "thanks"]),
        ThemeLexicon(id: "rest", label: "Rest", keywords: ["rest", "tired", "sleep", "exhaust", "weary", "sabbath", "pause"]),
        ThemeLexicon(id: "faith", label: "Faith & trust", keywords: ["faith", "trust", "god", "prayer", "pray", "spirit", "hope"]),
        ThemeLexicon(id: "relationships", label: "Relationships", keywords: ["friend", "relationship", "conflict", "forgive", "love", "lonely"]),
        ThemeLexicon(id: "health", label: "Health", keywords: ["health", "body", "sick", "heal", "energy", "wellness"]),
    ]

    @MainActor
    static func analyze() -> LocalUserPatternSnapshot {
        analyze(streak: StreakManager.shared, journey: JourneyTimelineStore.shared)
    }

    @MainActor
    static func analyze(
        streak: StreakManager,
        journey: JourneyTimelineStore
    ) -> LocalUserPatternSnapshot {
        let moodTrend = buildMoodTrend(streak: streak, days: 7)
        let topThemes = detectThemes(streak: streak, journey: journey, days: 14)
        let insights = buildInsights(
            streak: streak,
            moodTrend: moodTrend,
            topThemes: topThemes
        )

        return LocalUserPatternSnapshot(
            insights: insights.sorted { $0.priority > $1.priority },
            moodTrend: moodTrend,
            topThemes: topThemes,
            streakDays: streak.currentStreak,
            completedToday: streak.isCompletedToday,
            morningsThisWeek: streak.weekCompletionFlags.filter { $0 }.count
        )
    }

    @MainActor
    static func topInsights(limit: Int = 3) -> [PersonalInsight] {
        Array(analyze().insights.prefix(limit))
    }

    @MainActor
    static func primaryHighlight() -> String {
        if let headline = analyze().headlineInsight {
            return headline.body
        }
        return "Keep showing up — your sanctuary is waiting each morning."
    }

    // MARK: - Mood trends

    @MainActor
    private static func buildMoodTrend(streak: StreakManager, days: Int) -> MoodTrendSnapshot? {
        let moods = moods(inLastDays: days, streak: streak)
        guard !moods.isEmpty else { return nil }

        let counts = moods.reduce(into: [String: Int]()) { partial, mood in
            partial[mood, default: 0] += 1
        }
        guard let top = counts.max(by: { $0.value < $1.value }) else { return nil }

        return MoodTrendSnapshot(
            dominantMood: top.key,
            count: top.value,
            windowDays: days,
            totalEntries: moods.count
        )
    }

    @MainActor
    private static func moods(inLastDays days: Int, streak: StreakManager) -> [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var moods: [String] = []

        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = dateKey(for: date)
            if let emoji = streak.moodByDate[key], let label = moodLabel(for: emoji) {
                moods.append(label)
            }
        }
        return moods
    }

    private static func moodLabel(for emoji: String) -> String? {
        MoodCatalog.options.first { $0.emoji == emoji }?.label
    }

    // MARK: - Theme detection

    @MainActor
    private static func detectThemes(
        streak: StreakManager,
        journey: JourneyTimelineStore,
        days: Int
    ) -> [ThemeSignal] {
        var counts: [String: (label: String, count: Int)] = [:]
        let corpus = textCorpus(streak: streak, journey: journey, days: days)
        let lowered = corpus.lowercased()

        for theme in themes {
            var hits = 0
            for keyword in theme.keywords where lowered.contains(keyword) {
                hits += 1
            }
            if hits > 0 {
                counts[theme.id] = (theme.label, hits)
            }
        }

        for tag in focusTagCounts(streak: streak, journey: journey, days: days) {
            if let existing = counts[tag.id] {
                counts[tag.id] = (existing.label, existing.count + tag.count)
            } else {
                counts[tag.id] = (tag.label, tag.count)
            }
        }

        return counts
            .map { ThemeSignal(id: $0.key, label: $0.value.label, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    @MainActor
    private static func textCorpus(
        streak: StreakManager,
        journey: JourneyTimelineStore,
        days: Int
    ) -> String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var chunks: [String] = []

        for summary in streak.daySummaries.values where summary.dateKey >= dateKey(for: cutoff) {
            chunks.append(summary.journalPreview)
            if let affirmation = summary.affirmation { chunks.append(affirmation) }
            if let phrase = summary.savedVersePhrase { chunks.append(phrase) }
        }

        for entry in journey.entries where entry.createdAt >= cutoff {
            if let body = entry.body { chunks.append(body) }
            chunks.append(entry.title)
        }

        return chunks.joined(separator: " ")
    }

    @MainActor
    private static func focusTagCounts(
        streak: StreakManager,
        journey: JourneyTimelineStore,
        days: Int
    ) -> [ThemeSignal] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var counts: [String: Int] = [:]

        for summary in streak.daySummaries.values where summary.dateKey >= dateKey(for: cutoff) {
            for tag in summary.focusTags ?? [] {
                counts[tag, default: 0] += 2
            }
        }

        for entry in journey.entries where entry.createdAt >= cutoff {
            for tag in entry.focusTags {
                counts[tag, default: 0] += 1
            }
        }

        return counts.map { id, count in
            let label = FocusTag(rawValue: id)?.label ?? id.capitalized
            return ThemeSignal(id: id, label: label, count: count)
        }
    }

    // MARK: - Insight rules

    @MainActor
    private static func buildInsights(
        streak: StreakManager,
        moodTrend: MoodTrendSnapshot?,
        topThemes: [ThemeSignal]
    ) -> [PersonalInsight] {
        var insights: [PersonalInsight] = []
        let streakDays = streak.currentStreak
        let completedToday = streak.isCompletedToday
        let morningsThisWeek = streak.weekCompletionFlags.filter { $0 }.count
        let hour = Calendar.current.component(.hour, from: Date())

        if completedToday, [7, 14, 21, 30, 60, 100].contains(streakDays) {
            insights.append(PersonalInsight(
                id: "milestone-\(streakDays)",
                kind: .streakMilestone,
                title: "\(streakDays)-day streak",
                body: milestoneCopy(days: streakDays),
                priority: 100
            ))
        }

        if !completedToday, streakDays >= 2, hour >= 9 {
            insights.append(PersonalInsight(
                id: "streak-nudge",
                kind: .streakNudge,
                title: "Keep your streak alive",
                body: "You're on a \(streakDays)-day streak. A few quiet minutes this morning keeps the rhythm you've built.",
                priority: 95
            ))
        } else if !completedToday, streakDays == 0, streak.daysJournaled > 0, hour >= 10 {
            insights.append(PersonalInsight(
                id: "welcome-back",
                kind: .streakNudge,
                title: "Welcome back",
                body: "No pressure — just presence. Your journal remembers past mornings; today can be a gentle restart.",
                priority: 88
            ))
        }

        if let moodTrend, moodTrend.count >= 2 {
            let plural = moodTrend.count == 1 ? "time" : "times"
            insights.append(PersonalInsight(
                id: "mood-trend",
                kind: .moodTrend,
                title: "Mood pattern",
                body: "\(moodTrend.dominantMood) has shown up \(moodTrend.count) \(plural) in the last \(moodTrend.windowDays) days — more than any other mood you've logged.",
                priority: 82
            ))
        }

        if let theme = topThemes.first, theme.count >= 2 {
            let frequency = theme.count >= 4 ? "often" : "a few times"
            insights.append(PersonalInsight(
                id: "theme-\(theme.id)",
                kind: .recurringTheme,
                title: "Recurring theme",
                body: "\(theme.label) keeps appearing in your reflections — you've named it \(frequency) recently.",
                priority: 78
            ))
        }

        if morningsThisWeek >= 4 {
            insights.append(PersonalInsight(
                id: "week-strong",
                kind: .weeklyPattern,
                title: "Strong week",
                body: "You've shown up \(morningsThisWeek) mornings this week. That consistency is shaping a quiet anchor before the day begins.",
                priority: 72
            ))
        } else if morningsThisWeek >= 1, morningsThisWeek <= 2, !completedToday {
            insights.append(PersonalInsight(
                id: "week-building",
                kind: .weeklyPattern,
                title: "Building rhythm",
                body: "You've started \(morningsThisWeek) morning\(morningsThisWeek == 1 ? "" : "s") this week — one more would deepen the pattern.",
                priority: 68
            ))
        }

        if let secondaryTheme = topThemes.dropFirst().first, secondaryTheme.count >= 2 {
            insights.append(PersonalInsight(
                id: "theme-secondary-\(secondaryTheme.id)",
                kind: .recurringTheme,
                title: "Also on your heart",
                body: "\(secondaryTheme.label) is another thread running through your journal lately.",
                priority: 64
            ))
        }

        if insights.isEmpty {
            insights.append(PersonalInsight(
                id: "encouragement",
                kind: .encouragement,
                title: "Your story is forming",
                body: streak.daysJournaled == 0
                    ? "After a few devotions, Devotion Lock will notice moods and themes — all on your device, privately."
                    : "Keep journaling — local patterns will grow clearer with each morning you show up.",
                priority: 50
            ))
        }

        return insights
    }

    private static func milestoneCopy(days: Int) -> String {
        switch days {
        case 7: "One full week of showing up. That's a real sanctuary rhythm taking root."
        case 14: "Two weeks steady. Your mornings are becoming a place you return to."
        case 21: "Three weeks — habit and heart are meeting here."
        case 30: "A month of devotion. Notice how your journal already holds a shape."
        case 60: "Sixty days. Your faithfulness is writing a quiet story on this device."
        case 100: "One hundred mornings. What a witness to patience and presence."
        default: "\(days) days of showing up — keep honoring this practice."
        }
    }

    private static func dateKey(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

@Observable
@MainActor
final class PersonalInsightStore {
    static let shared = PersonalInsightStore()

    private(set) var snapshot: LocalUserPatternSnapshot = LocalUserPatternSnapshot(
        insights: [],
        moodTrend: nil,
        topThemes: [],
        streakDays: 0,
        completedToday: false,
        morningsThisWeek: 0
    )

    var topInsights: [PersonalInsight] { snapshot.insights }

    func refresh() {
        snapshot = LocalInsightEngine.analyze()
    }
}
