//
//  OnboardingFlowView.swift
//  test1
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case howItWorks
    case intention
    case voice
    case complete
}

struct OnboardingFlowView: View {
    var onComplete: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var selectedMood: String? = "Peaceful"
    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"
    @State private var contentAppeared = false

    private let moods: [(String, String)] = [
        ("Peaceful", "leaf.fill"),
        ("Overwhelmed", "cloud.rain.fill"),
        ("Grateful", "heart.fill"),
        ("Restless", "wind"),
        ("Hopeful", "sun.horizon.fill"),
    ]

    private let features: [(String, String, String)] = [
        ("lock.shield.fill", "The Shield", "Lock distracting apps until devotion is complete."),
        ("heart.text.square.fill", "Check-in", "Share how you're feeling with your AI Chaplain."),
        ("book.fill", "Devotion", "Personalized verse, reflection, and voice journaling."),
        ("sun.max.fill", "Unlock", "Start your day with a gentle affirmation."),
    ]

    var body: some View {
        ZStack {
            ABYBackground(style: .onboarding)

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if step == .welcome || step == .complete {
                            OnboardingHeroVisual(step: step)
                                .padding(.top, 8)
                        }

                        stepContent
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                bottomCTA
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { animateIn() }
        .onChange(of: step) { _, _ in animateIn() }
    }

    private var topBar: some View {
        VStack(spacing: 16) {
            HStack {
                if step.rawValue > OnboardingStep.welcome.rawValue {
                    OnboardingIconButton(icon: "chevron.left") {
                        withAnimation(AppTheme.springSnappy) {
                            step = OnboardingStep(rawValue: step.rawValue - 1) ?? .welcome
                        }
                    }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
                Spacer()
                if step == .welcome {
                    Button("Skip") { onComplete() }
                        .font(ABY.Font.body.weight(.medium))
                        .foregroundStyle(ABY.Color.onboardingTextMuted)
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
            }
            OnboardingProgressBar(total: 5, current: step.rawValue)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            welcomeContent
        case .howItWorks:
            howItWorksContent
        case .intention:
            intentionContent
        case .voice:
            voiceContent
        case .complete:
            completeContent
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 20) {
            OnboardingInfoCard(
                orbText: "Devotion Lock helps you ",
                boldText: "begin each day with intention"
            )
            OnboardingHeadline(
                title: "Begin with intention",
                subtitle: "Replace reactive scrolling with a peaceful morning devotion — before the world rushes in."
            )
        }
    }

    private var howItWorksContent: some View {
        VStack(spacing: 20) {
            OnboardingHeadline(
                eyebrow: "How it works",
                title: "Protect your mornings",
                subtitle: "Intentional friction to help devotion come first.",
                alignment: .leading
            )
            VStack(spacing: 16) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    OnboardingFeatureRow(
                        icon: feature.0,
                        title: feature.1,
                        detail: feature.2,
                        appeared: contentAppeared,
                        delay: Double(index) * 0.06
                    )
                }
            }
            .abyGlassCard(cornerRadius: ABY.Radius.glass)
        }
    }

    private var intentionContent: some View {
        VStack(spacing: 20) {
            OnboardingHeroVisual(step: .intention)
            OnboardingHeadline(
                title: "How are you this morning?",
                subtitle: "Your Chaplain will tailor today's devotion to where you are."
            )
            VStack(spacing: 8) {
                ForEach(Array(moods.enumerated()), id: \.offset) { index, mood in
                    OnboardingMoodChip(
                        label: mood.0,
                        icon: mood.1,
                        isSelected: selectedMood == mood.0
                    ) {
                        withAnimation(AppTheme.springSnappy) { selectedMood = mood.0 }
                    }
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 10)
                    .animation(AppTheme.springGentle.delay(0.05 + Double(index) * 0.04), value: contentAppeared)
                }
            }
        }
    }

    private var voiceContent: some View {
        VStack(spacing: 20) {
            OnboardingHeroVisual(step: .voice)
            OnboardingHeadline(
                title: "Choose your Chaplain",
                subtitle: "Pick a voice that feels right for your morning devotion."
            )
            VStack(spacing: 10) {
                ForEach(Array(ChaplainVoice.options.enumerated()), id: \.element.id) { index, voice in
                    OnboardingVoiceChip(voice: voice, isSelected: selectedVoiceID == voice.id) {
                        withAnimation(AppTheme.springSnappy) { selectedVoiceID = voice.id }
                        Task { await UserPreferencesSync.shared.pushPreferences(chaplainVoiceID: voice.id) }
                    }
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 10)
                    .animation(AppTheme.springGentle.delay(0.05 + Double(index) * 0.05), value: contentAppeared)
                }
            }
        }
    }

    private var completeContent: some View {
        VStack(spacing: 20) {
            OnboardingHeadline(
                title: "You're ready",
                subtitle: "Tomorrow morning, your sanctuary awaits. Rest well tonight."
            )
            OnboardingGlassInsightCard(
                moodEmoji: moodEmoji(for: selectedMood ?? "Peaceful"),
                moodLabel: selectedMood ?? "Peaceful",
                time: "Now",
                bodyText: insightPreview
            )
        }
    }

    @ViewBuilder
    private var bottomCTA: some View {
        switch step {
        case .welcome, .howItWorks, .intention, .voice:
            OnboardingPrimaryButton(title: ctaTitle, icon: "arrow.right", action: advance)
        case .complete:
            OnboardingPrimaryButton(title: "Enter Devotion Lock", icon: "arrow.right") {
                if let mood = selectedMood {
                    UserDefaults.standard.set(mood, forKey: "intentionMood")
                }
                Task {
                    await UserPreferencesSync.shared.pushPreferences(
                        chaplainVoiceID: selectedVoiceID,
                        intentionMood: selectedMood ?? "Peaceful"
                    )
                }
                onComplete()
            }
        }
    }

    private var ctaTitle: String {
        switch step {
        case .intention: "Set my intention"
        default: "Continue"
        }
    }

    private var insightPreview: String {
        let voice = ChaplainVoice.options.first { $0.id == selectedVoiceID }?.name ?? "Grace"
        return "You'll begin with \(selectedMood ?? "Peaceful") mornings, guided by Chaplain \(voice). Your sanctuary is ready."
    }

    private func moodEmoji(for mood: String) -> String {
        switch mood.lowercased() {
        case "peaceful": "🍃"
        case "grateful": "😊"
        case "overwhelmed": "🌧️"
        case "hopeful": "🌅"
        default: "🙏"
        }
    }

    private func animateIn() {
        contentAppeared = false
        withAnimation(AppTheme.springGentle) { contentAppeared = true }
    }

    private func advance() {
        withAnimation(AppTheme.springSnappy) {
            if let next = OnboardingStep(rawValue: step.rawValue + 1) { step = next }
        }
    }
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
