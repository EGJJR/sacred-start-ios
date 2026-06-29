//
//  MainTabCoordinator.swift
//  DevotionLock
//
//  Central presentation state for MainTabView — replaces boolean sheet flags.
//

import SwiftUI

@Observable
@MainActor
final class MainTabCoordinator {
    var selectedTab: AppTab = .home
    var sheet: MainSheetPresentation?
    var fullScreen: MainFullScreenPresentation?

    var voiceSessionPrompt: String?
    var voiceTranscriptHandoff: String?
    var assistedJournalPrompt: String?
    var isVoiceSessionPresented = false
    var chaplainPortal: ChaplainPortalPresentation?

    func openConversation(_ conversation: Conversation) {
        sheet = .conversation(conversation)
    }

    func openStreakScreen() {
        sheet = .streakScreen
    }

    func openPrayerWall(
        addKind: PrayerNoteKind? = nil,
        initialTab: PrayerWallTab = .myWall,
        joinCode: String? = nil
    ) {
        sheet = .prayerWall(
            PrayerWallLaunch(addKind: addKind, initialTab: initialTab, joinCode: joinCode)
        )
    }

    func openChaplainChat(
        starter: String?,
        seedMessages: [ChaplainMessage],
        resumeConversationID: UUID? = nil
    ) {
        fullScreen = .chaplain(makeChaplainLaunch(
            starter: starter,
            seedMessages: seedMessages,
            resumeConversationID: resumeConversationID
        ))
    }

    func openChaplainChatWithPortal(voiceName: String, starter: String?, seedMessages: [ChaplainMessage]) {
        var launch = makeChaplainLaunch(starter: starter, seedMessages: seedMessages)
        launch.playsPortalEntrance = true
        chaplainPortal = ChaplainPortalPresentation(voiceName: voiceName, launch: launch)
    }

    func completeChaplainPortalTransition() {
        guard let portal = chaplainPortal else { return }
        fullScreen = .chaplain(portal.launch)
        chaplainPortal = nil
    }

    private func makeChaplainLaunch(
        starter: String?,
        seedMessages: [ChaplainMessage],
        resumeConversationID: UUID? = nil
    ) -> ChaplainChatLaunch {
        let resumeID = resumeConversationID ?? ChaplainSessionStore.shared.consumePendingResumeID()
        var launch = ChaplainChatLaunch(
            starterText: starter ?? "",
            seedMessages: seedMessages,
            resumeConversationID: resumeID
        )
        if starter?.localizedCaseInsensitiveContains("expand this reflection") == true {
            launch.contextIntent = "expand_reflection"
        }
        return launch
    }

    func resumeChaplainChat(_ conversation: Conversation) {
        fullScreen = .chaplain(
            ChaplainChatLaunch(
                resumeConversationID: conversation.remoteID ?? conversation.id,
                resumedContext: conversation
            )
        )
    }

    func openGuidedJournal() {
        fullScreen = .guidedJournal
    }

    func openJournalEntryHub() {
        sheet = .journalEntryHub
    }

    func openDailyVerse() {
        sheet = .dailyVerse
    }

    func openEveningReflection() {
        sheet = .eveningReflection
    }

    func openAssistedJournal(prompt: String? = nil) {
        assistedJournalPrompt = prompt
        fullScreen = .assistedJournal
    }

    func openVoiceJournal() {
        fullScreen = .voiceJournal
    }

    func openMorningWrapped() {
        fullScreen = .morningWrapped
    }

    func openJourneyTimeline() {
        fullScreen = .journeyTimeline
    }

    func openVoiceSession(prompt: String?) {
        voiceSessionPrompt = prompt
        isVoiceSessionPresented = true
    }

    func closeVoiceSession() {
        isVoiceSessionPresented = false
        voiceSessionPrompt = nil
        voiceTranscriptHandoff = nil
    }

    func handleDevotionFinished(_ result: DevotionFinishResult) {
        if result.isFirstCompletionEver {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                fullScreen = .streakBorn
            }
        } else {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                fullScreen = .celebration(result)
            }
            /*
            if result.streak >= 2,
               !UserDefaults.standard.bool(forKey: "hasSeenWidgetOnboarding") {
                UserDefaults.standard.set(true, forKey: "hasSeenWidgetOnboarding")
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    fullScreen = .widgetOnboarding
                }
            }
            */
        }
    }

    func handleCelebrationDismissed(
        result: DevotionFinishResult,
        streakManager: StreakManager
    ) {
        fullScreen = nil
        if streakManager.shouldCelebrateMilestone(days: result.streak) {
            fullScreen = .milestone(MilestonePresentation(days: result.streak))
        }
    }

    // MARK: - Sacred orb

    func sacredOrbState(
        rhythmStore: DailyRhythmStore,
        streakManager: StreakManager
    ) -> SacredOrbState {
        SacredOrbResolver.resolve(
            selectedTab: selectedTab,
            rhythmStore: rhythmStore,
            streakManager: streakManager,
            showMicroLabel: SacredOrbSessionTracker.showsMicroLabel
        )
    }

    func performSacredOrbAction(_ state: SacredOrbState) {
        SacredOrbSessionTracker.recordTap()

        switch state.destination {
        case .guidedDevotion:
            openGuidedJournal()
        case .journalHub:
            openJournalEntryHub()
        case .eveningReflection:
            sheet = .eveningReflection
        case .assistedJournal(let prompt):
            openAssistedJournal(prompt: prompt)
        case .chaplain(let starter, let resumeID):
            openChaplainChat(
                starter: starter,
                seedMessages: [],
                resumeConversationID: resumeID
            )
        }
    }

    var sacredOrbMenuActions: [SacredOrbQuickAction] = []
    var sacredOrbQuickMenuPresented = false

    func presentSacredOrbQuickMenu(
        rhythmStore: DailyRhythmStore,
        streakManager: StreakManager
    ) {
        sacredOrbMenuActions = SacredOrbResolver.quickActions(
            selectedTab: selectedTab,
            rhythmStore: rhythmStore,
            streakManager: streakManager
        )
        sacredOrbQuickMenuPresented = true
    }

    func dismissSacredOrbQuickMenu() {
        sacredOrbQuickMenuPresented = false
    }

    func performSacredOrbQuickAction(_ action: SacredOrbQuickAction) {
        sacredOrbQuickMenuPresented = false
        switch action {
        case .morningDevotion:
            sheet = nil
            openGuidedJournal()
        case .journalCapture:
            sheet = .journalEntryHub
        case .assistedWrite:
            sheet = nil
            openAssistedJournal()
        case .voiceNote:
            sheet = nil
            openVoiceJournal()
        case .eveningReflection:
            sheet = .eveningReflection
        case .chaplain:
            sheet = nil
            let state = sacredOrbState(
                rhythmStore: DailyRhythmStore.shared,
                streakManager: StreakManager.shared
            )
            if case .chaplain(let starter, let resumeID) = state.destination {
                openChaplainChat(
                    starter: starter,
                    seedMessages: [],
                    resumeConversationID: resumeID
                )
            } else {
                openChaplainChat(starter: nil, seedMessages: [])
            }
        }
    }
}
