//
//  MainTabView.swift
//  DevotionLock
//
//  Tab shell + modal presentations (devotion, Chaplain, prayer wall, streaks, etc.).
//  Premium-gated actions call PaywallAccess.guardPremium before opening flows.
//  DeepLinkRouter and widget intents land here.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.presentDevotionPaywall) private var presentPaywall

    @State private var selectedTab: AppTab = .home
    @State private var showVoiceSession = false
    @State private var voiceStarterPrompt: String?
    @State private var voiceTranscriptHandoff: String?
    @State private var showChaplainChat = false
    @State private var chaplainChatSessionID = UUID()
    @State private var chatStarterText = ""
    @State private var chatSeedMessages: [ChaplainMessage] = []
    @State private var chatContextIntent: String?
    @State private var resumeConversationID: UUID?
    @State private var showGuidedJournal = false
    @State private var showStreakScreen = false
    @State private var showStreakBorn = false
    @State private var showMorningWrapped = false
    @State private var showPrayerWall = false
    @State private var prayerWallAddKind: PrayerNoteKind?
    @State private var prayerWallInitialTab: PrayerWallTab = .myWall
    @State private var prayerWallJoinCode: String?
    @State private var showWidgetOnboarding = false
    @State private var showJourneyTimeline = false
    @State private var pendingCelebration: DevotionFinishResult?
    @State private var selectedConversation: Conversation?
    @State private var streakManager = StreakManager.shared
    @State private var auth = AuthManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            ABYBackground()

            tabContent
                .id(selectedTab)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 8)),
                    removal: .opacity.combined(with: .offset(y: -4))
                ))
                .animation(AppTheme.springSnappy, value: selectedTab)

            BottomNavigationBar(selectedTab: $selectedTab) {
                if selectedTab == .conversations {
                    PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                        JournalPresentationStore.shared.presentEntryHub = true
                    }
                } else {
                    openGuidedJournalIfAllowed()
                }
            }
        }
        .abyScreen()
        .fullScreenCover(isPresented: $showVoiceSession) {
            RecordingSessionView(
                isPresented: $showVoiceSession,
                initialPrompt: voiceStarterPrompt,
                onComplete: { _ in
                    showVoiceSession = false
                },
                onSwitchToChat: { transcript in
                    showVoiceSession = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        openChaplainChatIfAllowed(
                            starter: VoiceChatHandoff.starter(from: transcript),
                            seedMessages: VoiceChatHandoff.seedMessages(for: transcript)
                        )
                    }
                },
                voiceTranscript: voiceTranscriptHandoff,
                saveOnlyLabel: "Close without chat"
            )
            .presentationBackground {
                ABYCleanGradientBackground()
            }
        }
        .onChange(of: showVoiceSession) { _, isShowing in
            if !isShowing {
                voiceStarterPrompt = nil
                voiceTranscriptHandoff = nil
            }
        }
        .fullScreenCover(isPresented: $showChaplainChat) {
            ChaplainChatView(
                isPresented: $showChaplainChat,
                voice: selectedChaplainVoice,
                seedMessages: chatSeedMessages,
                starterText: chatStarterText,
                contextIntent: chatContextIntent,
                resumeConversationID: resumeConversationID,
                onVoice: {
                    showChaplainChat = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        openVoiceIfAllowed(prompt: nil)
                    }
                }
            )
            .id(chaplainChatSessionID)
        }
        .onChange(of: showChaplainChat) { _, isShowing in
            if !isShowing {
                chatStarterText = ""
                chatSeedMessages = []
                chatContextIntent = nil
                resumeConversationID = nil
            }
        }
        .fullScreenCover(isPresented: $showGuidedJournal) {
            MorningFlowView(
                isPresented: $showGuidedJournal,
                streakManager: streakManager,
                userName: auth.displayName,
                onDevotionFinished: handleDevotionFinished,
                onOpenChaplainChat: { transcript in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        openChaplainChatIfAllowed(
                            starter: VoiceChatHandoff.starter(from: transcript, context: "my morning devotion"),
                            seedMessages: VoiceChatHandoff.seedMessages(for: transcript)
                        )
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showStreakBorn) {
            StreakBornView {
                showStreakBorn = false
            }
        }
        .fullScreenCover(item: $pendingCelebration) { result in
            StreakCelebrationView(
                result: result,
                weekFlags: streakManager.weekCompletionFlags
            ) {
                pendingCelebration = nil
            }
        }
        .fullScreenCover(isPresented: $showMorningWrapped) {
            MorningWrappedContainerView(baseStats: streakManager.wrappedStats()) {
                showMorningWrapped = false
            }
        }
        .sheet(isPresented: $showStreakScreen) {
            StreakScreenView(streakManager: streakManager)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .sheet(item: $selectedConversation) { conversation in
            ConversationDetailView(conversation: conversation)
        }
        .environment(\.openConversation) { selectedConversation = $0 }
        .environment(\.openVoiceSession, openVoiceIfAllowed)
        .environment(\.openChaplainChat, openChaplainChatIfAllowed)
        .environment(\.openGuidedJournal, openGuidedJournalIfAllowed)
        .environment(\.openStreakScreen) {
            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                showStreakScreen = true
            }
        }
        .environment(\.openMorningWrapped) {
            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                showMorningWrapped = true
            }
        }
        .environment(\.openPrayerWall) { kind in
            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                prayerWallAddKind = kind
                showPrayerWall = true
            }
        }
        .environment(\.openJourneyTimeline) {
            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                showJourneyTimeline = true
            }
        }
        .environment(\.streakManager, streakManager)
        .handleDevotionDeepLinks { route in
            handleDeepLink(route)
        }
        .sheet(isPresented: $showPrayerWall) {
            PrayerWallView(
                store: PrayerWallStore.shared,
                onReflect: { prompt in
                    showPrayerWall = false
                    selectedTab = .insights
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        openChaplainChatIfAllowed(starter: prompt, seedMessages: [])
                    }
                },
                initialAddKind: prayerWallAddKind,
                initialTab: prayerWallInitialTab,
                initialJoinCode: prayerWallJoinCode
            )
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground {
                ABYCleanGradientBackground()
            }
            .onDisappear {
                prayerWallAddKind = nil
                prayerWallInitialTab = .myWall
                prayerWallJoinCode = nil
            }
        }
        .fullScreenCover(isPresented: $showWidgetOnboarding) {
            WidgetOnboardingView {
                showWidgetOnboarding = false
                selectedTab = .profile
            }
        }
        .fullScreenCover(isPresented: $showJourneyTimeline) {
            NavigationStack {
                JourneyTimelineView(store: JourneyTimelineStore.shared)
            }
        }
    }

    private func handleDeepLink(_ route: DeepLinkRouter.DeepLinkRoute) {
        switch route {
        case .home:
            selectedTab = .home
        case .journal:
            openGuidedJournalIfAllowed()
        case .chaplain(let prompt):
            selectedTab = .insights
            openChaplainChatIfAllowed(starter: prompt, seedMessages: [])
        case .prayerWall(let kind, let openCircles, let joinCode):
            selectedTab = .insights
            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                prayerWallAddKind = kind.flatMap(PrayerNoteKind.init(rawValue:))
                prayerWallInitialTab = openCircles ? .circles : .myWall
                prayerWallJoinCode = joinCode
                showPrayerWall = true
            }
        case .streak:
            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                showStreakScreen = true
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .conversations:
            ConversationsListView()
        case .insights:
            AIInsightsView()
        case .profile:
            ProfileView()
        }
    }

    private var selectedChaplainVoice: ChaplainVoice {
        let id = UserDefaults.standard.string(forKey: "selectedChaplainVoice") ?? "grace"
        return ChaplainVoice.options.first { $0.id == id } ?? ChaplainVoice.options[0]
    }

    private func handleDevotionFinished(_ result: DevotionFinishResult) {
        if result.isFirstCompletionEver {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showStreakBorn = true
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                pendingCelebration = result
            }
            if result.streak >= 2,
               !UserDefaults.standard.bool(forKey: "hasSeenWidgetOnboarding") {
                UserDefaults.standard.set(true, forKey: "hasSeenWidgetOnboarding")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showWidgetOnboarding = true
                }
            }
        }
    }

    private func openVoiceIfAllowed(prompt: String? = nil) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
            voiceStarterPrompt = prompt
            withAnimation(AppTheme.springGentle) { showVoiceSession = true }
        }
    }

    private func openChaplainChatIfAllowed(
        starter: String?,
        seedMessages: [ChaplainMessage]
    ) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
            chaplainChatSessionID = UUID()
            chatStarterText = starter ?? ""
            chatSeedMessages = seedMessages
            resumeConversationID = ChaplainSessionStore.shared.consumePendingResumeID()
            chatContextIntent = starter?.localizedCaseInsensitiveContains("expand this reflection") == true
                ? "expand_reflection"
                : nil
            withAnimation(AppTheme.springGentle) { showChaplainChat = true }
        }
    }

    private func openGuidedJournalIfAllowed() {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
            withAnimation(AppTheme.springGentle) { showGuidedJournal = true }
        }
    }
}

private struct OpenConversationKey: EnvironmentKey {
    static let defaultValue: (Conversation) -> Void = { _ in }
}

private struct OpenChaplainChatKey: EnvironmentKey {
    static let defaultValue: (String?, [ChaplainMessage]) -> Void = { _, _ in }
}

private struct OpenVoiceSessionKey: EnvironmentKey {
    static let defaultValue: (String?) -> Void = { _ in }
}

private struct OpenGuidedJournalKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenStreakScreenKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenMorningWrappedKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenPrayerWallKey: EnvironmentKey {
    static let defaultValue: (PrayerNoteKind?) -> Void = { _ in }
}

private struct OpenJourneyTimelineKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct StreakManagerKey: EnvironmentKey {
    static let defaultValue = StreakManager.shared
}

extension EnvironmentValues {
    var openConversation: (Conversation) -> Void {
        get { self[OpenConversationKey.self] }
        set { self[OpenConversationKey.self] = newValue }
    }
    var openChaplainChat: (String?, [ChaplainMessage]) -> Void {
        get { self[OpenChaplainChatKey.self] }
        set { self[OpenChaplainChatKey.self] = newValue }
    }
    var openVoiceSession: (String?) -> Void {
        get { self[OpenVoiceSessionKey.self] }
        set { self[OpenVoiceSessionKey.self] = newValue }
    }
    var openGuidedJournal: () -> Void {
        get { self[OpenGuidedJournalKey.self] }
        set { self[OpenGuidedJournalKey.self] = newValue }
    }
    var openStreakScreen: () -> Void {
        get { self[OpenStreakScreenKey.self] }
        set { self[OpenStreakScreenKey.self] = newValue }
    }
    var openMorningWrapped: () -> Void {
        get { self[OpenMorningWrappedKey.self] }
        set { self[OpenMorningWrappedKey.self] = newValue }
    }
    var openPrayerWall: (PrayerNoteKind?) -> Void {
        get { self[OpenPrayerWallKey.self] }
        set { self[OpenPrayerWallKey.self] = newValue }
    }
    var openJourneyTimeline: () -> Void {
        get { self[OpenJourneyTimelineKey.self] }
        set { self[OpenJourneyTimelineKey.self] = newValue }
    }
    var streakManager: StreakManager {
        get { self[StreakManagerKey.self] }
        set { self[StreakManagerKey.self] = newValue }
    }
}

#Preview {
    MainTabView()
}
