//
//  SyncCoordinator.swift
//  DevotionLock
//
//  Central sync orchestrator: pulls remote data and flushes offline queues after sign-in
//  and on foreground. Runs on a detached task so SwiftUI `.task` cancellation does not
//  abort in-flight Supabase requests (which previously logged CancellationError everywhere).
//

import Foundation

enum SyncErrorFilter {
    /// True for structured-concurrency cancellation and URLSession -999.
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return true }
        return false
    }

    #if DEBUG
    static func logPullFailure(_ repository: String, _ error: Error) {
        guard !isCancellation(error) else { return }
        print("\(repository) pull failed: \(error)")
    }
    #else
    static func logPullFailure(_ repository: String, _ error: Error) {}
    #endif
}

@MainActor
final class SyncCoordinator {
    static let shared = SyncCoordinator()

    private var isFlushing = false
    private var flushAgain = false
    private var pendingForce = false
    private var lastFlushAt: Date?
    private let minimumFlushInterval: TimeInterval = 30
    private var activeFlush: Task<Void, Never>?

    func onAuthenticated() {
        scheduleFlush(force: true)
    }

    func onForeground() {
        scheduleFlush(force: false)
    }

    /// Starts a flush that survives SwiftUI view-task cancellation.
    func scheduleFlush(force: Bool = false) {
        guard AuthManager.shared.isAuthenticated else { return }
        if force { pendingForce = true }

        if isFlushing {
            flushAgain = true
            return
        }

        if !force, !pendingForce,
           let lastFlushAt,
           Date().timeIntervalSince(lastFlushAt) < minimumFlushInterval {
            return
        }

        activeFlush = Task.detached(priority: .utility) { @MainActor in
            await SyncCoordinator.shared.runFlushLoop()
        }
    }

    /// Await the in-flight detached flush (e.g. pull-to-refresh). Caller may be cancelled; sync continues.
    func flushAll(force: Bool = false) async {
        scheduleFlush(force: force)
        await activeFlush?.value
    }

    private func runFlushLoop() async {
        guard !isFlushing else {
            flushAgain = true
            return
        }

        isFlushing = true
        defer {
            isFlushing = false
            activeFlush = nil
        }

        let force = pendingForce
        pendingForce = false

        if !force,
           let lastFlushAt,
           Date().timeIntervalSince(lastFlushAt) < minimumFlushInterval {
            return
        }

        repeat {
            flushAgain = false
            lastFlushAt = Date()
            await performFlush()
        } while flushAgain
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
