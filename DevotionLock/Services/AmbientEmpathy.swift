//
//  AmbientEmpathy.swift
//  DevotionLock
//
//  Quiet, on-device noticing for Home and Chaplain.
//  Voice: second person, still, never more than the signals support.
//
//  Mobbin refs:
//  Tolan editorial insight — https://mobbin.com/screens/33ce497d-b5ca-4f10-bae7-26cc43ef2f44
//  Gentler Streak pale cards — https://mobbin.com/screens/f1f313b1-01a0-4d8e-828b-dfc014130b13
//  Moonly "For You" cards — https://mobbin.com/screens/8bd68924-87c1-460f-8ef7-7a9118d9286a
//

import Foundation

enum AmbientEmpathy {
    private static let insightDismissedDayKey = "ambient.insightDismissedDay"
    private static let companionDismissedSessionKey = "ambient.companionDismissedSession"
    private static let verseCallbackWeekKey = "ambient.verseCallbackWeek"
    private static let verseCallbackReferenceKey = "ambient.verseCallbackReference"
    private static let verseShownMonthKey = "ambient.verseShownMonth"
    private static let verseShownReferencesKey = "ambient.verseShownReferences"

    // MARK: - Personal insight (mood / theme only)

    @MainActor
    static func ambientInsight(from snapshot: LocalUserPatternSnapshot) -> PersonalInsight? {
        guard !isInsightDismissedToday else { return nil }
        return snapshot.insights.first { insight in
            switch insight.kind {
            case .moodTrend, .recurringTheme:
                return true
            default:
                return false
            }
        }
    }

    static var isInsightDismissedToday: Bool {
        UserDefaults.standard.string(forKey: insightDismissedDayKey) == todayKey
    }

    static func dismissInsightForToday() {
        UserDefaults.standard.set(todayKey, forKey: insightDismissedDayKey)
    }

    // MARK: - Story brief (Home greeting — "The story so far")

    /// One piece of the noticing brief: plain prose, or an entity that Home
    /// renders as an inline chip (mood in peach, theme in lilac, stats in teal).
    enum NoticingSegment: Equatable {
        case text(String)
        case mood(String)
        case theme(String)
        case stat(String)
    }

    /// Home header brief: Morning Wrapped's "story so far", with chip prose
    /// locally and the weekly narrative when progress has one.
    struct StoryBrief: Equatable {
        let title: String
        /// Chip-based local story (always preferred when no remote narrative).
        let segments: [NoticingSegment]
        /// Full weekly narrative from progress / generate-insight, when available.
        let narrative: String?

        var accessibilityLabel: String {
            if let narrative, !narrative.isEmpty {
                return "\(title). \(narrative)"
            }
            return "\(title). \(plainText(for: segments))"
        }
    }

    private static let storyNarrativeWeekKey = "ambient.storyNarrativeWeek"
    private static let storyNarrativeBodyKey = "ambient.storyNarrativeBody"

    @MainActor
    static func storyBrief(
        snapshot: LocalUserPatternSnapshot,
        profile: MorningProfile,
        streakDays: Int,
        narrative: String? = nil
    ) -> StoryBrief? {
        let resolvedNarrative = narrative.flatMap(homeNarrativeExcerpt)
            ?? cachedWeeklyNarrative().flatMap(homeNarrativeExcerpt)

        let segments = storySegments(
            snapshot: snapshot,
            profile: profile,
            streakDays: streakDays
        )

        // Need either a local story or a progress narrative.
        guard segments != nil || resolvedNarrative != nil else { return nil }

        return StoryBrief(
            title: "The story so far",
            segments: segments ?? [],
            narrative: resolvedNarrative
        )
    }

    /// Local chip story woven from the same signals Morning Wrapped uses.
    @MainActor
    static func storySegments(
        snapshot: LocalUserPatternSnapshot,
        profile: MorningProfile,
        streakDays: Int
    ) -> [NoticingSegment]? {
        let mornings = snapshot.morningsThisWeek
        let mood = snapshot.moodTrend
        let theme = snapshot.topThemes.first

        let hasMood = (mood?.count ?? 0) >= 2
        let hasTheme = (theme?.count ?? 0) >= 2
        let hasMornings = mornings >= 2
        let hasStreak = streakDays >= 2

        guard hasMood || hasTheme || hasMornings || hasStreak else {
            // Brand-new users: fall back to a single noticing line if we have one.
            return dailyNoticingSegments(snapshot: snapshot, profile: profile)
        }

        var segments: [NoticingSegment] = []

        if hasMornings {
            let label = mornings == 1 ? "1 morning" : "\(mornings) mornings"
            segments.append(contentsOf: [
                .text("This week you returned"),
                .stat(label),
                .text("."),
            ])
        } else if mornings == 1 {
            segments.append(contentsOf: [
                .text("You have begun"),
                .stat("1 morning"),
                .text("this week."),
            ])
        }

        if let mood, hasMood {
            let word = mood.dominantMood.lowercased()
            let countPhrase = mood.count == 2 ? "twice." : "\(mood.count) times."
            segments.append(contentsOf: [
                .text("You have felt"),
                .mood(word),
                .text(countPhrase),
            ])
        } else if let moodName = profile.dominantMood {
            let recent = profile.recentMoods.filter { $0.caseInsensitiveCompare(moodName) == .orderedSame }
            if recent.count >= 2 {
                segments.append(contentsOf: [
                    .text("You have been feeling"),
                    .mood(moodName.lowercased()),
                    .text("lately."),
                ])
            }
        }

        if let theme, hasTheme {
            let tail = theme.count == 2
                ? "has come up twice in your reflections."
                : "keeps returning in your reflections."
            segments.append(contentsOf: [
                .theme(theme.label),
                .text(tail),
            ])
        }

        if hasStreak {
            let label = streakDays == 1 ? "1 day" : "\(streakDays) days"
            segments.append(contentsOf: [
                .text("Your streak holds at"),
                .stat(label),
                .text("."),
            ])
        }

        return segments.isEmpty ? nil : segments
    }

    @MainActor
    private static func dailyNoticingSegments(
        snapshot: LocalUserPatternSnapshot,
        profile: MorningProfile
    ) -> [NoticingSegment]? {
        if let mood = snapshot.moodTrend, mood.count >= 2 {
            let word = mood.dominantMood.lowercased()
            let tail = mood.count == 2 ? "twice this week." : "\(mood.count) times this week."
            return [.text("You have felt"), .mood(word), .text(tail)]
        }

        if let theme = snapshot.topThemes.first, theme.count >= 2 {
            let tail = theme.count == 2
                ? "has come up twice in your reflections."
                : "keeps returning in your reflections."
            return [.theme(theme.label), .text(tail)]
        }

        if let mood = profile.dominantMood {
            let recent = profile.recentMoods.filter { $0.caseInsensitiveCompare(mood) == .orderedSame }
            guard recent.count >= 2 else { return nil }
            return [.text("You have been feeling"), .mood(mood.lowercased()), .text("lately.")]
        }

        return nil
    }

    static func plainText(for segments: [NoticingSegment]) -> String {
        segments.map { segment in
            switch segment {
            case .text(let text): text
            case .mood(let word): word
            case .theme(let word): word
            case .stat(let word): word
            }
        }.joined(separator: " ")
    }

    static func cachedWeeklyNarrative() -> String? {
        guard UserDefaults.standard.string(forKey: storyNarrativeWeekKey) == weekKey else {
            return nil
        }
        let body = UserDefaults.standard.string(forKey: storyNarrativeBodyKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let body, !body.isEmpty else { return nil }
        return body
    }

    static func cacheWeeklyNarrative(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(weekKey, forKey: storyNarrativeWeekKey)
        UserDefaults.standard.set(trimmed, forKey: storyNarrativeBodyKey)
    }

    /// Home only needs the opening beat of the weekly story, not all three paragraphs.
    private static func homeNarrativeExcerpt(_ text: String) -> String? {
        let paragraphs = text
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let first = paragraphs.first else { return nil }
        return first
    }

    // MARK: - Companion memory (Chaplain empty state)

    struct CompanionMemory: Equatable {
        let body: String
        let keepGoingPrompt: String
    }

    @MainActor
    static func companionMemory(
        snapshot: LocalUserPatternSnapshot,
        journey: JourneyTimelineStore
    ) -> CompanionMemory? {
        guard !isCompanionDismissedThisSession else { return nil }

        var facts: [String] = []
        var promptSeed = "Something has been on my heart this week."

        if let mood = snapshot.moodTrend, mood.count >= 2 {
            let word = mood.dominantMood.lowercased()
            facts.append("you have been feeling \(word)")
            promptSeed = "I have been feeling \(word) this week."
        } else if let theme = snapshot.topThemes.first, theme.count >= 2 {
            facts.append("\(theme.label.lowercased()) has been on your heart")
            promptSeed = "\(theme.label) has been on my heart."
        }

        if let verse = journey.entries.first(where: { $0.kind == .verse && $0.verseReference != nil }),
           let reference = verse.verseReference {
            let weekday = weekdayName(for: verse.createdAt)
            facts.append("you read \(reference) on \(weekday)")
            if facts.count == 1 {
                promptSeed = "I want to return to \(reference)."
            }
        }

        guard !facts.isEmpty else { return nil }

        let body: String
        switch facts.count {
        case 1:
            body = "I remember \(facts[0]). Want to keep going from there, or start fresh?"
        default:
            body = "I remember \(facts[0]), and \(facts[1]). Want to keep going from there, or start fresh?"
        }

        return CompanionMemory(body: body, keepGoingPrompt: promptSeed)
    }

    static var isCompanionDismissedThisSession: Bool {
        UserDefaults.standard.bool(forKey: companionDismissedSessionKey)
    }

    static func dismissCompanionForSession() {
        UserDefaults.standard.set(true, forKey: companionDismissedSessionKey)
    }

    static func resetCompanionSessionFlag() {
        UserDefaults.standard.set(false, forKey: companionDismissedSessionKey)
    }

    // MARK: - Verse-anchored callback

    struct VerseCallback: Equatable, Identifiable {
        let id: String
        let reference: String
        let body: String
        let passageText: String?
    }

    @MainActor
    static func verseCallback(
        journey: JourneyTimelineStore,
        profile: MorningProfile,
        snapshot: LocalUserPatternSnapshot
    ) -> VerseCallback? {
        guard !didShowVerseCallbackThisWeek else { return nil }

        let moods = currentMoodSignals(profile: profile, snapshot: snapshot)
        guard !moods.isEmpty else { return nil }

        let topics = topics(forMoods: moods)
        guard !topics.isEmpty else { return nil }

        let cutoff = Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        let shownThisMonth = shownVerseReferencesThisMonth

        let candidates = journey.entries.filter { entry in
            guard entry.kind == .verse,
                  let reference = entry.verseReference,
                  entry.createdAt <= cutoff,
                  !shownThisMonth.contains(reference) else { return false }
            return true
        }

        for entry in candidates {
            guard let reference = entry.verseReference else { continue }
            guard let passage = passage(matching: reference) else { continue }
            let overlap = Set(passage.topics).intersection(topics)
            guard let topic = overlap.first else { continue }

            let carrying = topic.label.lowercased()
            let body = "You read \(reference) when \(carrying) was close. Open it again?"
            return VerseCallback(
                id: "verse-\(reference)",
                reference: reference,
                body: body,
                passageText: entry.body ?? passage.text
            )
        }

        return nil
    }

    static func markVerseCallbackShown(_ callback: VerseCallback) {
        UserDefaults.standard.set(weekKey, forKey: verseCallbackWeekKey)
        UserDefaults.standard.set(callback.reference, forKey: verseCallbackReferenceKey)

        var shown = shownVerseReferencesThisMonth
        shown.insert(callback.reference)
        UserDefaults.standard.set(monthKey, forKey: verseShownMonthKey)
        UserDefaults.standard.set(Array(shown), forKey: verseShownReferencesKey)
    }

    static func dismissVerseCallback(_ callback: VerseCallback) {
        markVerseCallbackShown(callback)
    }

    // MARK: - Private helpers

    private static var todayKey: String {
        dateKey(for: Date())
    }

    private static var weekKey: String {
        let calendar = Calendar.current
        let week = calendar.component(.weekOfYear, from: Date())
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        return "\(year)-W\(week)"
    }

    private static var monthKey: String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let year = calendar.component(.year, from: Date())
        return String(format: "%04d-%02d", year, month)
    }

    private static var didShowVerseCallbackThisWeek: Bool {
        UserDefaults.standard.string(forKey: verseCallbackWeekKey) == weekKey
    }

    private static var shownVerseReferencesThisMonth: Set<String> {
        let storedMonth = UserDefaults.standard.string(forKey: verseShownMonthKey)
        guard storedMonth == monthKey else { return [] }
        let refs = UserDefaults.standard.stringArray(forKey: verseShownReferencesKey) ?? []
        return Set(refs)
    }

    private static func dateKey(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private static func weekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    @MainActor
    private static func currentMoodSignals(
        profile: MorningProfile,
        snapshot: LocalUserPatternSnapshot
    ) -> [String] {
        var moods: [String] = []
        if let dominant = snapshot.moodTrend?.dominantMood {
            moods.append(dominant)
        }
        moods.append(contentsOf: profile.recentMoods.prefix(3))
        if let theme = snapshot.topThemes.first {
            moods.append(theme.label)
        }
        return moods
    }

    private static func topics(forMoods moods: [String]) -> Set<PassageTopic> {
        var topics = Set<PassageTopic>()
        for mood in moods {
            let key = mood.lowercased()
            switch key {
            case "peaceful", "peace":
                topics.formUnion([.peace, .presence])
            case "overwhelmed", "anxious", "anxiety":
                topics.formUnion([.anxiety, .rest, .peace])
            case "grateful", "gratitude":
                topics.formUnion([.gratitude, .joy])
            case "restless", "rest":
                topics.formUnion([.rest, .peace, .anxiety])
            case "hopeful", "hope":
                topics.formUnion([.hope, .faith])
            case "work", "family", "health", "relationships", "faith":
                if let topic = PassageTopic(rawValue: key) {
                    topics.insert(topic)
                } else if key == "faith" {
                    topics.insert(.faith)
                }
            default:
                if let topic = PassageTopic(rawValue: key) {
                    topics.insert(topic)
                }
            }
        }
        return topics
    }

    private static func passage(matching reference: String) -> SpiritualPassage? {
        let needle = reference.lowercased()
        return SpiritualPassageCatalog.all.first { passage in
            passage.source == .scripture && (
                passage.reference.lowercased() == needle
                    || passage.reference.lowercased().hasPrefix(needle)
                    || needle.hasPrefix(passage.reference.lowercased())
            )
        }
    }
}
