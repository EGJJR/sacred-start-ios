//
//  JourneyTimeline.swift
//  DevotionLock
//

import Foundation
import Observation

enum JourneyEntryKind: String, Codable, CaseIterable {
    case mood
    case devotion
    case verse
    case gratitude
    case reflection
    case voiceNote
    case answeredPrayer
    case evening

    var icon: String {
        switch self {
        case .mood: "face.smiling"
        case .devotion: "sun.horizon.fill"
        case .verse: "text.quote"
        case .gratitude: "heart.fill"
        case .reflection: "pencil.and.outline"
        case .voiceNote: "waveform"
        case .answeredPrayer: "checkmark.seal.fill"
        case .evening: "moon.stars.fill"
        }
    }

    var label: String {
        switch self {
        case .mood: "Check-in"
        case .devotion: "Morning devotion"
        case .verse: "Verse"
        case .gratitude: "Gratitude"
        case .reflection: "Reflection"
        case .voiceNote: "Voice note"
        case .answeredPrayer: "Answered"
        case .evening: "Evening"
        }
    }
}

struct JourneyTimelineEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let kind: JourneyEntryKind
    let title: String
    let body: String?
    let moodEmoji: String?
    let focusTags: [String]
    let verseReference: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        kind: JourneyEntryKind,
        title: String,
        body: String? = nil,
        moodEmoji: String? = nil,
        focusTags: [String] = [],
        verseReference: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.title = title
        self.body = body
        self.moodEmoji = moodEmoji
        self.focusTags = focusTags
        self.verseReference = verseReference
    }
}

@Observable
@MainActor
final class JourneyTimelineStore {
    static let shared = JourneyTimelineStore()

    private enum Keys {
        static let entries = "journeyTimelineEntries"
    }

    private(set) var entries: [JourneyTimelineEntry] = []
    private(set) var revision = 0

    init() {
        load()
    }

    var todayEntries: [JourneyTimelineEntry] {
        entries.filter { Calendar.current.isDateInToday($0.createdAt) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var recentEntries: [JourneyTimelineEntry] {
        Array(entries.sorted { $0.createdAt > $1.createdAt }.prefix(40))
    }

    func add(_ entry: JourneyTimelineEntry) {
        entries.insert(entry, at: 0)
        revision += 1
        persist()
        NotificationCenter.default.post(name: .devotionRhythmDidUpdate, object: nil)
        JourneyEntryRepository.shared.enqueue(entry)
    }

    func updateEntryBody(id: UUID, body: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let existing = entries[index]
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let updated = JourneyTimelineEntry(
            id: existing.id,
            createdAt: existing.createdAt,
            kind: existing.kind,
            title: existing.title,
            body: trimmed,
            moodEmoji: existing.moodEmoji,
            focusTags: existing.focusTags,
            verseReference: existing.verseReference
        )
        entries[index] = updated
        revision += 1
        persist()
        JourneyEntryRepository.shared.enqueue(updated)
    }

    func logMood(_ mood: String, tags: [FocusTag]) {
        add(JourneyTimelineEntry(
            kind: .mood,
            title: mood,
            moodEmoji: MoodCatalog.emoji(for: mood),
            focusTags: tags.map(\.rawValue)
        ))
    }

    func logDevotion(summary: DaySummary, draft: JournalDraft) {
        add(JourneyTimelineEntry(
            kind: .devotion,
            title: "Morning devotion",
            body: summary.journalPreview,
            moodEmoji: summary.moodEmoji,
            focusTags: draft.focusTags,
            verseReference: summary.verseReference
        ))
        if draft.gratitudeItems.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            add(JourneyTimelineEntry(
                kind: .gratitude,
                title: "Grateful for",
                body: draft.gratitudeItems.filter { !$0.isEmpty }.joined(separator: " · "),
                moodEmoji: summary.moodEmoji,
                focusTags: draft.focusTags
            ))
        }
        if !draft.savedVersePhrase.isEmpty {
            add(JourneyTimelineEntry(
                kind: .verse,
                title: "Saved phrase",
                body: draft.savedVersePhrase,
                verseReference: summary.verseReference
            ))
        }
        if !draft.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            add(JourneyTimelineEntry(
                kind: .reflection,
                title: "Wisdom reflection",
                body: draft.reflectionText,
                moodEmoji: summary.moodEmoji
            ))
        }
    }

    func logAnsweredPrayer(text: String) {
        add(JourneyTimelineEntry(
            kind: .answeredPrayer,
            title: "Answered prayer",
            body: text
        ))
    }

    func logEvening(highlight: String) {
        add(JourneyTimelineEntry(
            kind: .evening,
            title: "Evening reflection",
            body: highlight
        ))
    }

    func logReflection(title: String, body: String, moodEmoji: String? = nil) {
        add(JourneyTimelineEntry(
            kind: .reflection,
            title: title,
            body: body,
            moodEmoji: moodEmoji,
            focusTags: TodayFocusStore.tags.map(\.rawValue)
        ))
    }

    func logVoiceNote(transcript: String, moodEmoji: String? = nil) {
        add(JourneyTimelineEntry(
            kind: .voiceNote,
            title: "Voice note",
            body: transcript,
            moodEmoji: moodEmoji ?? "🎙️",
            focusTags: TodayFocusStore.tags.map(\.rawValue)
        ))
    }

    func logVerseViewed(reference: String, text: String) {
        guard !entries.contains(where: {
            $0.kind == .verse && $0.verseReference == reference && Calendar.current.isDateInToday($0.createdAt)
        }) else { return }
        add(JourneyTimelineEntry(
            kind: .verse,
            title: "Daily verse",
            body: text,
            verseReference: reference
        ))
    }

    func mergeRemoteEntries(_ remoteEntries: [JourneyTimelineEntry]) {
        guard !remoteEntries.isEmpty else { return }

        let existingIDs = Set(entries.map(\.id))
        let merged = remoteEntries.filter { !existingIDs.contains($0.id) } + entries
        entries = merged.sorted { $0.createdAt > $1.createdAt }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Keys.entries),
              let decoded = try? JSONDecoder().decode([JourneyTimelineEntry].self, from: data)
        else { return }
        entries = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Keys.entries)
    }
}
