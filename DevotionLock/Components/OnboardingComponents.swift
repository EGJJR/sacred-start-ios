//
//  OnboardingComponents.swift
//  test1
//

import SwiftUI

struct ShepherdLogoView: View {
    var size: CGFloat = 200
    var lightBackdrop = false
    @State private var breathe = false

    var body: some View {
        ZStack {
            Circle()
                .fill(lightBackdrop ? ABY.Color.orbTeal.opacity(0.08) : .white.opacity(0.12))
                .frame(width: size * 1.15, height: size * 1.15)
                .overlay(
                    Circle().strokeBorder(
                        lightBackdrop ? ABY.Color.divider : ABY.Color.glassStroke,
                        lineWidth: 1
                    )
                )
            Image("ShepherdLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .scaleEffect(breathe ? 1.02 : 0.98)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

struct OnboardingProgressRing: View {
    enum Style { case light, dark }

    let progress: CGFloat
    var style: Style = .dark

    private var trackColor: Color {
        style == .light ? ABY.Color.track : Color.white.opacity(0.25)
    }

    private var fillColor: Color {
        style == .light ? ABY.Color.textPrimary : Color.white
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: 2.5)
                .frame(width: 44, height: 44)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(fillColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))
        }
    }
}

struct OnboardingHeroVisual: View {
    let step: OnboardingStep

    var body: some View {
        Group {
            switch step {
            case .welcome:
                ShepherdLogoView(size: 130)
            case .howItWorks:
                featureIcon("lock.shield.fill")
            case .intention:
                featureIcon("heart.text.square.fill")
            case .voice:
                VoiceOrb(state: .idle, size: 110)
            case .complete:
                ZStack {
                    VoiceOrb(state: .listening, size: 100)
                    Image(systemName: "checkmark")
                        .font(ABY.Font.checkmarkLarge)
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
        }
        .frame(height: 140)
    }

    private func featureIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(ABY.Font.heroIcon)
            .foregroundStyle(ABY.Color.onboardingText)
            .frame(width: 100, height: 100)
            .background {
                Circle()
                    .fill(ABY.Color.glassFill)
                    .background(Circle().fill(.ultraThinMaterial).opacity(0.5))
            }
            .overlay(Circle().strokeBorder(ABY.Color.glassStroke, lineWidth: 1))
    }
}

struct OnboardingInfoCard: View {
    let orbText: String
    let boldText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VoiceOrb(state: .idle, size: 32)
                .frame(width: 32, height: 32)
            (Text(orbText).foregroundStyle(ABY.Color.onboardingTextSecondary)
            + Text(boldText).fontWeight(.semibold).foregroundStyle(ABY.Color.onboardingText))
            .font(ABY.Font.callout)
        }
        .abyGlassCard(cornerRadius: ABY.Radius.glass)
    }
}

struct OnboardingGlassSelectionChip: View {
    let label: String
    var icon: String? = nil
    var trailing: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(ABY.Font.iconMedium)
                        .foregroundStyle(isSelected ? ABY.Color.onboardingText : ABY.Color.onboardingTextSecondary)
                        .frame(width: 24)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(ABY.Font.headline)
                        .foregroundStyle(ABY.Color.onboardingText)
                    if let trailing {
                        Text(trailing)
                            .font(ABY.Font.footnote)
                            .foregroundStyle(ABY.Color.onboardingTextSecondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(ABY.Font.checkmark)
                    .foregroundStyle(isSelected ? ABY.Color.onboardingText : ABY.Color.onboardingTextMuted)
            }
            .padding(.horizontal, ABY.Spacing.card)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: ABY.Radius.glass, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.22) : ABY.Color.glassFill)
                    .background {
                        RoundedRectangle(cornerRadius: ABY.Radius.glass, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(isSelected ? 0.65 : 0.45)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.glass, style: .continuous)
                    .strokeBorder(isSelected ? Color.white.opacity(0.55) : ABY.Color.glassStroke, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct OnboardingVoiceChip: View {
    let voice: ChaplainVoice
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        OnboardingGlassSelectionChip(label: voice.name, trailing: voice.personality, isSelected: isSelected, action: action)
    }
}

struct OnboardingMoodChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        OnboardingGlassSelectionChip(label: label, icon: icon, isSelected: isSelected, action: action)
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let detail: String
    var appeared: Bool = true
    var delay: Double = 0

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(ABY.Font.iconLarge)
                .foregroundStyle(ABY.Color.onboardingText)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.chip))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ABY.Font.headline)
                    .foregroundStyle(ABY.Color.onboardingText)
                Text(detail)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(ABY.Color.onboardingTextSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(AppTheme.springGentle.delay(delay), value: appeared)
    }
}

struct OnboardingHeadline: View {
    var eyebrow: String? = nil
    let title: String
    let subtitle: String
    var alignment: TextAlignment = .center

    var body: some View {
        ABYOnboardingHeadline(eyebrow: eyebrow, title: title, subtitle: subtitle, alignment: alignment)
    }
}

struct OnboardingGlassInsightCard: View {
    let moodEmoji: String
    let moodLabel: String
    let time: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                OnboardingMoodPill(emoji: moodEmoji, label: moodLabel)
                Spacer()
                Text(time)
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.onboardingTextMuted)
            }
            Text(bodyText)
                .font(ABY.Font.body)
                .foregroundStyle(ABY.Color.onboardingTextSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .abyGlassCard(cornerRadius: ABY.Radius.glass)
    }
}

struct OnboardingMoodPill: View {
    let emoji: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji).font(ABY.Font.emojiSmall)
            Text(label)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(ABY.Color.onboardingText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
    }
}

struct OnboardingIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(ABY.Font.iconMedium)
                .foregroundStyle(ABY.Color.onboardingText)
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(ABY.Color.glassFill)
                        .background(Circle().fill(.ultraThinMaterial).opacity(0.45))
                }
                .overlay(Circle().strokeBorder(ABY.Color.glassStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

typealias OnboardingProgressBar = ABYOnboardingProgressBar
typealias OnboardingPrimaryButton = ABYOnboardingPrimaryButton
