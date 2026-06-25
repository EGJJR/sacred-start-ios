//
//  ChaplainContextBuilder.swift
//  DevotionLock
//

import Foundation

struct ChaplainRequestContext: Encodable {
    struct DevotionSummary: Encodable {
        let emotion: String?
        let reason: String?
        let verse: String?
        let reference: String?
        let affirmation: String?
        let onMind: String?
        let focusTags: [String]?

        enum CodingKeys: String, CodingKey {
            case emotion
            case reason
            case verse
            case reference
            case affirmation
            case onMind = "on_mind"
            case focusTags = "focus_tags"
        }
    }

    let chaplainVoice: String
    let personality: String
    let mood: String
    let focusTags: [String]
    let intent: String?
    let devotionSummary: DevotionSummary?
    let recentJourney: [String]
    let localPatterns: [String]
    let streakDays: Int?
    let devotionCompletedToday: Bool?
    let prefetchedScripture: [PrefetchedScripturePayload]?
    /// When true, the edge function streams a reply without creating or saving a conversation.
    let ephemeral: Bool?

    enum CodingKeys: String, CodingKey {
        case chaplainVoice = "chaplain_voice"
        case personality
        case mood
        case focusTags = "focus_tags"
        case intent
        case devotionSummary = "devotion_summary"
        case recentJourney = "recent_journey"
        case localPatterns = "local_patterns"
        case streakDays = "streak_days"
        case devotionCompletedToday = "devotion_completed_today"
        case prefetchedScripture = "prefetched_scripture"
        case ephemeral
    }
}

struct PrefetchedScripturePayload: Encodable {
    let reference: String
    let text: String
    let source: String
    let bookSlug: String?
    let chapter: Int?
    let startVerse: Int?
    let endVerse: Int?
    let catalogPassageID: String?
    let version: String?

    enum CodingKeys: String, CodingKey {
        case reference
        case text
        case source
        case bookSlug = "book_slug"
        case chapter
        case startVerse = "start_verse"
        case endVerse = "end_verse"
        case catalogPassageID = "catalog_passage_id"
        case version
    }

    static func from(_ citation: ChaplainScriptureCitation) -> PrefetchedScripturePayload {
        PrefetchedScripturePayload(
            reference: citation.reference,
            text: citation.displayText,
            source: citation.source.rawValue,
            bookSlug: citation.bookSlug,
            chapter: citation.chapter,
            startVerse: citation.startVerse,
            endVerse: citation.endVerse,
            catalogPassageID: citation.catalogPassageID,
            version: citation.version
        )
    }
}

enum ChaplainContextBuilder {
    @MainActor
    static func build(
        intent: String? = nil,
        prefetchedScripture: [ChaplainScriptureCitation] = [],
        ephemeral: Bool = false
    ) -> ChaplainRequestContext {
        let voiceID = UserDefaults.standard.string(forKey: "selectedChaplainVoice") ?? "grace"
        let voice = ChaplainVoice.options.first { $0.id == voiceID } ?? ChaplainVoice.options[0]
        let mood = UserDefaults.standard.string(forKey: "intentionMood") ?? "Peaceful"
        let tags = TodayFocusStore.tags.map(\.rawValue)
        let streak = StreakManager.shared
        let patterns = PersonalInsightStore.shared

        let recentJourney = JourneyTimelineStore.shared.entries.prefix(3).map { entry in
            "\(entry.title): \(entry.body ?? "")"
        }

        if patterns.snapshot.insights.isEmpty {
            patterns.refresh()
        }

        return ChaplainRequestContext(
            chaplainVoice: voice.id,
            personality: voice.personality,
            mood: mood,
            focusTags: tags,
            intent: normalizedIntent(intent),
            devotionSummary: devotionSummary(from: streak.todaySummary),
            recentJourney: Array(recentJourney),
            localPatterns: patterns.snapshot.contextLines,
            streakDays: streak.currentStreak > 0 ? streak.currentStreak : nil,
            devotionCompletedToday: streak.isCompletedToday,
            prefetchedScripture: prefetchedScripture.isEmpty
                ? nil
                : prefetchedScripture.map(PrefetchedScripturePayload.from),
            ephemeral: ephemeral ? true : nil
        )
    }

    private static func normalizedIntent(_ intent: String?) -> String? {
        guard let intent else { return nil }
        if intent == "expand_reflection" || intent == "guided_prayer" || intent == "transcript_polish" {
            return intent
        }
        if intent.localizedCaseInsensitiveContains("reflect on today's verse") {
            return "verse_reflection"
        }
        if intent.localizedCaseInsensitiveContains("bible") || intent.localizedCaseInsensitiveContains("scripture") {
            return "bible_question"
        }
        if intent.localizedCaseInsensitiveContains("voice") {
            return "voice_handoff"
        }
        return intent
    }

    private static func devotionSummary(from summary: DaySummary?) -> ChaplainRequestContext.DevotionSummary? {
        guard let summary else { return nil }
        return ChaplainRequestContext.DevotionSummary(
            emotion: summary.mood,
            reason: nil,
            verse: summary.savedVersePhrase,
            reference: summary.verseReference,
            affirmation: summary.affirmation,
            onMind: summary.journalPreview,
            focusTags: summary.focusTags
        )
    }
}
