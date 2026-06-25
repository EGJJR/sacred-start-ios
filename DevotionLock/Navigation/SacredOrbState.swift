//
//  SacredOrbState.swift
//  DevotionLock
//
//  Resolves the center orb's next sacred action from daily rhythm state.
//

import Foundation

// MARK: - Destination

enum SacredOrbDestination: Equatable {
    case guidedDevotion
    case journalHub
    case eveningReflection
    case assistedJournal(prompt: String?)
    case chaplain(starter: String?, resumeConversationID: UUID?)
}

// MARK: - Visual style

enum SacredOrbVisualStyle: Equatable {
    /// Morning devotion still open — inviting pulse.
    case pulse
    /// Mid-day rhythm — steady, calm breathe.
    case calm
    /// Day complete — soft rest glow.
    case rest
    /// Background preparation — faster dot weave, soft teal bloom (polish, guided prayer).
    case weaving
}

// MARK: - Resolved state

struct SacredOrbState: Equatable {
    let shortLabel: String
    let microLabel: String?
    let accessibilityLabel: String
    let visualStyle: SacredOrbVisualStyle
    let destination: SacredOrbDestination
    /// Journal tab + morning devotion pending — teach without wrong routing.
    let showsMorningFirstNudge: Bool
    /// Completed daily rhythm rings today (0…1) — drawn as an arc on the orb.
    let rhythmProgress: CGFloat
}

// MARK: - Session teaching

enum SacredOrbSessionTracker {
    private static let tapCountKey = "sacredOrbTapSessionCount"

    static var tapCount: Int {
        UserDefaults.standard.integer(forKey: tapCountKey)
    }

    static var showsMicroLabel: Bool {
        tapCount < 7
    }

    static func recordTap() {
        UserDefaults.standard.set(tapCount + 1, forKey: tapCountKey)
    }
}

// MARK: - Resolver

@MainActor
enum SacredOrbResolver {
    static let morningHourCutoff = 10
    static let eveningHourStart = 17

    static func resolve(
        selectedTab: AppTab,
        rhythmStore: DailyRhythmStore,
        streakManager: StreakManager,
        showMicroLabel: Bool,
        now: Date = Date()
    ) -> SacredOrbState {
        let hour = Calendar.current.component(.hour, from: now)
        let isMorning = hour < morningHourCutoff
        let isEvening = hour >= eveningHourStart

        let devotionDone = rhythmStore.isComplete(.morningDevotion, on: now)
            || streakManager.isCompletedToday
        let capturedToday = hasCapturedToday(now: now)
        let eveningDone = rhythmStore.isComplete(.eveningReflection, on: now)
        let allRingsDone = DailyRhythmRing.allCases.allSatisfy {
            rhythmStore.isComplete($0, on: now)
        }
        let rhythmProgress = rhythmCompletionProgress(rhythmStore: rhythmStore, on: now)

        // Journal tab: honor capture intent, but nudge morning first when appropriate.
        if selectedTab == .conversations {
            if !devotionDone && isMorning {
                return makeState(
                    shortLabel: "Begin",
                    microLabel: showMicroLabel ? "Morning first?" : nil,
                    accessibilityLabel: "Begin morning devotion",
                    visualStyle: .pulse,
                    destination: .guidedDevotion,
                    showsMorningFirstNudge: true,
                    rhythmProgress: rhythmProgress
                )
            }
            if devotionDone && !capturedToday {
                return captureState(showMicroLabel: showMicroLabel, rhythmProgress: rhythmProgress)
            }
        }

        if !devotionDone {
            return makeState(
                shortLabel: "Begin",
                microLabel: showMicroLabel ? "Begin" : nil,
                accessibilityLabel: "Begin devotion",
                visualStyle: .pulse,
                destination: .guidedDevotion,
                showsMorningFirstNudge: false,
                rhythmProgress: rhythmProgress
            )
        }

        if !capturedToday {
            return captureState(showMicroLabel: showMicroLabel, rhythmProgress: rhythmProgress)
        }

        if isEvening && !eveningDone {
            return makeState(
                shortLabel: "Reflect",
                microLabel: showMicroLabel ? "Reflect" : nil,
                accessibilityLabel: "Reflect on today",
                visualStyle: .calm,
                destination: .eveningReflection,
                showsMorningFirstNudge: false,
                rhythmProgress: rhythmProgress
            )
        }

        if allRingsDone {
            return continueState(
                isEvening: isEvening,
                showMicroLabel: showMicroLabel,
                visualStyle: .rest,
                rhythmProgress: rhythmProgress
            )
        }

        return continueState(
            isEvening: isEvening,
            showMicroLabel: showMicroLabel,
            visualStyle: .calm,
            rhythmProgress: rhythmProgress
        )
    }

    // MARK: - Helpers

    static func rhythmCompletionProgress(rhythmStore: DailyRhythmStore, on date: Date) -> CGFloat {
        let total = CGFloat(DailyRhythmRing.allCases.count)
        guard total > 0 else { return 0 }
        let completed = CGFloat(
            DailyRhythmRing.allCases.filter { rhythmStore.isComplete($0, on: date) }.count
        )
        return min(1, completed / total)
    }

    @MainActor
    static func hasCapturedToday(now: Date = Date()) -> Bool {
        let calendar = Calendar.current

        let localCapture = JournalLocalStore.shared.entries.contains { entry in
            calendar.isDateInToday(entry.createdAt)
                && entry.kind != .chaplainChat
        }
        if localCapture { return true }

        return ConversationMerger.mergedTimeline().contains { conversation in
            conversation.isToday && !ConversationMerger.isChaplainChat(conversation)
        }
    }

    private static func captureState(showMicroLabel: Bool, rhythmProgress: CGFloat) -> SacredOrbState {
        makeState(
            shortLabel: "Capture",
            microLabel: showMicroLabel ? "Capture" : nil,
            accessibilityLabel: "Add to journal",
            visualStyle: .calm,
            destination: .journalHub,
            showsMorningFirstNudge: false,
            rhythmProgress: rhythmProgress
        )
    }

    private static func continueState(
        isEvening: Bool,
        showMicroLabel: Bool,
        visualStyle: SacredOrbVisualStyle,
        rhythmProgress: CGFloat
    ) -> SacredOrbState {
        let resumable = ChaplainSessionStore.shared.resumableConversation
        let resumeToday = resumable.map {
            Calendar.current.isDateInToday($0.updatedAt)
        } ?? false

        let starter: String?
        let resumeID: UUID?
        if resumeToday, let resumable {
            starter = nil
            resumeID = resumable.id
        } else {
            starter = isEvening
                ? "What's on your heart as the day winds down?"
                : "What would you like to sit with your Chaplain about?"
            resumeID = nil
        }

        return makeState(
            shortLabel: "Continue",
            microLabel: showMicroLabel ? (visualStyle == .rest ? "Rest well" : "Continue") : nil,
            accessibilityLabel: resumeToday ? "Continue Chaplain conversation" : "Talk with Chaplain",
            visualStyle: visualStyle,
            destination: .chaplain(starter: starter, resumeConversationID: resumeID),
            showsMorningFirstNudge: false,
            rhythmProgress: rhythmProgress
        )
    }

    private static func makeState(
        shortLabel: String,
        microLabel: String?,
        accessibilityLabel: String,
        visualStyle: SacredOrbVisualStyle,
        destination: SacredOrbDestination,
        showsMorningFirstNudge: Bool,
        rhythmProgress: CGFloat
    ) -> SacredOrbState {
        SacredOrbState(
            shortLabel: shortLabel,
            microLabel: microLabel,
            accessibilityLabel: accessibilityLabel,
            visualStyle: visualStyle,
            destination: destination,
            showsMorningFirstNudge: showsMorningFirstNudge,
            rhythmProgress: rhythmProgress
        )
    }

    static func quickActions(
        selectedTab: AppTab,
        rhythmStore: DailyRhythmStore,
        streakManager: StreakManager,
        now: Date = Date()
    ) -> [SacredOrbQuickAction] {
        let hour = Calendar.current.component(.hour, from: now)
        let isEvening = hour >= eveningHourStart
        let devotionDone = rhythmStore.isComplete(.morningDevotion, on: now)
            || streakManager.isCompletedToday
        let eveningDone = rhythmStore.isComplete(.eveningReflection, on: now)

        var actions: [SacredOrbQuickAction] = []
        if !devotionDone {
            actions.append(.morningDevotion)
        }
        actions.append(.journalCapture)
        actions.append(.assistedWrite)
        if FeatureFlags.voiceChatEnabled {
            actions.append(.voiceNote)
        }
        if isEvening && !eveningDone {
            actions.append(.eveningReflection)
        }
        actions.append(.chaplain)
        return actions
    }
}
