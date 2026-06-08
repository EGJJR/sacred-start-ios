//
//  SyncCoordinator.swift
//  DevotionLock
//
//  Central sync orchestrator: pulls remote data and flushes offline queues after sign-in
//  and on foreground. Debounced so token refresh / rapid lifecycle events don't stack
//  redundant full syncs (which previously caused memory pressure).
//

import Foundation

@MainActor
final class SyncCoordinator {
    static let shared = SyncCoordinator()

    /// Coalesces overlapping flushAll() calls into one performFlush() pass.
    private var isFlushing = false
    private var flushAgain = false
    /// Skips non-forced flushes within this window (foreground can be chatty).
    private var lastFlushAt: Date?
    private let minimumFlushInterval: TimeInterval = 30

    func onAuthenticated() async {
        DemoDataCleaner.clearIfAuthenticated()
        await flushAll(force: true)
    }

    func flushAll(force: Bool = false) async {
        guard AuthManager.shared.isAuthenticated else { return }

        if !force,
           let lastFlushAt,
           Date().timeIntervalSince(lastFlushAt) < minimumFlushInterval {
            return
        }

        if isFlushing {
            flushAgain = true
            return
        }

        isFlushing = true
        defer { isFlushing = false }

        repeat {
            flushAgain = false
            lastFlushAt = Date()
            await performFlush()
        } while flushAgain
    }

    func onForeground() async {
        await flushAll()
    }

    private func performFlush() async {
        await UserPreferencesSync.shared.pullAndApply()
        await DevotionSessionRepository.shared.pullRemote()
        await JourneyEntryRepository.shared.pullRemote()
        await PrayerWallRepository.shared.pullRemote()
        await DailyRhythmRepository.shared.pullRemote()
        await ConversationRepository.shared.refresh()
        await DevotionSessionRepository.shared.flushPending()
        await JourneyEntryRepository.shared.flushPending()
        await PrayerWallRepository.shared.flushPending()
        await CircleRepository.shared.flushPending()
        await CircleRepository.shared.pullRemote(into: PrayerCircleStore.shared)
    }
}
