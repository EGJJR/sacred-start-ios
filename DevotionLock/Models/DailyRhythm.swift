//
//  DailyRhythm.swift
//  DevotionLock
//

import Foundation
import Observation

enum DailyRhythmRing: String, CaseIterable, Identifiable, Codable {
    case dailyVerse
    case morningDevotion
    case eveningReflection
    case prayerWall

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dailyVerse: "Daily Verse"
        case .morningDevotion: "Morning Devotion"
        case .eveningReflection: "Evening Reflection"
        case .prayerWall: "Prayer Wall"
        }
    }

    var shortLabel: String {
        switch self {
        case .dailyVerse: "Verse"
        case .morningDevotion: "Morning"
        case .eveningReflection: "Evening"
        case .prayerWall: "Prayer"
        }
    }

    var icon: String {
        switch self {
        case .dailyVerse: "text.quote"
        case .morningDevotion: "sun.horizon.fill"
        case .eveningReflection: "moon.stars.fill"
        case .prayerWall: "hands.sparkles.fill"
        }
    }

    var accentHex: UInt {
        switch self {
        case .dailyVerse: 0x8C7BB8
        case .morningDevotion: 0x4D9E94
        case .eveningReflection: 0x6B7FD7
        case .prayerWall: 0xEB8C52
        }
    }
}

@Observable
@MainActor
final class DailyRhythmStore {
    static let shared = DailyRhythmStore()

    private enum Keys {
        static let completions = "dailyRhythmCompletionsByDate"
    }

    private var completionsByDate: [String: Set<String>] = [:]
    /// Bumps when completions change so views reliably refresh.
    private(set) var revision = 0

    init() {
        load()
    }

    func isComplete(_ ring: DailyRhythmRing, on date: Date = Date()) -> Bool {
        completions(for: date).contains(ring.rawValue)
    }

    func markComplete(_ ring: DailyRhythmRing, on date: Date = Date()) {
        let key = dateKey(for: date)
        var set = completionsByDate[key] ?? []
        guard !set.contains(ring.rawValue) else { return }
        set.insert(ring.rawValue)
        completionsByDate[key] = set
        revision += 1
        persist()
        NotificationCenter.default.post(name: .devotionRhythmDidUpdate, object: nil)
        DailyRhythmRepository.shared.syncCompletion(ring: ring, on: date)
    }

    func mergeRemoteCompletions(_ rows: [(completionDate: String, ringKind: String)]) {
        guard !rows.isEmpty else { return }
        for row in rows {
            var set = completionsByDate[row.completionDate] ?? []
            set.insert(row.ringKind)
            completionsByDate[row.completionDate] = set
        }
        revision += 1
        persist()
    }

    func completionFlagsToday() -> [Bool] {
        DailyRhythmRing.allCases.map { isComplete($0) }
    }

    func syncFromExistingState() {
        let today = Date()
        if StreakManager.shared.isCompletedToday {
            markComplete(.morningDevotion, on: today)
        }
        if PrayerWallStore.shared.notes.isEmpty == false {
            let calendar = Calendar.current
            if PrayerWallStore.shared.notes.contains(where: {
                calendar.isDateInToday($0.createdAt) || ($0.answeredAt.map { calendar.isDateInToday($0) } ?? false)
            }) {
                markComplete(.prayerWall, on: today)
            }
        }
    }

    #if DEBUG
    func clearTodayCompletions() {
        let key = dateKey(for: Date())
        completionsByDate.removeValue(forKey: key)
        revision += 1
        persist()
        NotificationCenter.default.post(name: .devotionRhythmDidUpdate, object: nil)
    }
    #endif

    private func completions(for date: Date) -> Set<String> {
        completionsByDate[dateKey(for: date)] ?? []
    }

    private func dateKey(for date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Keys.completions),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return }
        completionsByDate = decoded.mapValues { Set($0) }
    }

    private func persist() {
        let encoded = completionsByDate.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: Keys.completions)
        }
        SharedDataSync.scheduleRefresh(syncRhythmFromStores: false)
    }
}
