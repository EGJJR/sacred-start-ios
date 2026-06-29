//
//  JournalLiveActivityManager.swift
//  DevotionLock
//

import ActivityKit
import Foundation

@MainActor
enum JournalLiveActivityManager {
    private static var activity: Activity<JournalActivityAttributes>?
    private static var elapsedTicker: Task<Void, Never>?

    // MARK: - Morning devotion

    static func startDevotionIfAvailable() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()

        let attributes = JournalActivityAttributes(sessionTitle: "Morning Devotion")
        let state = devotionState(step: .mood, elapsedSeconds: 0)

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            startElapsedTicker { elapsed in
                guard let step = currentDevotionStep else { return }
                updateDevotion(step: step, elapsedSeconds: elapsed)
            }
        } catch {}
    }

    private static var currentDevotionStep: GuidedJournalStep?

    static func updateDevotion(step: GuidedJournalStep, elapsedSeconds: Int) {
        currentDevotionStep = step
        guard let activity else { return }
        let state = devotionState(step: step, elapsedSeconds: elapsedSeconds)
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    private static func devotionState(step: GuidedJournalStep, elapsedSeconds: Int) -> JournalActivityAttributes.ContentState {
        let title: String = switch step {
        case .mood: "How are you?"
        case .focusTags: "What's in focus?"
        case .madLibs: "Tell your story"
        case .gratitude: "Three gratitudes"
        case .affirmation: "Today I will…"
        case .scripture: "Today's word"
        case .voice: "Talk with Chaplain"
        case .complete: "Finishing up"
        }
        return JournalActivityAttributes.ContentState(
            session: .morningDevotion,
            stepIndex: step.progressIndex,
            stepTitle: title,
            totalSteps: GuidedJournalStep.allCases.count,
            elapsedSeconds: elapsedSeconds,
            breathsRemaining: 0,
            breathPhaseLabel: ""
        )
    }

    // MARK: - Prayer breath

    static func startPrayerBreathIfAvailable(
        title: String,
        breathsRemaining: Int,
        phaseLabel: String,
        elapsedSeconds: Int = 0
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()

        let attributes = JournalActivityAttributes(sessionTitle: title)
        let state = breathState(
            title: phaseLabel,
            breathsRemaining: breathsRemaining,
            phaseLabel: phaseLabel,
            elapsedSeconds: elapsedSeconds
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {}
    }

    static func updatePrayerBreath(
        title: String,
        breathsRemaining: Int,
        phaseLabel: String,
        elapsedSeconds: Int
    ) {
        guard let activity else { return }
        let state = breathState(
            title: title,
            breathsRemaining: breathsRemaining,
            phaseLabel: phaseLabel,
            elapsedSeconds: elapsedSeconds
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    private static func breathState(
        title: String,
        breathsRemaining: Int,
        phaseLabel: String,
        elapsedSeconds: Int
    ) -> JournalActivityAttributes.ContentState {
        JournalActivityAttributes.ContentState(
            session: .prayerBreath,
            stepIndex: max(0, 3 - breathsRemaining),
            stepTitle: title,
            totalSteps: 3,
            elapsedSeconds: elapsedSeconds,
            breathsRemaining: breathsRemaining,
            breathPhaseLabel: phaseLabel
        )
    }

    // MARK: - Shared

    static func end() {
        elapsedTicker?.cancel()
        elapsedTicker = nil
        currentDevotionStep = nil

        guard let activity else { return }
        let final = JournalActivityAttributes.ContentState(
            session: .morningDevotion,
            stepIndex: GuidedJournalStep.complete.progressIndex,
            stepTitle: "Complete",
            totalSteps: GuidedJournalStep.allCases.count,
            elapsedSeconds: 0,
            breathsRemaining: 0,
            breathPhaseLabel: ""
        )
        Task {
            await activity.end(.init(state: final, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
    }

    private static func startElapsedTicker(tick: @escaping @MainActor (Int) -> Void) {
        elapsedTicker?.cancel()
        let started = Date()
        elapsedTicker = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { return }
                let elapsed = Int(Date().timeIntervalSince(started))
                await MainActor.run { tick(elapsed) }
            }
        }
    }
}
