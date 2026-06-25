//
//  PrayerWall.swift
//  DevotionLock
//

import Foundation
import Observation
import SwiftUI

enum PrayerNoteKind: String, Codable, CaseIterable, Identifiable {
    case request
    case reminder
    case answered

    var id: String { rawValue }

    var label: String {
        switch self {
        case .request: "Requests"
        case .reminder: "Reminders"
        case .answered: "Answered"
        }
    }

    var shortLabel: String {
        switch self {
        case .request: "Request"
        case .reminder: "Reminder"
        case .answered: "Answered"
        }
    }

    var icon: String {
        switch self {
        case .request: "hands.sparkles.fill"
        case .reminder: "bell.fill"
        case .answered: "checkmark.seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .request: ABY.Color.pillPurple
        case .reminder: ABY.Color.pillOrange
        case .answered: ABY.Color.orbSage
        }
    }

    var paperColor: Color {
        switch self {
        case .request: Color(red: 0.96, green: 0.93, blue: 0.99)
        case .reminder: Color(red: 1.0, green: 0.96, blue: 0.88)
        case .answered: Color(red: 0.90, green: 0.97, blue: 0.92)
        }
    }
}

struct PrayerWallNote: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: PrayerNoteKind
    var text: String
    let createdAt: Date
    var answeredAt: Date?
    var rotation: Double
    var tintIndex: Int

    init(
        id: UUID = UUID(),
        kind: PrayerNoteKind,
        text: String,
        createdAt: Date = Date(),
        answeredAt: Date? = nil,
        rotation: Double? = nil,
        tintIndex: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.createdAt = createdAt
        self.answeredAt = answeredAt
        self.rotation = rotation ?? Double.random(in: -2.8...2.8)
        self.tintIndex = tintIndex ?? Int.random(in: 0..<PrayerWallNote.paperVariants.count)
    }

    static let paperVariants: [Color] = [
        Color(red: 0.98, green: 0.95, blue: 0.82),
        Color(red: 0.94, green: 0.97, blue: 1.0),
        Color(red: 0.97, green: 0.93, blue: 0.96),
        Color(red: 0.92, green: 0.98, blue: 0.94),
        Color(red: 1.0, green: 0.94, blue: 0.90),
    ]

    /// Always dark — sticky notes stay pastel in both sanctuary modes.
    static let inkColor = Color(red: 0.13, green: 0.13, blue: 0.15)

    var paperColor: Color {
        kind == .answered ? PrayerNoteKind.answered.paperColor : Self.paperVariants[tintIndex % Self.paperVariants.count]
    }

    var chatPrompt: String {
        switch kind {
        case .request:
            return "I'd like to pray through this request on my wall: \"\(text)\""
        case .reminder:
            return "Help me hold onto this reminder: \"\(text)\""
        case .answered:
            return "I want to give thanks for this answered prayer: \"\(text)\""
        }
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

enum PrayerWallFilter: String, CaseIterable, Identifiable {
    case all
    case request
    case reminder
    case answered

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "All"
        case .request: "Requests"
        case .reminder: "Reminders"
        case .answered: "Answered"
        }
    }

    var kind: PrayerNoteKind? {
        switch self {
        case .all: nil
        case .request: .request
        case .reminder: .reminder
        case .answered: .answered
        }
    }
}

@Observable
@MainActor
final class PrayerWallStore {
    static let shared = PrayerWallStore()

    private enum Keys {
        static let notes = "prayerWallNotes"
        static let didSeed = "prayerWallDidSeed"
    }

    private(set) var notes: [PrayerWallNote] = []

    init() {
        load()
        seedIfNeeded()
    }

    var requestCount: Int { notes.filter { $0.kind == .request }.count }
    var reminderCount: Int { notes.filter { $0.kind == .reminder }.count }
    var answeredCount: Int { notes.filter { $0.kind == .answered }.count }

    func filtered(by filter: PrayerWallFilter) -> [PrayerWallNote] {
        guard let kind = filter.kind else {
            return notes.sorted { $0.createdAt > $1.createdAt }
        }
        return notes.filter { $0.kind == kind }.sorted { $0.createdAt > $1.createdAt }
    }

    var previewNotes: [PrayerWallNote] {
        Array(notes.prefix(4))
    }

    @discardableResult
    func add(kind: PrayerNoteKind, text: String) -> PrayerWallNote {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = PrayerWallNote(kind: kind, text: trimmed)
        notes.insert(note, at: 0)
        persist()
        PrayerWallRepository.shared.enqueue(note)
        return note
    }

    func markAnswered(_ id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        let text = notes[index].text
        notes[index].kind = .answered
        notes[index].answeredAt = Date()
        notes[index].rotation = Double.random(in: -1.5...1.5)
        persist()
        JourneyTimelineStore.shared.logAnsweredPrayer(text: text)
        DailyRhythmStore.shared.markComplete(.prayerWall)
        AnsweredCelebrationStore.activate(text: text)
        NotificationManager.shared.postAnsweredPrayerCelebration(text: text)
        PrayerWallRepository.shared.enqueue(notes[index])
    }

    func delete(_ id: UUID) {
        notes.removeAll { $0.id == id }
        persist()
        Task { await PrayerWallRepository.shared.deleteRemote(id) }
    }

    func mergeRemoteNotes(_ remoteNotes: [PrayerWallNote]) {
        guard !remoteNotes.isEmpty else { return }
        let existingIDs = Set(notes.map(\.id))
        let merged = remoteNotes.filter { !existingIDs.contains($0.id) } + notes
        notes = merged.sorted { $0.createdAt > $1.createdAt }
        persist()
    }

    func clearDemoData() {
        guard UserDefaults.standard.bool(forKey: Keys.didSeed) else { return }
        notes.removeAll()
        UserDefaults.standard.removeObject(forKey: Keys.notes)
        UserDefaults.standard.set(false, forKey: Keys.didSeed)
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Keys.notes),
              let decoded = try? JSONDecoder().decode([PrayerWallNote].self, from: data)
        else { return }
        notes = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        UserDefaults.standard.set(data, forKey: Keys.notes)
        SharedDataSync.scheduleRefresh(prayerWallStore: self)
    }

    private func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Keys.didSeed), notes.isEmpty else { return }
        notes = [
            PrayerWallNote(
                kind: .request,
                text: "Peace for my family through this season of change.",
                createdAt: Date().addingTimeInterval(-86400 * 2),
                rotation: -2.2,
                tintIndex: 0
            ),
            PrayerWallNote(
                kind: .reminder,
                text: "God is closer than my next breath.",
                createdAt: Date().addingTimeInterval(-86400),
                rotation: 1.8,
                tintIndex: 2
            ),
            PrayerWallNote(
                kind: .answered,
                text: "Clarity about the job decision — doors opened gently.",
                createdAt: Date().addingTimeInterval(-86400 * 5),
                answeredAt: Date().addingTimeInterval(-86400),
                rotation: -1.1,
                tintIndex: 3
            ),
            PrayerWallNote(
                kind: .request,
                text: "Strength for a friend walking through grief.",
                createdAt: Date().addingTimeInterval(-3600 * 6),
                rotation: 2.4,
                tintIndex: 1
            ),
        ]
        persist()
        UserDefaults.standard.set(true, forKey: Keys.didSeed)
    }
}
