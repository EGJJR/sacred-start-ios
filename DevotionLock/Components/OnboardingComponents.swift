//
//  OnboardingComponents.swift
//  test1
//
//  Mobbin ABY Journal: warm sunset + lavender gradients, glass chips,
//  frosted cards, segmented progress, black/white pill CTAs.
//

import SwiftUI

// MARK: - Logo & hero

struct ShepherdLogoView: View {
    var size: CGFloat = 200
    var lightBackdrop = false
    @State private var breathe = false

    var body: some View {
        ZStack {
            Circle()
                .fill(lightBackdrop ? Color.white.opacity(0.22) : .white.opacity(0.12))
                .frame(width: size * 1.15, height: size * 1.15)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
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
            case .entry:
                EmptyView()
            case .goal:
                poolHeroIcon("sparkles")
            case .intention:
                poolHeroIcon("heart.text.square.fill")
            case .voice:
                VoiceOrb(state: .idle, size: 72)
            case .notifications:
                poolHeroIcon("bell.badge.fill")
            case .recap:
                DevotionLockBrandMark(size: 72)
            }
        }
        .frame(height: step == .entry ? 0 : 88)
    }

    private func poolHeroIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(ABY.Font.title)
            .foregroundStyle(ABY.Color.pillPurple)
            .frame(width: 72, height: 72)
            .background(ABY.Color.fieldFill)
            .clipShape(Circle())
    }
}

// MARK: - ABY Journal light education screens

/// ABY "Self-discovery through reflection" body copy with highlighted stat pill.
struct OnboardingStoryBody: View {
    var body: some View {
        Text(storyText)
            .font(ABY.Font.callout)
            .foregroundStyle(ABY.Color.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var storyText: AttributedString {
        var text = AttributedString(
            "Morning devotion deepens faith more than you think. People who pray and journal daily report up to "
        )
        var highlight = AttributedString("40%")
        highlight.font = ABY.Font.headline
        highlight.foregroundColor = ABY.Color.textPrimary
        highlight.backgroundColor = Color.white
        text.append(highlight)
        text.append(AttributedString(" greater sense of peace. Sacred Start helps you show up before the noise begins."))
        return text
    }
}

/// Warm flat-style scene inspired by ABY's reading illustration.
struct OnboardingMorningIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.94, blue: 0.82),
                            Color(red: 0.98, green: 0.88, blue: 0.72),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 168)

            HStack(alignment: .bottom, spacing: 16) {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.55, green: 0.38, blue: 0.22).opacity(0.85))
                        .frame(width: 36, height: 48)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.92, green: 0.72, blue: 0.38))
                        .frame(width: 72, height: 56)
                }

                ZStack {
                    Circle()
                        .fill(Color(red: 0.98, green: 0.82, blue: 0.42))
                        .frame(width: 64, height: 64)
                    Image(systemName: "sun.horizon.fill")
                        .font(ABY.Font.title)
                        .foregroundStyle(Color(red: 0.72, green: 0.48, blue: 0.18))
                }
                .offset(y: -8)

                VStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.58, green: 0.76, blue: 0.72).opacity(0.55))
                        .frame(width: 22, height: 22)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.45, green: 0.62, blue: 0.58))
                        .frame(width: 8, height: 28)
                }
            }
            .padding(.horizontal, 28)
        }
    }
}

/// ABY "ABY helps you see patterns" white insight card.
struct OnboardingHelpCard: View {
    let lead: String
    let highlight: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [ABY.Color.meshSky, ABY.Color.meshLilac, ABY.Color.pillPink.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(lead)
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.textSecondary)
                Text(highlight)
                    .font(ABY.Font.editorialAccent)
                    .foregroundStyle(ABY.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

/// White journey step card on light onboarding screens.
struct OnboardingJourneyStepCard: View {
    let icon: String
    let title: String
    let detail: String
    let stepNumber: Int

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(ABY.Color.background)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(ABY.Font.iconLarge)
                    .foregroundStyle(ABY.Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Step \(stepNumber)")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.textTertiary)
                Text(title)
                    .font(ABY.Font.headline)
                    .foregroundStyle(ABY.Color.textPrimary)
                Text(detail)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(ABY.Color.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

extension View {
    fileprivate func abyJournalGlass(
        cornerRadius: CGFloat = 20,
        isSelected: Bool = false,
        padding: CGFloat = ABY.Spacing.card
    ) -> some View {
        modifier(ABYJournalGlassModifier(
            cornerRadius: cornerRadius,
            isSelected: isSelected,
            padding: padding
        ))
    }
}

private struct ABYJournalGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isSelected: Bool
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.22 : 0.14))
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.45)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(isSelected ? 0.85 : 0.22),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
    }
}

// MARK: - Cards & info

struct OnboardingInfoCard: View {
    let orbText: String
    let boldText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VoiceOrb(state: .idle, size: 32)
                .frame(width: 32, height: 32)
            Text(onboardingInfoAttributedText)
                .font(ABY.Font.callout)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .abyJournalGlass(cornerRadius: 22)
    }

    private var onboardingInfoAttributedText: AttributedString {
        var leading = AttributedString(orbText)
        leading.foregroundColor = ABY.Color.onboardingTextSecondary
        var emphasis = AttributedString(boldText)
        emphasis.font = ABY.Font.calloutSemibold
        emphasis.foregroundColor = ABY.Color.onboardingText
        leading.append(emphasis)
        return leading
    }
}

struct OnboardingValueChecklist: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(ABY.Font.bodySemibold)
                        .foregroundStyle(.white.opacity(0.95))
                    Text(item)
                        .font(ABY.Font.callout)
                        .foregroundStyle(ABY.Color.onboardingTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .abyJournalGlass(cornerRadius: 22, padding: 18)
    }
}

struct OnboardingRhythmTimeline: View {
    private let steps: [(String, String, String)] = [
        ("lock.shield.fill", "Shield", "Optional app blocking until devotion is done."),
        ("book.fill", "Devotion", "Scripture, reflection, and journaling with your Chaplain."),
        ("sun.max.fill", "Unlock", "Start the day with peace — then open your apps."),
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: step.0)
                        .font(ABY.Font.iconLarge)
                        .foregroundStyle(.white.opacity(0.95))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.1)
                            .font(ABY.Font.headline)
                            .foregroundStyle(ABY.Color.onboardingText)
                        Text(step.2)
                            .font(ABY.Font.footnote)
                            .foregroundStyle(ABY.Color.onboardingTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                    Spacer(minLength: 0)
                }
                .abyJournalGlass(cornerRadius: 20, padding: 16)
            }
        }
    }
}

struct OnboardingGlassInsightCard: View {
    let moodEmoji: String
    let moodLabel: String
    let time: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                OnboardingMoodPill(emoji: moodEmoji, label: moodLabel)
                Spacer(minLength: 8)
                Text(time)
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.onboardingTextMuted)
            }

            Text(bodyText)
                .font(ABY.Font.body)
                .foregroundStyle(ABY.Color.onboardingTextSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "book.closed.fill")
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 2)

                Text("Each morning of devotion is a new chapter in your journey.")
                    .font(ABY.Font.footnote)
                    .foregroundStyle(ABY.Color.onboardingTextMuted)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .abyJournalGlass(cornerRadius: 22, padding: 18)
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

// MARK: - Selection chips (ABY Journal glass rows)

private struct ABYJournalSelectionRow: View {
    let label: String
    var detail: String? = nil
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon {
                    Image(systemName: icon)
                        .font(ABY.Font.iconLarge)
                        .foregroundStyle(.white.opacity(isSelected ? 1 : 0.75))
                        .frame(width: 24)
                }

                VStack(alignment: .leading, spacing: detail == nil ? 0 : 3) {
                    Text(label)
                        .font(detail == nil ? ABY.Font.body : ABY.Font.headline)
                        .foregroundStyle(ABY.Color.onboardingText)
                    if let detail {
                        Text(detail)
                            .font(ABY.Font.footnote)
                            .foregroundStyle(ABY.Color.onboardingTextSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .strokeBorder(Color.white.opacity(isSelected ? 1 : 0.35), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, detail == nil ? 16 : 14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.20 : 0.12))
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.4)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(isSelected ? 0.9 : 0.18), lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct OnboardingGlassSelectionChip: View {
    let label: String
    var icon: String? = nil
    var trailing: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ABYJournalSelectionRow(
            label: label,
            detail: trailing,
            icon: icon,
            isSelected: isSelected,
            action: action
        )
    }
}

struct OnboardingVoiceChip: View {
    let voice: ChaplainVoice
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ABYJournalSelectionRow(
            label: voice.name,
            detail: voice.personality,
            isSelected: isSelected,
            action: action
        )
    }
}

struct OnboardingMoodChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ABYJournalSelectionRow(
            label: label,
            icon: icon,
            isSelected: isSelected,
            action: action
        )
    }
}

struct OnboardingGoalChip: View {
    let label: String
    let detail: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ABYJournalSelectionRow(
            label: label,
            detail: detail,
            icon: icon,
            isSelected: isSelected,
            action: action
        )
    }
}

// MARK: - Typography & chrome

struct OnboardingHeadline: View {
    var eyebrow: String? = nil
    let title: String
    let subtitle: String
    var alignment: TextAlignment = .center
    var serifTitle: Bool? = nil

    var body: some View {
        ABYOnboardingHeadline(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
            alignment: alignment,
            serifTitle: serifTitle
        )
    }
}

struct OnboardingStepLabel: View {
    let current: Int
    let total: Int

    var body: some View {
        Text("Step \(current + 1) of \(total)")
            .font(ABY.Font.captionMedium)
            .foregroundStyle(ABY.Color.onboardingTextMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OnboardingSkipLink: View {
    let title: String
    let action: () -> Void
    @Environment(\.onboardingSurface) private var surface

    private var isLightChrome: Bool {
        switch surface {
        case .welcome, .light, .plain: true
        case .gradient: false
        }
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ABY.Font.footnoteMedium)
                .foregroundStyle(isLightChrome ? ABY.Color.textSecondary : ABY.Color.onboardingTextSecondary)
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }
}

struct OnboardingIconButton: View {
    let icon: String
    let action: () -> Void
    @Environment(\.onboardingSurface) private var surface

    private var isLightChrome: Bool {
        switch surface {
        case .welcome, .light, .plain: true
        case .gradient: false
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(ABY.Font.iconMedium)
                .foregroundStyle(isLightChrome ? ABY.Color.textPrimary : ABY.Color.onboardingText)
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(isLightChrome ? Color.black.opacity(0.06) : Color.white.opacity(0.14))
                        .background {
                            if !isLightChrome {
                                Circle().fill(.ultraThinMaterial).opacity(0.35)
                            }
                        }
                }
                .overlay {
                    Circle().strokeBorder(
                        isLightChrome ? Color.black.opacity(0.08) : Color.white.opacity(0.30),
                        lineWidth: 1
                    )
                }
        }
        .buttonStyle(.plain)
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
                .background(Color.white.opacity(0.16))
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

typealias OnboardingProgressBar = ABYOnboardingProgressBar
typealias OnboardingPrimaryButton = ABYOnboardingPrimaryButton

// MARK: - Pool-style floating card shell

struct OnboardingFloatingCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 72)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 24, y: -6)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct OnboardingSegmentProgress: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? ABY.Color.textPrimary : ABY.Color.track)
                    .frame(height: 3)
                    .animation(AppTheme.springSnappy, value: current)
            }
        }
        .frame(maxWidth: 120)
    }
}

struct OnboardingCardChrome: View {
    let progressTotal: Int
    let progressCurrent: Int
    var showBack: Bool = false
    var showSkip: Bool = false
    var skipTitle: String = "Skip"
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if showBack {
                OnboardingLightIconButton(icon: "chevron.left", action: onBack)
            } else {
                Color.clear.frame(width: 36, height: 36)
            }

            Spacer(minLength: 4)

            OnboardingSegmentProgress(total: progressTotal, current: progressCurrent)

            Spacer(minLength: 4)

            if showSkip {
                Button(action: onSkip) {
                    Text(skipTitle)
                        .font(ABY.Font.footnoteMedium)
                        .foregroundStyle(ABY.Color.textTertiary)
                }
                .buttonStyle(.plain)
                .frame(width: 36, alignment: .trailing)
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
    }
}

struct OnboardingLightIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(ABY.Font.iconMedium)
                .foregroundStyle(ABY.Color.textPrimary)
                .frame(width: 36, height: 36)
                .background(ABY.Color.fieldFill)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingPoolChip: View {
    let label: String
    var detail: String? = nil
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(ABY.Font.iconLarge)
                        .foregroundStyle(isSelected ? ABY.Color.textPrimary : ABY.Color.textSecondary)
                        .frame(width: 22)
                }

                VStack(alignment: .leading, spacing: detail == nil ? 0 : 3) {
                    Text(label)
                        .font(detail == nil ? ABY.Font.body : ABY.Font.headline)
                        .foregroundStyle(ABY.Color.textPrimary)
                    if let detail {
                        Text(detail)
                            .font(ABY.Font.footnote)
                            .foregroundStyle(ABY.Color.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? ABY.Color.textPrimary : ABY.Color.track, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(ABY.Color.textPrimary)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, detail == nil ? 14 : 12)
            .background(isSelected ? ABY.Color.textPrimary.opacity(0.06) : ABY.Color.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? ABY.Color.textPrimary.opacity(0.35) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct OnboardingValueSlide: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
}

struct OnboardingValueCarousel: View {
    let slides: [OnboardingValueSlide]
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(spacing: 20) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    VStack(spacing: 16) {
                        valueIllustration(slide.systemImage)
                        Text(slide.title)
                            .font(ABY.Font.editorialTitle)
                            .foregroundStyle(ABY.Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(slide.subtitle)
                            .font(ABY.Font.callout)
                            .foregroundStyle(ABY.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 8)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 280)

            HStack(spacing: 6) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Circle()
                        .fill(index == selectedIndex ? ABY.Color.textPrimary : ABY.Color.track)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    private func valueIllustration(_ name: String) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(ABY.Color.fieldFill)
            .frame(height: 140)
            .overlay {
                Image(systemName: name)
                    .font(ABY.Font.heroIcon)
                    .foregroundStyle(ABY.Color.pillPurple.opacity(0.85))
            }
    }
}

struct OnboardingNotificationPreview: View {
    private let samples: [(String, String)] = [
        ("Your morning devotion is ready", "2m ago"),
        ("Grace noticed a peaceful streak", "1h ago"),
        ("Time for a quiet evening reflection", "Yesterday"),
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(ABY.Color.pillTeal.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "bell.fill")
                                .font(ABY.Font.calloutSemibold)
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(sample.0)
                            .font(ABY.Font.calloutSemibold)
                            .foregroundStyle(ABY.Color.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 0)

                    Text(sample.1)
                        .font(ABY.Font.caption)
                        .foregroundStyle(ABY.Color.textTertiary)
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            }
        }
    }
}

struct SacredStartRecapView: View {
    let goal: String
    let mood: String
    let voiceName: String
    @Binding var weeklyCommitment: Int?
    @Binding var beat: Int
    var onFinish: () -> Void

    private let commitmentOptions = [3, 5, 7]

    var body: some View {
        VStack(spacing: 0) {
            OnboardingSegmentProgress(total: 4, current: beat)
                .padding(.bottom, 24)

            Group {
                switch beat {
                case 0:
                    recapBeat0
                case 1:
                    recapBeat1
                case 2:
                    recapBeat2
                default:
                    recapBeat3
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 16)

            recapActions
        }
    }

    private var recapBeat0: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Sacred Start recap")
                .font(ABY.Font.editorialTitle)
                .foregroundStyle(ABY.Color.textPrimary)
            Text("You came for \(goal.lowercased()), feeling \(mood.lowercased()). Chaplain \(voiceName) will meet you there each morning.")
                .font(ABY.Font.body)
                .foregroundStyle(ABY.Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var recapBeat1: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How many mornings will you show up this week?")
                .font(ABY.Font.editorialTitle)
                .foregroundStyle(ABY.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                ForEach(commitmentOptions, id: \.self) { days in
                    Button {
                        withAnimation(AppTheme.springSnappy) { weeklyCommitment = days }
                    } label: {
                        Text("\(days)")
                            .font(ABY.Font.headline)
                            .foregroundStyle(weeklyCommitment == days ? .white : ABY.Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(weeklyCommitment == days ? ABY.Color.pillTeal : ABY.Color.fieldFill)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recapBeat2: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("We'll help you protect \(goal.lowercased())")
                .font(ABY.Font.editorialTitle)
                .foregroundStyle(ABY.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            OnboardingHelpCard(
                lead: "Your plan",
                highlight: "\(weeklyCommitment ?? 5) mornings with Chaplain \(voiceName), starting \(mood.lowercased())."
            )
        }
    }

    private var recapBeat3: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("A week of showing up stacks higher than you think.")
                .font(ABY.Font.editorialTitle)
                .foregroundStyle(ABY.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Five quiet mornings can reshape how the rest of your day feels.")
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            OnboardingHelpCard(
                lead: "Tomorrow morning",
                highlight: insightPreview
            )
        }
    }

    private var insightPreview: String {
        "Chaplain \(voiceName) will guide your \(mood.lowercased()) mornings, focused on \(goal.lowercased()). Your first devotion awaits."
    }

    @ViewBuilder
    private var recapActions: some View {
        if beat < 3 {
            HStack {
                if beat > 0 {
                    Button("Back") {
                        withAnimation(AppTheme.springSnappy) { beat -= 1 }
                    }
                    .font(ABY.Font.callout)
                    .foregroundStyle(ABY.Color.textSecondary)
                }
                Spacer()
                Button(beat == 1 && weeklyCommitment == nil ? "Continue" : "Next") {
                    if beat == 1 && weeklyCommitment == nil { return }
                    withAnimation(AppTheme.springSnappy) { beat += 1 }
                }
                .font(ABY.Font.calloutSemibold)
                .foregroundStyle(ABY.Color.pillTeal)
                .disabled(beat == 1 && weeklyCommitment == nil)
            }
        } else {
            AuthPrimaryCapsuleButton(title: "Start my journey", action: onFinish)
        }
    }
}

struct OnboardingPoolPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ABY.Font.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ABY.Color.pillTeal.opacity(isEnabled ? 1 : 0.45))
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
    }
}

struct OnboardingEntryGate: View {
    var onEnter: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Button(action: onEnter) {
                VStack(spacing: 24) {
                    DevotionLockBrandMark(size: 120)

                    VStack(spacing: 8) {
                        Text("Sacred Start")
                            .font(ABY.Font.editorialLargeTitle)
                            .foregroundStyle(.white)
                        Text("Sacro Cuore di Gesù")
                            .font(ABY.Font.editorialAccent)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }
            }
            .buttonStyle(.plain)

            Text("Tap to begin your sanctuary")
                .font(ABY.Font.callout)
                .foregroundStyle(.white.opacity(0.85))

            Spacer()
            Spacer()
        }
        .padding(.horizontal, ABY.Spacing.screen)
    }
}
