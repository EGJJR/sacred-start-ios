//
//  CelebrationViews.swift
//  DevotionLock
//

import SwiftUI

struct StreakBornView: View {
    var onCommit: () -> Void

    @Environment(\.sanctuaryPalette) private var palette
    @State private var appeared = false

    var body: some View {
        ZStack {
            ABYGuidedJournalBackground()
            ConfettiView(isActive: appeared)

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(ABY.Color.pillOrange.opacity(0.14))
                        .frame(width: 120, height: 120)
                        .scaleEffect(appeared ? 1 : 0.6)
                    Image(systemName: "flame.fill")
                        .font(ABY.Font.largeTitle)
                        .foregroundStyle(StreakPalette.orange)
                        .scaleEffect(appeared ? 1 : 0.4)
                }

                VStack(spacing: 10) {
                    Text("A streak is born")
                        .font(ABY.Font.title)
                        .foregroundStyle(palette.textPrimary)
                    Text("Open Devotion Lock each morning to help it grow. Even one day is a beautiful start.")
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 28)

                VStack(spacing: 12) {
                    Text("This week")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textTertiary)
                    HStack(spacing: 8) {
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                            VStack(spacing: 6) {
                                Text(day)
                                    .font(ABY.Font.caption)
                                    .foregroundStyle(palette.textTertiary)
                                Circle()
                                    .fill(day == todaySymbol ? StreakPalette.orange : palette.track)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(palette.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
                .padding(.horizontal, ABY.Spacing.screen)

                Spacer()

                ABYPrimaryButton(title: "I'm committed", icon: "checkmark") {
                    DevotionHaptics.success()
                    onCommit()
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 32)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
        }
        .abyScreen()
        .onAppear {
            DevotionHaptics.success()
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }

    private var todaySymbol: String {
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]
        let index = Calendar.current.component(.weekday, from: Date()) - 1
        return symbols[max(0, min(index, 6))]
    }
}

struct StreakCelebrationView: View {
    let result: DevotionFinishResult
    let weekFlags: [Bool]
    var onContinue: () -> Void

    @Environment(\.sanctuaryPalette) private var palette
    @State private var appeared = false
    @State private var sharePresented = false

    private var insightColor: Color {
        palette.isNight ? ABY.Color.starlight.opacity(0.90) : ABY.Color.moodPeachText
    }

    var body: some View {
        ZStack {
            ABYGuidedJournalBackground()
            ConfettiView(isActive: appeared)

            VStack(spacing: 22) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(StreakPalette.orange.opacity(0.15))
                        .frame(width: 130, height: 130)
                        .scaleEffect(appeared ? 1.05 : 0.5)
                    VStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(ABY.Font.largeTitle)
                            .foregroundStyle(StreakPalette.orange)
                        AnimatedStreakNumber(target: result.streak, color: palette.textPrimary)
                            .font(ABY.Font.largeTitle)
                    }
                }

                VStack(spacing: 8) {
                    Text("day streak")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textSecondary)
                    Text("You showed up \(result.mood.lowercased()) today.")
                        .font(ABY.Font.title2)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                ABYWeeklyStrip(completedDays: weekFlags)
                    .padding(.horizontal, ABY.Spacing.screen)

                Text(result.summary.insight)
                    .font(ABY.Font.body)
                    .foregroundStyle(insightColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        sharePresented = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share streak")
                                .font(ABY.Font.button)
                        }
                        .foregroundStyle(palette.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(palette.cardFill)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    ABYPrimaryButton(title: "Continue", icon: "arrow.right") {
                        DevotionHaptics.light()
                        onContinue()
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 32)
            }
            .opacity(appeared ? 1 : 0)
        }
        .abyScreen()
        .onAppear {
            DevotionHaptics.success()
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
        .sheet(isPresented: $sharePresented) {
            ShareSheet(items: [
                "I just completed day \(result.streak) of my morning devotion streak with Devotion Lock 🙏",
            ])
        }
    }
}

struct MilestonePresentation: Identifiable {
    let days: Int
    var id: Int { days }
}

struct StreakMilestoneCelebrationView: View {
    let milestoneDays: Int
    let identity: StreakIdentity
    var onContinue: () -> Void

    @Environment(\.sanctuaryPalette) private var palette
    @State private var appeared = false
    @State private var sharePresented = false

    var body: some View {
        ZStack {
            ABYGuidedJournalBackground()
            ConfettiView(isActive: appeared)

            VStack(spacing: 24) {
                Spacer()

                SanctuaryGrowthArtifact(stage: identity.stage, size: 110)
                    .scaleEffect(appeared ? 1 : 0.5)

                VStack(spacing: 10) {
                    Text(identity.statusName)
                        .font(ABY.Font.title)
                        .foregroundStyle(palette.textPrimary)
                    Text("\(milestoneDays)-day milestone")
                        .font(ABY.Font.headline)
                        .foregroundStyle(ABY.Color.pillTeal)
                    Text(StreakIdentity.milestoneCelebrationCopy(days: milestoneDays))
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        sharePresented = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                                .font(ABY.Font.button)
                        }
                        .foregroundStyle(palette.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(palette.cardFill)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    ABYPrimaryButton(title: "Continue", icon: "arrow.right") {
                        DevotionHaptics.light()
                        onContinue()
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 32)
            }
            .opacity(appeared ? 1 : 0)
        }
        .abyScreen()
        .onAppear {
            DevotionHaptics.success()
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
        .sheet(isPresented: $sharePresented) {
            ShareSheet(items: [
                "I just reached \(milestoneDays) days in the Word: \(identity.statusName) with Devotion Lock",
            ])
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
