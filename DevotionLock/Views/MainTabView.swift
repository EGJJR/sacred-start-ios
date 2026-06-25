//
//  MainTabView.swift
//  DevotionLock
//
//  Tab shell + item-driven modal presentations.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @Environment(\.authManager) private var auth

    @State private var coordinator = MainTabCoordinator()
    private let streakManager = StreakManager.shared
    private let rhythmStore = DailyRhythmStore.shared
    private let journalStore = JournalLocalStore.shared

    private var sacredOrbState: SacredOrbState {
        coordinator.sacredOrbState(rhythmStore: rhythmStore, streakManager: streakManager)
    }

    private var sacredOrbRefreshKey: String {
        "\(rhythmStore.revision)-\(journalStore.entries.count)-\(streakManager.isCompletedToday)"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            MainTabShellBackground(selectedTab: coordinator.selectedTab)

            tabShell
                .animation(AppTheme.springSnappy, value: coordinator.selectedTab)

            BottomNavigationBar(
                selectedTab: $coordinator.selectedTab,
                orbState: sacredOrbState,
                onOrbTap: performSacredOrbTap,
                onOrbLongPress: performSacredOrbLongPress
            )
            .id(sacredOrbRefreshKey)
        }
        .abyScreen()
        .installMainTabEnvironment(coordinator: coordinator, streakManager: streakManager)
        .modifier(MainTabVoiceSessionModifier(coordinator: coordinator, onSwitchToChat: { transcript in
            coordinator.closeVoiceSession()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                openChaplainChatIfAllowed(
                    starter: VoiceChatHandoff.starter(from: transcript),
                    seedMessages: VoiceChatHandoff.seedMessages(for: transcript)
                )
            }
        }))
        .mainTabPresentations(coordinator: coordinator, streakManager: streakManager, auth: auth)
        .overlay {
            if let portal = coordinator.chaplainPortal {
                ChaplainPortalTransition(voiceName: portal.voiceName) {
                    coordinator.completeChaplainPortalTransition()
                }
                .transition(.opacity)
                .zIndex(200)
            }
        }
        .animation(AppTheme.springGentle, value: coordinator.chaplainPortal != nil)
        .handleDevotionDeepLinks { route in
            handleDeepLink(route)
        }
    }

    @ViewBuilder
    private var tabShell: some View {
        ZStack {
            tabLayer(.home) { HomeView().abyTabShell() }
            tabLayer(.conversations) { ConversationsListView().abyTabShell() }
            tabLayer(.insights) { AIInsightsView().abyTabShell() }
            tabLayer(.profile) { ProfileView().abyTabShell() }
        }
    }

    @ViewBuilder
    private func tabLayer<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(coordinator.selectedTab == tab ? 1 : 0)
            .allowsHitTesting(coordinator.selectedTab == tab)
            .accessibilityHidden(coordinator.selectedTab != tab)
    }

    private var selectedChaplainVoice: ChaplainVoice {
        let id = UserDefaults.standard.string(forKey: "selectedChaplainVoice") ?? "grace"
        return ChaplainVoice.options.first { $0.id == id } ?? ChaplainVoice.options[0]
    }

    private func handleDeepLink(_ route: DeepLinkRouter.DeepLinkRoute) {
        switch route {
        case .home:
            coordinator.selectedTab = .home
        case .journal:
            openGuidedJournalIfAllowed()
        case .chaplain(let prompt):
            coordinator.selectedTab = .insights
            openChaplainChatIfAllowed(starter: prompt, seedMessages: [])
        case .prayerWall(let kind, let openCircles, let joinCode):
            coordinator.selectedTab = .insights
            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                coordinator.openPrayerWall(
                    addKind: kind.flatMap(PrayerNoteKind.init(rawValue:)),
                    initialTab: openCircles ? .circles : .myWall,
                    joinCode: joinCode
                )
            }
        case .streak:
            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                coordinator.openStreakScreen()
            }
        }
    }

    private func openVoiceIfAllowed(prompt: String? = nil) {
        guard FeatureFlags.voiceChatEnabled else { return }
        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
            withAnimation(AppTheme.springGentle) {
                coordinator.openVoiceSession(prompt: prompt)
            }
        }
    }

    private func openChaplainChatIfAllowed(starter: String?, seedMessages: [ChaplainMessage]) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
            withAnimation(AppTheme.springGentle) {
                coordinator.openChaplainChat(starter: starter, seedMessages: seedMessages)
            }
        }
    }

    private func resumeChaplainChatIfAllowed(_ conversation: Conversation) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
            withAnimation(AppTheme.springGentle) {
                coordinator.resumeChaplainChat(conversation)
            }
        }
    }

    private func openGuidedJournalIfAllowed() {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
            withAnimation(AppTheme.springGentle) {
                coordinator.openGuidedJournal()
            }
        }
    }

    private func performSacredOrbTap() {
        let state = sacredOrbState
        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
            withAnimation(AppTheme.springGentle) {
                coordinator.performSacredOrbAction(state)
            }
        }
    }

    private func performSacredOrbLongPress() {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
            withAnimation(AppTheme.springGentle) {
                coordinator.presentSacredOrbQuickMenu(
                    rhythmStore: rhythmStore,
                    streakManager: streakManager
                )
            }
        }
    }
}

// MARK: - Tab shell background

/// Flat wash on browse tabs; full sanctuary gradient on Journal (Mobbin ABY / Alan Mind pattern).
private struct MainTabShellBackground: View {
    let selectedTab: AppTab

    private var usesImmersiveGradient: Bool {
        selectedTab == .conversations
    }

    var body: some View {
        ZStack {
            ABYFlatTabWashBackground()
            if usesImmersiveGradient {
                ABYCleanGradientBackground()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: selectedTab)
    }
}

// MARK: - Environment wiring

private extension View {
    func installMainTabEnvironment(
        coordinator: MainTabCoordinator,
        streakManager: StreakManager
    ) -> some View {
        environment(\.openConversation, coordinator.openConversation)
            .environment(\.streakManager, streakManager)
            .modifier(MainTabActionEnvironmentModifier(coordinator: coordinator))
    }

    /// Sheets/full-screen covers are hosted outside the tab tree — re-apply shell environment.
    func mainTabModalEnvironment(coordinator: MainTabCoordinator) -> some View {
        abyScreen()
            .modifier(MainTabActionEnvironmentModifier(coordinator: coordinator))
    }
}

private struct MainTabActionEnvironmentModifier: ViewModifier {
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    let coordinator: MainTabCoordinator

    func body(content: Content) -> some View {
        content
            .environment(\.openChaplainChat) { starter, seeds in
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    withAnimation(AppTheme.springGentle) {
                        coordinator.openChaplainChat(starter: starter, seedMessages: seeds)
                    }
                }
            }
            .environment(\.openChaplainChatWithPortal) { voiceName, starter, seeds in
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    coordinator.openChaplainChatWithPortal(
                        voiceName: voiceName,
                        starter: starter,
                        seedMessages: seeds
                    )
                }
            }
            .environment(\.resumeChaplainChat) { conversation in
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    withAnimation(AppTheme.springGentle) {
                        coordinator.resumeChaplainChat(conversation)
                    }
                }
            }
            .environment(\.openGuidedJournal) {
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    withAnimation(AppTheme.springGentle) {
                        coordinator.openGuidedJournal()
                    }
                }
            }
            .environment(\.openJournalEntryHub) {
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    coordinator.openJournalEntryHub()
                }
            }
            .environment(\.openAssistedJournal) { prompt in
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    withAnimation(AppTheme.springGentle) {
                        coordinator.openAssistedJournal(prompt: prompt)
                    }
                }
            }
            .environment(\.openVoiceJournal) {
                guard FeatureFlags.voiceChatEnabled else { return }
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    withAnimation(AppTheme.springGentle) {
                        coordinator.openVoiceJournal()
                    }
                }
            }
            .environment(\.openStreakScreen) {
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    coordinator.openStreakScreen()
                }
            }
            .environment(\.openMorningWrapped) {
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    coordinator.openMorningWrapped()
                }
            }
            .environment(\.openPrayerWall) { kind in
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    coordinator.openPrayerWall(addKind: kind)
                }
            }
            .environment(\.openDailyVerse) {
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    coordinator.openDailyVerse()
                }
            }
            .environment(\.openEveningReflection) {
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    coordinator.openEveningReflection()
                }
            }
            .environment(\.openJourneyTimeline) {
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    coordinator.openJourneyTimeline()
                }
            }
            .environment(\.selectTab) { tab in
                withAnimation(AppTheme.springSnappy) {
                    coordinator.selectedTab = tab
                }
            }
            .environment(\.openVoiceSession) { prompt in
                guard FeatureFlags.voiceChatEnabled else { return }
                PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                    withAnimation(AppTheme.springGentle) {
                        coordinator.openVoiceSession(prompt: prompt)
                    }
                }
            }
    }
}

// MARK: - Presentations

private struct MainTabPresentationsModifier: ViewModifier {
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    let coordinator: MainTabCoordinator
    let streakManager: StreakManager
    let auth: AuthManager

    func body(content: Content) -> some View {
        content
            .sheet(item: Bindable(coordinator).sheet) { presentation in
                sheetContent(for: presentation)
            }
            .fullScreenCover(item: Bindable(coordinator).fullScreen) { presentation in
                fullScreenContent(for: presentation)
            }
    }

    @ViewBuilder
    private func sheetContent(for presentation: MainSheetPresentation) -> some View {
        Group {
            switch presentation {
            case .streakScreen:
                StreakScreenView(streakManager: streakManager)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            case .conversation(let conversation):
                ConversationDetailView(conversation: conversation)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            case .prayerWall(let launch):
                PrayerWallView(
                    store: PrayerWallStore.shared,
                    onReflect: { prompt in
                        coordinator.sheet = nil
                        coordinator.selectedTab = .insights
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(350))
                            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                                coordinator.openChaplainChat(starter: prompt, seedMessages: [])
                            }
                        }
                    },
                    initialAddKind: launch.addKind,
                    initialTab: launch.initialTab,
                    initialJoinCode: launch.joinCode
                )
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground {
                    ABYCleanGradientBackground()
                }
            case .journalEntryHub:
                JournalEntryHubSheet(
                    onAssisted: {
                        coordinator.sheet = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(350))
                            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                                coordinator.openAssistedJournal()
                            }
                        }
                    },
                    onVoice: {
                        guard FeatureFlags.voiceChatEnabled else { return }
                        coordinator.sheet = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(350))
                            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                                coordinator.openVoiceJournal()
                            }
                        }
                    }
                )
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            case .dailyVerse:
                let passage = SpiritualPassageCatalog.todayScripture
                DailyVerseSheet(
                    passage: passage,
                    onReflect: {
                        coordinator.sheet = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(350))
                            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                                coordinator.openChaplainChat(
                                    starter: "Help me reflect on today's passage: \"\(passage.text)\" — \(passage.attribution)",
                                    seedMessages: []
                                )
                            }
                        }
                    },
                    onComplete: {
                        DailyRhythmStore.shared.markComplete(.dailyVerse)
                        JourneyTimelineStore.shared.logVerseViewed(
                            reference: passage.reference,
                            text: passage.text
                        )
                    }
                )
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground {
                    ABYCleanGradientBackground()
                }
            case .eveningReflection:
                EveningReflectionSheet(
                    onComplete: { highlight in
                        DailyRhythmStore.shared.markComplete(.eveningReflection)
                        JourneyTimelineStore.shared.logEvening(highlight: highlight)
                        coordinator.sheet = nil
                    },
                    onVoiceHandoff: { transcript in
                        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                        let saved = text.isEmpty ? "Quiet gratitude for today." : text
                        DailyRhythmStore.shared.markComplete(.eveningReflection)
                        JourneyTimelineStore.shared.logEvening(highlight: saved)
                        coordinator.sheet = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(400))
                            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                                coordinator.openChaplainChat(
                                    starter: VoiceChatHandoff.starter(from: saved, context: "my evening reflection"),
                                    seedMessages: VoiceChatHandoff.seedMessages(for: saved)
                                )
                            }
                        }
                    }
                )
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground {
                    ABYCleanGradientBackground()
                }
            case .sacredOrbMenu:
                SacredOrbQuickActionsSheet(
                    actions: coordinator.sacredOrbMenuActions,
                    onSelect: { action in
                        PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                            coordinator.performSacredOrbQuickAction(action)
                        }
                    }
                )
            }
        }
        .mainTabModalEnvironment(coordinator: coordinator)
    }

    @ViewBuilder
    private func fullScreenContent(for presentation: MainFullScreenPresentation) -> some View {
        Group {
            switch presentation {
            case .chaplain(let launch):
                ChaplainChatView(
                    voice: selectedChaplainVoice,
                    seedMessages: launch.seedMessages,
                    starterText: launch.starterText,
                    contextIntent: launch.contextIntent,
                    resumeConversationID: launch.resumeConversationID,
                    resumedContext: launch.resumedContext,
                    onVoice: FeatureFlags.voiceChatEnabled ? {
                        coordinator.fullScreen = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(350))
                            guard FeatureFlags.voiceChatEnabled else { return }
                            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                                coordinator.openVoiceSession(prompt: nil)
                            }
                        }
                    } : nil,
                    playsPortalEntrance: launch.playsPortalEntrance
                )
                .id(launch.sessionID)
            case .guidedJournal:
                MorningFlowView(
                    streakManager: streakManager,
                    userName: auth.displayName,
                    onDevotionFinished: { coordinator.handleDevotionFinished($0) },
                    onOpenChaplainChat: { transcript in
                        coordinator.fullScreen = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(350))
                            PaywallAccess.guardPremium(presentPaywall: presentPaywall) {
                                coordinator.openChaplainChat(
                                    starter: VoiceChatHandoff.starter(from: transcript, context: "my morning devotion"),
                                    seedMessages: VoiceChatHandoff.seedMessages(for: transcript)
                                )
                            }
                        }
                    }
                )
            case .assistedJournal:
                AssistedJournalView(initialPrompt: coordinator.assistedJournalPrompt)
                    .onDisappear {
                        coordinator.assistedJournalPrompt = nil
                    }
            case .voiceJournal:
                VoiceJournalView()
            case .streakBorn:
                StreakBornView {
                    coordinator.fullScreen = nil
                }
            case .morningWrapped:
                MorningWrappedContainerView(baseStats: streakManager.wrappedStats()) {
                    coordinator.fullScreen = nil
                }
            case .widgetOnboarding:
                WidgetOnboardingView {
                    coordinator.fullScreen = nil
                    coordinator.selectedTab = .profile
                }
            case .journeyTimeline:
                NavigationStack {
                    JourneyTimelineView(store: JourneyTimelineStore.shared)
                }
            case .celebration(let result):
                StreakCelebrationView(
                    result: result,
                    weekFlags: streakManager.weekCompletionFlags
                ) {
                    coordinator.handleCelebrationDismissed(result: result, streakManager: streakManager)
                }
            case .milestone(let presentation):
                StreakMilestoneCelebrationView(
                    milestoneDays: presentation.days,
                    identity: StreakIdentity.identity(for: presentation.days)
                ) {
                    streakManager.markMilestoneSeen(presentation.days)
                    coordinator.fullScreen = nil
                }
            }
        }
        .mainTabModalEnvironment(coordinator: coordinator)
    }

    private var selectedChaplainVoice: ChaplainVoice {
        let id = UserDefaults.standard.string(forKey: "selectedChaplainVoice") ?? "grace"
        return ChaplainVoice.options.first { $0.id == id } ?? ChaplainVoice.options[0]
    }
}

private extension View {
    func mainTabPresentations(
        coordinator: MainTabCoordinator,
        streakManager: StreakManager,
        auth: AuthManager
    ) -> some View {
        modifier(MainTabPresentationsModifier(
            coordinator: coordinator,
            streakManager: streakManager,
            auth: auth
        ))
    }
}

// MARK: - Voice session

private struct MainTabVoiceSessionModifier: ViewModifier {
    let coordinator: MainTabCoordinator
    let onSwitchToChat: (String) -> Void

    func body(content: Content) -> some View {
        if FeatureFlags.voiceChatEnabled {
            content
                .fullScreenCover(isPresented: Bindable(coordinator).isVoiceSessionPresented) {
                    RecordingSessionView(
                        isPresented: Bindable(coordinator).isVoiceSessionPresented,
                        initialPrompt: coordinator.voiceSessionPrompt,
                        onComplete: { _ in coordinator.closeVoiceSession() },
                        onSwitchToChat: onSwitchToChat,
                        voiceTranscript: coordinator.voiceTranscriptHandoff,
                        saveOnlyLabel: "Close without chat"
                    )
                    .presentationBackground {
                        ABYCleanGradientBackground()
                    }
                }
        } else {
            content
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.authManager, .shared)
}
