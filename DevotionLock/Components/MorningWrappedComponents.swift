//
//  MorningWrappedComponents.swift
//  DevotionLock
//
//  Custom animated building blocks for "Your week in review".
//

import SwiftUI

// MARK: - Story chrome (Mobbin: How We Feel / Opal / Apple Music Replay)

enum WrappedStoryBeat: Int, CaseIterable, Identifiable {
    case intro
    case mornings
    case rhythm
    case mood
    case streak
    case chaplain
    case narrative
    case closing

    var id: Int { rawValue }
}

struct WrappedStoryProgress: View {
    @Environment(\.sanctuaryPalette) private var palette
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(fillColor(for: index))
                    .frame(height: 3)
                    .animation(AppTheme.springSnappy, value: current)
            }
        }
        .accessibilityLabel("Story page \(current + 1) of \(total)")
    }

    private func fillColor(for index: Int) -> Color {
        if index < current { return palette.textPrimary.opacity(0.35) }
        if index == current { return palette.textPrimary }
        return palette.track
    }
}

struct WrappedStoryChrome: View {
    @Environment(\.sanctuaryPalette) private var palette
    let current: Int
    let total: Int
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(ABY.Font.footnoteSemibold)
                        .foregroundStyle(palette.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(palette.surface.opacity(0.92))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Week in review")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.1)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }

            WrappedStoryProgress(current: current, total: total)
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 8)
    }
}

struct WrappedStoryHeadline: View {
    @Environment(\.sanctuaryPalette) private var palette
    let text: String
    var subtitle: String? = nil
    var appeared: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(text)
                .font(ABY.Font.editorialLargeTitle)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .blurReveal(appeared, blurRadius: 10, scale: 1.01)

            if let subtitle {
                Text(subtitle)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .blurReveal(appeared, blurRadius: 6, scale: 1.004)
            }
        }
        .padding(.horizontal, ABY.Spacing.screen)
    }
}

struct WrappedStoryStatCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let value: String
    let label: String
    var badge: String? = nil
    var tint: Color = ABY.Color.pillTeal

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(value)
                    .font(ABY.Font.displayLarge)
                    .foregroundStyle(palette.textPrimary)

                if let badge {
                    Text(badge)
                        .font(ABY.Font.captionSemibold)
                        .foregroundStyle(tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(tint.opacity(0.14))
                        .clipShape(Capsule())
                }
            }

            Text(label)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(palette.isNight ? 0.12 : 0.98))
                .shadow(color: .black.opacity(palette.isNight ? 0.22 : 0.06), radius: 20, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(palette.divider.opacity(0.45), lineWidth: 1)
        }
    }
}

struct WrappedMoodStoryOrb: View {
    let emoji: String
    let mood: String
    var appeared: Bool

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ABY.Color.pillPink.opacity(0.55), ABY.Color.pillPurple.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 148, height: 148)
                    .blurReveal(appeared, blurRadius: 12, scale: 0.94)

                Text(emoji)
                    .font(.system(size: 68))
            }

            Text(mood)
                .font(ABY.Font.title)
                .foregroundStyle(ABY.Color.textPrimary)
        }
    }
}

// MARK: - Hero counter

struct WrappedHeroCounter: View {
    let value: Int
    let label: String
    var tint: Color = ABY.Color.pillOrange
    var appeared: Bool

    @State private var displayValue = 0

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(tint.opacity(0.14 - Double(ring) * 0.03), lineWidth: 1)
                        .frame(width: 140 + CGFloat(ring) * 28, height: 140 + CGFloat(ring) * 28)
                        .scaleEffect(appeared ? 1 : 0.82)
                        .opacity(appeared ? 1 : 0)
                        .animation(AppTheme.springGentle.delay(Double(ring) * 0.06), value: appeared)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.35), tint.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 2)

                Text("\(displayValue)")
                    .font(ABY.Font.displayLarge)
                    .foregroundStyle(ABY.Color.textPrimary)
                    .contentTransition(.numericText())
            }

            Text(label)
                .font(ABY.Font.title2)
                .foregroundStyle(ABY.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .onAppear { animateCount() }
        .onChange(of: appeared) { _, isVisible in
            if isVisible { animateCount() }
        }
        .onChange(of: value) { _, _ in animateCount() }
    }

    private func animateCount() {
        guard appeared else {
            displayValue = 0
            return
        }
        displayValue = 0
        guard value > 0 else { return }
        let steps = min(value, 12)
        let stride = max(1, value / steps)
        for step in 0...steps {
            let target = min(value, step * stride)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.07) {
                withAnimation(.easeOut(duration: 0.2)) {
                    displayValue = step == steps ? value : target
                }
            }
        }
    }
}

// MARK: - Week rhythm (reuses streak weekly strip)

struct WrappedWeekRhythmPanel: View {
    @Environment(\.sanctuaryPalette) private var palette
    let completedDays: [Bool]
    var appeared: Bool

    private var completedCount: Int {
        completedDays.filter { $0 }.count
    }

    var body: some View {
        ABYGlassPanel {
            VStack(spacing: 14) {
                ABYWeeklyStrip(completedDays: completedDays, showsCardBackground: false)

                Text("\(completedCount) of 7 mornings")
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .blurReveal(appeared, blurRadius: 8)
    }
}

// MARK: - Mood reveal

struct WrappedMoodReveal: View {
    let emoji: String
    let mood: String
    var appeared: Bool

    @State private var float = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(ABY.Color.pillPink.opacity(0.2))
                    .frame(width: 130, height: 130)
                    .blur(radius: 18)
                    .offset(y: float ? -6 : 6)

                Text(emoji)
                    .font(.system(size: 64))
                    .offset(y: float ? -4 : 4)
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            Text(mood)
                .font(ABY.Font.largeTitle)
                .foregroundStyle(ABY.Color.textPrimary)
                .blurReveal(appeared, blurRadius: 8)
        }
        .onAppear {
            guard appeared else { return }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                float = true
            }
        }
        .onChange(of: appeared) { _, visible in
            if visible {
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                    float = true
                }
            }
        }
    }
}

// MARK: - Streak flame

struct WrappedStreakFlame: View {
    let streak: Int
    var appeared: Bool

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(StreakPalette.orange.opacity(0.25), lineWidth: 2)
                    .frame(width: 110, height: 110)
                    .scaleEffect(pulse ? 1.08 : 0.94)

                Image(systemName: "flame.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [StreakPalette.orangeLight, StreakPalette.orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(appeared ? (pulse ? 1.06 : 0.96) : 0.6)
            }

            Text("\(streak) day streak")
                .font(ABY.Font.title2)
                .foregroundStyle(ABY.Color.textPrimary)
                .contentTransition(.numericText())
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Chaplain note

struct WrappedChaplainNote: View {
    let insight: String
    var appeared: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "ellipsis.bubble.fill")
                    .foregroundStyle(ABY.Color.pillPurple)
                Text("Chaplain's note")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.2)
            }

            Text(insight)
                .font(ABY.Font.editorialHeadline)
                .foregroundStyle(ABY.Color.textPrimary)
                .lineSpacing(8)
                .blurReveal(appeared, blurRadius: 10, scale: 1.01)
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .fill(ABY.Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                        .stroke(ABY.Color.pillPurple.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Narrative chapter

struct WrappedNarrativeChapter: View {
    let narrative: String
    var appeared: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The story so far")
                .font(ABY.Font.section)
                .foregroundStyle(ABY.Color.textTertiary)
                .textCase(.uppercase)
                .tracking(1.4)

            Text(narrative)
                .font(ABY.Font.editorialBody)
                .foregroundStyle(ABY.Color.textSecondary)
                .lineSpacing(7)
                .blurReveal(appeared, blurRadius: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
