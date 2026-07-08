//
//  DevotionCompletionView.swift
//  DevotionLock
//
//  Mobbin ABY Journal: quiet insight card on sanctuary background.
//

import SwiftUI

struct DevotionCompletionView: View {
    let streak: Int
    let mood: String
    var insight: String? = nil
    var onContinue: () -> Void

    @Environment(\.sanctuaryPalette) private var palette
    @State private var appeared = false

    private var bodyText: String {
        if let insight, !insight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return insight
        }
        return "Today you showed up with \(DaySummary.withArticle(mood.lowercased())) heart. Sacred Start noticed the quiet faithfulness in showing up."
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                DevotionCompletionHero()
                    .completionReveal(appeared, delay: 0)

                DevotionCompletionInsightCard(
                    moodLabel: mood,
                    bodyText: bodyText
                )
                .completionReveal(appeared, delay: 0.08)

                if streak > 0 {
                    DevotionCompletionStreakChip(streak: streak)
                        .completionReveal(appeared, delay: 0.16)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            ABYPrimaryButton(title: "Continue", icon: "arrow.right") {
                DevotionHaptics.light()
                onContinue()
            }
            .completionCTAReveal(appeared)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            DevotionHaptics.success()
            withAnimation(AppTheme.onboardingStepIn) {
                appeared = true
            }
        }
    }
}

// MARK: - Hero

private struct DevotionCompletionHero: View {
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                VoiceOrb(state: .listening, size: 72)
                Image(systemName: "checkmark")
                    .font(ABY.Font.checkmarkLarge)
                    .foregroundStyle(.white.opacity(0.95))
            }

            Text("Morning devotion complete")
                .font(ABY.Font.title2)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Insight card

private struct DevotionCompletionInsightCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let moodLabel: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sacred Start noticed…")
                .font(ABY.Font.captionSemibold)
                .foregroundStyle(ABY.Color.moodPeachText)
                .textCase(.none)

            HStack {
                MoodPill(label: moodLabel)
                Spacer()
                Text("Just now")
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.textTertiary)
            }

            Text(bodyText)
                .font(ABY.Font.body)
                .foregroundStyle(ABY.Color.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ABY.Spacing.card)
        .background {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            ABY.Color.moodPeach.opacity(0.9),
                            ABY.Color.pillOrange.opacity(0.30),
                            ABY.Color.moodPeach.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ABY.Color.moodPeach.opacity(0.35),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 48
                    )
                )
                .frame(width: 96, height: 96)
                .offset(x: 24, y: -24)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
    }
}

// MARK: - Streak

private struct DevotionCompletionStreakChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let streak: Int

    private var label: String {
        streak == 1 ? "1 day morning streak" : "\(streak) day morning streak"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(ABY.Font.iconSmall)
                .foregroundStyle(ABY.Color.pillOrange)
            Text(label)
                .font(ABY.Font.calloutSemibold)
                .foregroundStyle(ABY.Color.textPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background {
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
        }
        .overlay {
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            ABY.Color.pillOrange.opacity(0.35),
                            ABY.Color.moodPeach.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Reveal

private extension View {
    func completionReveal(_ isRevealed: Bool, delay: Double) -> some View {
        opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed ? 0 : 8)
            .animation(AppTheme.onboardingStepIn.delay(delay), value: isRevealed)
    }

    func completionCTAReveal(_ isRevealed: Bool) -> some View {
        opacity(isRevealed ? 1 : 0)
            .scaleEffect(isRevealed ? 1 : 0.88)
            .animation(
                .spring(response: 0.52, dampingFraction: 0.72).delay(0.24),
                value: isRevealed
            )
    }
}

#Preview {
    ZStack {
        ABYBackground()
        DevotionCompletionView(streak: 6, mood: "Peaceful", onContinue: {})
    }
    .abyScreen()
}
