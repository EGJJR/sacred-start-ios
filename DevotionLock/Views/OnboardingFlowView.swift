//
//  OnboardingFlowView.swift
//  DevotionLock
//
//  Pool-adapted Sacred Start onboarding: sanctuary gradient + floating white cards.
//

import SwiftUI
import UIKit

enum OnboardingStep: Int, CaseIterable {
    case entry
    case goal
    case intention
    case voice
    case notifications
    case recap

    static let progressStepCount = 4

    var progressIndex: Int? {
        switch self {
        case .entry: nil
        case .goal: 0
        case .intention: nil
        case .voice: 1
        case .notifications: 2
        case .recap: 3
        }
    }

    var showsFloatingCard: Bool { self != .entry }
}

struct OnboardingFlowView: View {
    var onComplete: () -> Void
    var initialStep: OnboardingStep = .entry

    @State private var auth = AuthManager.shared
    @State private var step: OnboardingStep
    @State private var selectedGoal: String? = "Morning devotion"
    @State private var intentionNote = ""
    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"
    @State private var stepRevealed = false
    @State private var recapBeat = 0
    @State private var weeklyCommitment: Int? = nil
    @State private var isPreparingSanctuary = false
    @State private var isRequestingNotificationPermission = false
    @State private var notificationPermissionDenied = false
    @Environment(\.openURL) private var openURL

    private let goals: [(String, String, String)] = [
        ("Morning devotion", "Start each day in Scripture and prayer.", "sun.horizon.fill"),
        ("Less phone distraction", "Protect your mornings before the scroll.", "lock.shield.fill"),
        ("Prayer & reflection", "Journal and talk with your AI Chaplain.", "hands.sparkles.fill"),
        ("Spiritual growth", "Build a steady rhythm in the Word.", "leaf.fill"),
    ]

    init(initialStep: OnboardingStep = .entry, onComplete: @escaping () -> Void) {
        self.initialStep = initialStep
        self.onComplete = onComplete
        _step = State(initialValue: initialStep)
    }

    var body: some View {
        ZStack {
            ABYWarmSanctuaryBackground()

            if isPreparingSanctuary {
                preparingOverlay
            } else if step == .entry {
                OnboardingEntryGate {
                    advanceFromEntry()
                }
                .onboardingStepReveal(stepRevealed)
            } else {
                floatingCardFlow
            }
        }
        .environment(\.onboardingSurface, .light)
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(AppTheme.onboardingStepIn) { stepRevealed = true }
        }
    }

    private var floatingCardFlow: some View {
        OnboardingFloatingCard {
            VStack(spacing: 0) {
                if step != .recap {
                    OnboardingCardChrome(
                        progressTotal: OnboardingStep.progressStepCount,
                        progressCurrent: step.progressIndex ?? 0,
                        showBack: step.rawValue > OnboardingStep.goal.rawValue,
                        showSkip: step == .voice,
                        onBack: goBack,
                        onSkip: { advance() }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .onboardingStepReveal(stepRevealed)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if step != .recap {
                            OnboardingHeroVisual(step: step)
                                .onboardingStepReveal(stepRevealed)
                        }

                        stepContent
                            .onboardingStepReveal(stepRevealed)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }

                if step != .recap {
                    bottomCTA
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                        .onboardingStepReveal(stepRevealed)
                }
            }
        }
    }

    private var preparingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
            Text("Preparing your sanctuary…")
                .font(ABY.Font.callout)
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .entry:
            EmptyView()
        case .goal:
            goalContent
        case .intention:
            EmptyView()
        case .voice:
            voiceContent
        case .notifications:
            notificationsContent
        case .recap:
            SacredStartRecapView(
                goal: selectedGoal ?? "morning devotion",
                voiceName: selectedVoiceName,
                weeklyCommitment: $weeklyCommitment,
                beat: $recapBeat,
                onFinish: finishOnboarding
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
    }

    private var goalContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingHeadline(
                eyebrow: "Welcome, \(auth.displayName)",
                title: "What brings you here?",
                subtitle: "We'll tailor your devotion and Chaplain to your focus.",
                alignment: .leading,
                serifTitle: true
            )
            VStack(spacing: 8) {
                ForEach(Array(goals.enumerated()), id: \.offset) { _, goal in
                    OnboardingPoolChip(
                        label: goal.0,
                        detail: goal.1,
                        icon: goal.2,
                        isSelected: selectedGoal == goal.0
                    ) {
                        withAnimation(AppTheme.springSnappy) { selectedGoal = goal.0 }
                    }
                }
            }
        }
    }

    /*
    private var intentionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingHeadline(
                title: "How are you feeling?",
                subtitle: "Your Chaplain will shape today's devotion around where you are.",
                alignment: .leading,
                serifTitle: true
            )

            VStack(spacing: 8) {
                ForEach(Array(moods.enumerated()), id: \.offset) { _, mood in
                    OnboardingPoolChip(
                        label: mood.0,
                        icon: mood.1,
                        isSelected: selectedMood == mood.0
                    ) {
                        withAnimation(AppTheme.springSnappy) { selectedMood = mood.0 }
                    }
                }
            }

            TextField("What's on your mind this week?", text: $intentionNote, axis: .vertical)
                .font(ABY.Font.body)
                .lineLimit(3...5)
                .padding(14)
                .background(ABY.Color.fieldFill)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
    */

    private var voiceContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingHeadline(
                title: "Choose your Chaplain",
                subtitle: "Pick a voice that feels right for your morning devotion.",
                alignment: .leading,
                serifTitle: true
            )
            VStack(spacing: 8) {
                ForEach(ChaplainVoice.options) { voice in
                    OnboardingPoolChip(
                        label: voice.name,
                        detail: voice.personality,
                        isSelected: selectedVoiceID == voice.id
                    ) {
                        withAnimation(AppTheme.springSnappy) { selectedVoiceID = voice.id }
                        Task { await UserPreferencesSync.shared.pushPreferences(chaplainVoiceID: voice.id) }
                    }
                }
            }
        }
    }

    private var notificationsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingHeadline(
                title: "Get gentle morning reminders",
                subtitle: "We'll nudge you when your devotion is ready. You can change this anytime.",
                alignment: .leading,
                serifTitle: true
            )

            OnboardingNotificationPreview()

            if notificationPermissionDenied {
                Text("Notifications are turned off in iOS Settings. Tap Allow below to open Settings, then come back and continue.")
                    .font(ABY.Font.footnote)
                    .foregroundStyle(ABY.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            NotificationManager.shared.configure()
            notificationPermissionDenied = false
        }
    }

    // MARK: - Bottom CTA

    @ViewBuilder
    private var bottomCTA: some View {
        switch step {
        case .notifications:
            VStack(spacing: 10) {
                OnboardingPoolPrimaryButton(
                    title: isRequestingNotificationPermission ? "Waiting…" : "Allow notifications",
                    isEnabled: !isRequestingNotificationPermission,
                    action: { Task { await requestNotificationPermission() } }
                )
                Button("Not now") { advance() }
                    .font(ABY.Font.footnoteMedium)
                    .foregroundStyle(ABY.Color.textTertiary)
            }
        case .goal, .voice:
            OnboardingPoolPrimaryButton(title: ctaTitle, isEnabled: canAdvance, action: advance)
        default:
            EmptyView()
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .goal: selectedGoal != nil
        default: true
        }
    }

    private var ctaTitle: String {
        switch step {
        case .voice: "Continue"
        default: "Continue"
        }
    }

    private var selectedVoiceName: String {
        ChaplainVoice.options.first { $0.id == selectedVoiceID }?.name ?? "Grace"
    }

    private func requestNotificationPermission() async {
        isRequestingNotificationPermission = true
        defer { isRequestingNotificationPermission = false }

        let status = await NotificationManager.shared.authorizationStatus()
        if status == .denied {
            notificationPermissionDenied = true
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
            return
        }

        let granted = await NotificationManager.shared.requestAuthorizationEnablingDefaults()
        if granted {
            notificationPermissionDenied = false
            advance()
            return
        }

        let updated = await NotificationManager.shared.authorizationStatus()
        notificationPermissionDenied = updated == .denied
    }

    private func finishOnboarding() {
        if let goal = selectedGoal {
            UserDefaults.standard.set(goal, forKey: "onboardingGoal")
        }
        if !intentionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            UserDefaults.standard.set(intentionNote, forKey: "onboardingIntentionNote")
        }
        if let weeklyCommitment {
            UserDefaults.standard.set(weeklyCommitment, forKey: "onboardingWeeklyCommitment")
        }
        Task {
            await UserPreferencesSync.shared.pushPreferences(
                chaplainVoiceID: selectedVoiceID
            )
        }

        withAnimation { isPreparingSanctuary = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onComplete()
        }
    }

    private func advanceFromEntry() {
        OnboardingStepTransition.animateChange(revealed: $stepRevealed) {
            step = .goal
        }
    }

    private func goBack() {
        OnboardingStepTransition.animateChange(revealed: $stepRevealed) {
            if step == .goal {
                step = .entry
            } else if let prev = previousStep(before: step) {
                step = prev
            }
            if step != .recap { recapBeat = 0 }
        }
    }

    private func advance() {
        OnboardingStepTransition.animateChange(revealed: $stepRevealed) {
            if let next = nextStep(after: step) {
                step = next
            }
        }
    }

    private func nextStep(after step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .entry: .goal
        case .goal: .voice
        case .intention: .voice
        case .voice: .notifications
        case .notifications: .recap
        case .recap: nil
        }
    }

    private func previousStep(before step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .entry: nil
        case .goal: .entry
        case .intention: .goal
        case .voice: .goal
        case .notifications: .voice
        case .recap: .notifications
        }
    }
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
