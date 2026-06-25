//
//  DesignTourView.swift
//  DevotionLock
//
//  DEBUG-only screen picker for design QA vs Mobbin references.
//  Enable: Profile → Developer → Design tour, or launch with -design-tour
//

#if DEBUG
import InAppKit
import SwiftUI

struct DesignTourTimelineSamplesKey: EnvironmentKey {
    static let defaultValue: [Conversation]? = nil
}

extension EnvironmentValues {
    var designTourTimelineSamples: [Conversation]? {
        get { self[DesignTourTimelineSamplesKey.self] }
        set { self[DesignTourTimelineSamplesKey.self] = newValue }
    }
}

enum DesignTour {
    static let storageKey = "debugDesignTourEnabled"
    static let launchArgument = "-design-tour"
    static let auditArgument = "-design-tour-audit"

    static var launchArgumentEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
            || ProcessInfo.processInfo.arguments.contains(auditArgument)
    }

    static var auditModeEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(auditArgument)
    }

    static var isActive: Bool {
        launchArgumentEnabled || UserDefaults.standard.bool(forKey: storageKey)
    }

    static func activateFromLaunchArgumentIfNeeded() {
        if launchArgumentEnabled {
            UserDefaults.standard.set(true, forKey: storageKey)
        }
    }

    /// Written to Documents for `scripts/capture-design-tour.sh` to poll.
    static let auditReadyFilename = "design-tour-ready.txt"

    static func markAuditScreenReady(_ destination: DesignTourDestination) {
        guard auditModeEnabled,
              let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(auditReadyFilename)
        else { return }
        try? destination.rawValue.write(to: url, atomically: true, encoding: .utf8)
    }

    static func clearAuditScreenReady() {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(auditReadyFilename)
        else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

enum DesignTourDestination: String, Identifiable, CaseIterable {
    case authWelcome
    case authSignUp
    case authSignIn
    case onboardingEntry
    case onboardingGoal
    case onboardingIntention
    case onboardingVoice
    case onboardingNotifications
    case onboardingRecap
    case home
    case conversations
    case insights
    case profile
    case journalMood
    case journalMadLibs
    case journalComplete
    case paywall
    case devotionComplete
    case splash
    case streak
    case prayerThreshold
    case prayerLiturgyWeave
    case prayerLiturgyWeaving
    case sacredOrbWeavingLab
    case morningLiturgyBranch
    case weekInReview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .authWelcome: "Auth · Welcome"
        case .authSignUp: "Auth · Sign up"
        case .authSignIn: "Auth · Sign in"
        case .onboardingEntry: "Onboarding · Entry"
        case .onboardingGoal: "Onboarding · Goal"
        case .onboardingIntention: "Onboarding · Mood"
        case .onboardingVoice: "Onboarding · Chaplain"
        case .onboardingNotifications: "Onboarding · Reminders"
        case .onboardingRecap: "Onboarding · Recap"
        case .home: "Main · Home"
        case .conversations: "Main · Journal list"
        case .insights: "Main · Chaplain"
        case .profile: "Main · Profile"
        case .journalMood: "Journal · Mood"
        case .journalMadLibs: "Journal · Mad-libs"
        case .journalComplete: "Journal · Complete"
        case .paywall: "Paywall"
        case .devotionComplete: "Devotion complete"
        case .splash: "Splash / loading"
        case .streak: "Streak sheet"
        case .prayerThreshold: "Prayer · Threshold Chapel"
        case .prayerLiturgyWeave: "Prayer · Liturgy Weave"
        case .prayerLiturgyWeaving: "Prayer · Weaving overlay"
        case .sacredOrbWeavingLab: "Sacred orb · Weaving lab"
        case .morningLiturgyBranch: "Morning · Liturgy branch"
        case .weekInReview: "Week in review"
        }
    }

    var section: String {
        switch self {
        case .authWelcome, .authSignUp, .authSignIn: "Auth"
        case .onboardingEntry, .onboardingGoal, .onboardingIntention, .onboardingVoice, .onboardingNotifications, .onboardingRecap: "Onboarding"
        case .home, .conversations, .insights, .profile: "Main tabs"
        case .journalMood, .journalMadLibs, .journalComplete: "Guided journal"
        case .paywall, .devotionComplete, .splash, .streak, .weekInReview: "Other flows"
        case .prayerThreshold, .prayerLiturgyWeave, .prayerLiturgyWeaving, .sacredOrbWeavingLab, .morningLiturgyBranch: "Guided prayer prototypes"
        }
    }

    static var grouped: [(String, [DesignTourDestination])] {
        let order = ["Auth", "Onboarding", "Main tabs", "Guided journal", "Guided prayer prototypes", "Other flows"]
        return order.map { section in
            (section, allCases.filter { $0.section == section })
        }
    }
}

struct DesignTourView: View {
    @AppStorage(DesignTour.storageKey) private var designTourEnabled = true
    @State private var destination: DesignTourDestination?
    @State private var auditTask: Task<Void, Never>?

    private var isAuditing: Bool { DesignTour.auditModeEnabled }

    var body: some View {
        Group {
            if isAuditing {
                auditRoot
            } else {
                tourMenu
            }
        }
        .fullScreenCover(item: $destination) { item in
            DesignTourScreen(destination: item)
                .accessibilityIdentifier("design-tour-\(item.rawValue)")
        }
        .onAppear {
            DesignTour.activateFromLaunchArgumentIfNeeded()
            if isAuditing { startAudit() }
        }
        .onDisappear {
            auditTask?.cancel()
        }
    }

    @ViewBuilder
    private var auditRoot: some View {
        if let destination {
            DesignTourScreen(destination: destination)
                .accessibilityIdentifier("design-tour-\(destination.rawValue)")
                .id(destination)
        } else {
            Color.clear
        }
    }

    private var tourMenu: some View {
        NavigationStack {
            List {
                ForEach(DesignTourDestination.grouped, id: \.0) { section, items in
                    Section(section) {
                        ForEach(items) { item in
                            Button(item.title) {
                                destination = item
                            }
                            .foregroundStyle(ABY.Color.textPrimary)
                        }
                    }
                }

                Section {
                    Button("Exit design tour") {
                        designTourEnabled = false
                    }
                    .foregroundStyle(.red)
                } footer: {
                    Text("Launch with \(DesignTour.launchArgument) to open this menu automatically. Screenshots: xcrun simctl io booted screenshot tour.png")
                        .font(ABY.Font.caption)
                }
            }
            .navigationTitle("Design Tour")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func startAudit() {
        auditTask?.cancel()
        auditTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1200))
            for item in DesignTourDestination.allCases {
                guard !Task.isCancelled else { return }
                destination = item
                try? await Task.sleep(for: .seconds(3.2))
            }
            destination = nil
            DesignTour.clearAuditScreenReady()
        }
    }
}

private struct DesignTourScreen: View {
    let destination: DesignTourDestination
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            screenContent

            if !DesignTour.auditModeEnabled {
                tourChrome
            }
        }
        .accessibilityIdentifier("design-tour-screen-\(destination.rawValue)")
        .onAppear {
            DesignTour.markAuditScreenReady(destination)
        }
    }

    private var tourChrome: some View {
        HStack(spacing: 8) {
            Text(destination.title)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(ABY.Color.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())

            Spacer()

            Button("Close") { dismiss() }
                .font(ABY.Font.captionMedium)
                .foregroundStyle(ABY.Color.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var screenContent: some View {
        switch destination {
        case .authWelcome:
            AuthWelcomeView(onContinue: {}, onSignIn: {})

        case .authSignUp:
            AuthSocialView(intent: .signUp, onBack: {})

        case .authSignIn:
            AuthSocialView(intent: .signIn, onBack: {})

        case .onboardingEntry:
            onboarding(.entry)

        case .onboardingGoal:
            onboarding(.goal)

        case .onboardingIntention:
            onboarding(.intention)

        case .onboardingVoice:
            onboarding(.voice)

        case .onboardingNotifications:
            onboarding(.notifications)

        case .onboardingRecap:
            onboarding(.recap)

        case .home:
            HomeView().designTourTabShell(tab: .home)

        case .conversations:
            ConversationsListView()
                .environment(\.designTourTimelineSamples, Conversation.designTourSamples)
                .designTourTabShell(tab: .conversations)

        case .insights:
            AIInsightsView().designTourTabShell(tab: .insights)

        case .profile:
            ProfileView().designTourTabShell(tab: .profile)

        case .journalMood:
            journalTour(step: .mood)

        case .journalMadLibs:
            journalTour(step: .madLibs)

        case .journalComplete:
            journalTour(step: .complete)

        case .paywall:
            DevotionPaywallView(
                context: PaywallContext(triggeredBy: "design-tour", availableProducts: []),
                onDismiss: {}
            )

        case .devotionComplete:
            ZStack {
                ABYBackground()
                DevotionCompletionView(
                    streak: 6,
                    mood: "Peaceful",
                    insight: "Today you named feeling peaceful because work is heavy. Showing up with honesty is already a sacred start.",
                    onContinue: {}
                )
            }
            .abyScreen()

        case .splash:
            AppLoadingView(progress: .constant(0.65), isBrief: false)
                .ignoresSafeArea()

        case .streak:
            StreakScreenView(streakManager: .shared)

        case .prayerThreshold:
            GuidedPrayerFlowView(
                prayer: GuidedPrayerCatalog.all[0],
                style: .threshold
            ) {}

        case .prayerLiturgyWeave:
            GuidedPrayerFlowView(
                prayer: GuidedPrayerCatalog.all[0],
                style: .liturgyWeave,
                weaveContext: .preview
            ) {}

        case .prayerLiturgyWeaving:
            LiturgyWeavePrayerView(
                beats: LiturgyWeaveBuilder.wovenBeats(
                    prayer: GuidedPrayerCatalog.all[0],
                    context: .preview
                ),
                isEnriching: true,
                onComplete: {}
            )

        case .sacredOrbWeavingLab:
            DesignTourSacredOrbWeavingLab()

        case .morningLiturgyBranch:
            ThresholdPrayerFlowView(
                prayer: GuidedPrayerCatalog.all[0],
                prayerBeats: LiturgyWeaveBuilder.repeatablePrayerBeats(
                    prayer: GuidedPrayerCatalog.all[0],
                    context: .preview
                ),
                onComplete: {}
            )

        case .weekInReview:
            MorningWrappedView(
                stats: StreakManager.shared.wrappedStats(),
                onDismiss: {}
            )
        }
    }

    private func onboarding(_ step: OnboardingStep) -> some View {
        OnboardingFlowView(initialStep: step, onComplete: {})
    }

    private func journalTour(step: GuidedJournalStep) -> some View {
        DesignTourJournalHost(initialStep: step)
    }
}

private struct DesignTourJournalHost: View {
    let initialStep: GuidedJournalStep
    @Environment(\.dismiss) private var dismiss
    @State private var isPresented = true

    var body: some View {
        GuidedJournalFlowView(
            isPresented: $isPresented,
            streakManager: .shared,
            userName: "Alex",
            initialStep: initialStep
        )
        .onChange(of: isPresented) { _, shown in
            if !shown { dismiss() }
        }
    }
}

private struct DesignTourMorningHost: View {
    let path: MorningPath
    let step: MorningStep

    var body: some View {
        MorningFlowView(
            streakManager: .shared,
            userName: "Alex",
            initialMorningPath: path,
            initialStep: step
        )
    }
}

private struct DesignTourTabShell: ViewModifier {
    let tab: AppTab
    @State private var tourCoordinator = MainTabCoordinator()

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            ABYBackground()
            content
                .padding(.bottom, 88)
            BottomNavigationBar(
                selectedTab: .constant(tab),
                orbState: SacredOrbState(
                    shortLabel: "Begin",
                    microLabel: "Begin",
                    accessibilityLabel: "Begin devotion",
                    visualStyle: .pulse,
                    destination: .guidedDevotion,
                    showsMorningFirstNudge: false,
                    rhythmProgress: 0.25
                ),
                onOrbTap: {}
            )
        }
        .designTourTabEnvironment(openJournalEntryHub: { tourCoordinator.openJournalEntryHub() })
        .sheet(item: Bindable(tourCoordinator).sheet) { presentation in
            designTourSheet(for: presentation)
                .designTourModalEnvironment()
        }
        .fullScreenCover(item: Bindable(tourCoordinator).fullScreen) { presentation in
            designTourFullScreen(for: presentation)
                .designTourModalEnvironment()
        }
    }

    @ViewBuilder
    private func designTourSheet(for presentation: MainSheetPresentation) -> some View {
        switch presentation {
        case .journalEntryHub:
            JournalEntryHubSheet(
                onAssisted: {
                    tourCoordinator.sheet = nil
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        tourCoordinator.openAssistedJournal()
                    }
                },
                onVoice: {
                    guard FeatureFlags.voiceChatEnabled else { return }
                    tourCoordinator.sheet = nil
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        tourCoordinator.openVoiceJournal()
                    }
                }
            )
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        case .eveningReflection:
            EveningReflectionSheet(onComplete: { _ in tourCoordinator.sheet = nil })
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func designTourFullScreen(for presentation: MainFullScreenPresentation) -> some View {
        switch presentation {
        case .assistedJournal:
            AssistedJournalView()
        case .voiceJournal:
            VoiceJournalView()
        default:
            EmptyView()
        }
    }
}

private extension View {
    func designTourTabShell(tab: AppTab) -> some View {
        modifier(DesignTourTabShell(tab: tab))
    }

    func designTourTabEnvironment(openJournalEntryHub: @escaping () -> Void = {}) -> some View {
        environment(\.streakManager, .shared)
            .environment(\.openConversation, { _ in })
            .environment(\.openChaplainChat, { _, _ in })
            .environment(\.resumeChaplainChat, { _ in })
            .environment(\.openVoiceSession, { _ in })
            .environment(\.openGuidedJournal, {})
            .environment(\.openJournalEntryHub, openJournalEntryHub)
            .environment(\.openStreakScreen, {})
            .environment(\.openMorningWrapped, {})
            .environment(\.openPrayerWall, { _ in })
            .environment(\.openJourneyTimeline, {})
            .environment(\.presentDevotionPaywall, {})
            .abyScreen()
    }

    func designTourModalEnvironment() -> some View {
        environment(\.streakManager, .shared)
            .environment(\.openConversation, { _ in })
            .environment(\.openChaplainChat, { _, _ in })
            .environment(\.resumeChaplainChat, { _ in })
            .environment(\.openVoiceSession, { _ in })
            .environment(\.openGuidedJournal, {})
            .environment(\.openStreakScreen, {})
            .environment(\.openMorningWrapped, {})
            .environment(\.openPrayerWall, { _ in })
            .environment(\.openJourneyTimeline, {})
            .environment(\.presentDevotionPaywall, {})
            .abyScreen()
    }
}

private struct DesignTourSacredOrbWeavingLab: View {
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                Text("Compare loading affordances — spinner vs shared sacred shell.")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(3)

                labSection(title: "Legacy spinner") {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Tidying gently…")
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                labSection(title: "Mini orb · speech polish") {
                    ABYSpeechTidyPresence(phase: .smoothing)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                labSection(title: "Nav shell · 52pt weaving") {
                    SacredOrbShell(size: 52, visualStyle: .weaving, rhythmProgress: 0.35)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                labSection(title: "Guided prayer · center overlay") {
                    ZStack {
                        Color.black.opacity(0.88)
                        SacredOrbWeavingOverlay(shellSize: 68)
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                labSection(title: "In-card polish mock") {
                    ZStack(alignment: .bottom) {
                        Text("Lord today I felt anxious about work and I don't know how to slow down…")
                            .font(ABY.Font.body)
                            .foregroundStyle(palette.textPrimary)
                            .lineSpacing(6)
                            .blur(radius: 2.5)
                            .padding(16)
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        ABYSpeechTidyPresence(phase: .arranging)
                            .padding(.bottom, 10)
                    }
                    .background(Color.white.opacity(0.98))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(palette.divider.opacity(0.5), lineWidth: 1)
                    }
                }
            }
            .padding(ABY.Spacing.screen)
            .padding(.bottom, 32)
        }
        .background(ABYBackground())
    }

    private func labSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(ABY.Font.section)
                .tracking(0.8)
                .foregroundStyle(palette.textTertiary)
            content()
        }
    }
}

#Preview {
    DesignTourView()
}
#endif
