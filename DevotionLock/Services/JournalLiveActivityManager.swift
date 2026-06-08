//
//  JournalLiveActivityManager.swift
//  DevotionLock
//

import ActivityKit
import Foundation

@MainActor
enum JournalLiveActivityManager {
    private static var activity: Activity<JournalActivityAttributes>?

    static func startIfAvailable() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()

        let attributes = JournalActivityAttributes(sessionTitle: "Morning Devotion")
        let state = JournalActivityAttributes.ContentState(
            stepIndex: 0,
            stepTitle: "How are you arriving?",
            totalSteps: GuidedJournalStep.allCases.count,
            elapsedSeconds: 0
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {}
    }

    static func update(step: GuidedJournalStep, elapsedSeconds: Int) {
        guard let activity else { return }
        let title: String = switch step {
        case .mood: "How are you arriving?"
        case .focusTags: "What's in focus?"
        case .madLibs: "Tell your story"
        case .gratitude: "Three gratitudes"
        case .affirmation: "Today I will…"
        case .scripture: "Today's word"
        case .voice: "Talk with Chaplain"
        case .complete: "Finishing up"
        }
        let state = JournalActivityAttributes.ContentState(
            stepIndex: step.progressIndex,
            stepTitle: title,
            totalSteps: GuidedJournalStep.allCases.count,
            elapsedSeconds: elapsedSeconds
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    static func end() {
        guard let activity else { return }
        let final = JournalActivityAttributes.ContentState(
            stepIndex: GuidedJournalStep.complete.progressIndex,
            stepTitle: "Devotion complete",
            totalSteps: GuidedJournalStep.allCases.count,
            elapsedSeconds: 0
        )
        Task {
            await activity.end(.init(state: final, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
