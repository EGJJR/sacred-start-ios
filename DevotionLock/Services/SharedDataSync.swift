//
//  SharedDataSync.swift
//  DevotionLock
//

import Foundation
import WidgetKit

enum SharedDataSync {
    @MainActor
    static func refreshSharedStores() {
        DailyRhythmStore.shared.syncFromExistingState()
        refresh(
            streakManager: StreakManager.shared,
            prayerWallStore: PrayerWallStore.shared
        )
    }

    @MainActor
    private static func celebrationState() -> (text: String?, active: Bool) {
        let state = AnsweredCelebrationStore.current()
        return (state.active ? state.text : nil, state.active)
    }

    @MainActor
    static func refresh(
        streakManager: StreakManager,
        prayerWallStore: PrayerWallStore
    ) {
        let quote = LoadingQuoteCatalog.today
        let notes = prayerWallStore.notes.prefix(4).map { note in
            WidgetPrayerNoteSnapshot(
                id: note.id.uuidString,
                kind: note.kind.rawValue,
                text: note.text,
                tintIndex: note.tintIndex,
                rotation: note.rotation
            )
        }
        let celebration = celebrationState()

        let snapshot = WidgetSnapshot(
            currentStreak: streakManager.currentStreak,
            isCompletedToday: streakManager.isCompletedToday,
            weekCompletionFlags: streakManager.weekCompletionFlags,
            shieldEnabled: UserDefaults.standard.object(forKey: "shieldEnabled") as? Bool ?? true,
            quoteText: quote.text,
            quoteReference: quote.reference,
            prayerRequestCount: prayerWallStore.requestCount,
            prayerAnsweredCount: prayerWallStore.answeredCount,
            prayerNotes: Array(notes),
            rhythmCompletionFlags: DailyRhythmStore.shared.completionFlagsToday(),
            answeredCelebrationText: celebration.text,
            answeredCelebrationActive: celebration.active,
            updatedAt: Date()
        )

        WidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
