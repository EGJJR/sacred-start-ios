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
    var isVoiceSessionPresented = false

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
        let resumeID = resumeConversationID ?? ChaplainSessionStore.shared.consumePendingResumeID()
        var launch = ChaplainChatLaunch(
            starterText: starter ?? "",
            seedMessages: seedMessages,
            resumeConversationID: resumeID
        )
        if starter?.localizedCaseInsensitiveContains("expand this reflection") == true {
            launch.contextIntent = "expand_reflection"
        }
        fullScreen = .chaplain(launch)
    }

    func resumeChaplainChat(_ conversation: Conversation) {
        fullScreen = .chaplain(
            ChaplainChatLaunch(
                resumeConversationID: conversation.remoteID ?? conversation.id
            )
        )
    }

    func openGuidedJournal() {
        fullScreen = .guidedJournal
    }

    func openJournalEntryHub() {
        sheet = .journalEntryHub
    }

    func openAssistedJournal() {
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
            if result.streak >= 2,
               !UserDefaults.standard.bool(forKey: "hasSeenWidgetOnboarding") {
                UserDefaults.standard.set(true, forKey: "hasSeenWidgetOnboarding")
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    fullScreen = .widgetOnboarding
                }
            }
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
}
