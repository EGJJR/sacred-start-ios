//
//  AmbientAIComponents.swift
//  DevotionLock
//
//  Siri-style ambient AI affordances, tuned to the sanctuary palette.
//  A breathing gradient glow marks "AI lives here" without rainbow loudness,
//  and the Home noticing line streams in with inline entity chips.
//
//  Refs: Subble AI assist bar (user clip), Apple Siri edge glow,
//  Mobbin ChatGPT hub composer.
//

import SwiftUI

// MARK: - Breathing AI glow

/// Soft halo in brand blues with a warm gold accent, slowly breathing
/// behind a capsule control. Stronger in night mode where it reads as light.
struct AmbientAIGlowModifier: ViewModifier {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Blooms the halo outward, used while a control expands into its action.
    var intensified = false

    @State private var breathing = false

    private var glowGradient: AngularGradient {
        AngularGradient(
            colors: [
                ABY.Color.meshSky,
                ABY.Color.meshPeriwinkle,
                ABY.Color.meshLilac,
                ABY.Color.meshGold,
                ABY.Color.meshSky,
            ],
            center: .center
        )
    }

    private var haloOpacity: Double {
        let low: Double = palette.isNight ? 0.38 : 0.26
        let high: Double = palette.isNight ? 0.62 : 0.46
        if intensified { return palette.isNight ? 0.95 : 0.75 }
        if reduceMotion { return (low + high) / 2 }
        return breathing ? high : low
    }

    private var edgeOpacity: Double {
        let low: Double = palette.isNight ? 0.5 : 0.38
        let high: Double = palette.isNight ? 0.85 : 0.65
        if intensified { return 1 }
        if reduceMotion { return (low + high) / 2 }
        return breathing ? high : low
    }

    private var haloPadding: CGFloat { intensified ? -7 : -2 }
    private var haloBlur: CGFloat { intensified ? 18 : 9 }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Capsule()
                        .fill(glowGradient)
                        .padding(haloPadding)
                        .blur(radius: haloBlur)
                        .opacity(haloOpacity)

                    Capsule()
                        .fill(glowGradient)
                        .padding(-1.5)
                        .blur(radius: 3)
                        .opacity(edgeOpacity)
                }
                .hueRotation(.degrees(reduceMotion ? 0 : (breathing ? 12 : -8)))
                .allowsHitTesting(false)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                    breathing = true
                }
            }
    }
}

extension View {
    /// Breathing sanctuary-toned AI glow behind a capsule control.
    func ambientAIGlow(intensified: Bool = false) -> some View {
        modifier(AmbientAIGlowModifier(intensified: intensified))
    }
}

// MARK: - Chaplain glow pill (journal hub sheet)

/// Conversational escape hatch below structured options: manual paths above,
/// or just tell Chaplain what you are carrying. Opens an empty chat — never auto-sends.
struct ChaplainGlowPill: View {
    @Environment(\.sanctuaryPalette) private var palette

    var title = "Let Chaplain guide you…"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(ABY.Font.bodyMedium)
                    .foregroundStyle(palette.isNight ? ABY.Color.starlight : ABY.Color.meshPeriwinkle)

                Text(title)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "arrow.up")
                    .font(ABY.Font.captionSemibold)
                    .foregroundStyle(palette.buttonForeground)
                    .frame(width: 26, height: 26)
                    .background(palette.buttonFill)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(palette.composerFill)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(palette.divider.opacity(palette.isNight ? 0.55 : 0.35), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .ambientAIGlow(intensified: false)
        .accessibilityLabel("Let Chaplain guide you")
        .accessibilityHint("Opens a blank conversation with your Chaplain")
    }
}

// MARK: - Story brief (Home greeting)

/// Morning Wrapped's "story so far" as a Home header brief: label, optional
/// weekly narrative, and chip-woven local prose streaming in behind a shimmer.
struct AmbientNoticingBrief: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let brief: AmbientEmpathy.StoryBrief

    @State private var revealed = false

    private var hasNarrative: Bool {
        guard let narrative = brief.narrative else { return false }
        return !narrative.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(brief.title)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(palette.textTertiary)
                .textCase(.uppercase)
                .tracking(1.2)
                .opacity(revealed ? 1 : 0)

            ZStack(alignment: .topLeading) {
                if revealed {
                    storyBody
                        .transition(.opacity.combined(with: .offset(y: 3)))
                } else {
                    NoticingSkeleton()
                        .transition(.opacity)
                }
            }
        }
        .animation(AppTheme.springGentle, value: revealed)
        .animation(AppTheme.springGentle, value: hasNarrative)
        .onAppear {
            guard !revealed else { return }
            if reduceMotion {
                revealed = true
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                revealed = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(brief.accessibilityLabel)
    }

    @ViewBuilder
    private var storyBody: some View {
        if hasNarrative, let narrative = brief.narrative {
            Text(narrative)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            chipFlow
        }
    }

    private var chipFlow: some View {
        AmbientBriefLayout(horizontalSpacing: 4, verticalSpacing: 5) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                switch token {
                case .word(let word):
                    Text(word)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                case .mood(let word):
                    NoticingEntityChip(label: word, style: .mood)
                case .theme(let word):
                    NoticingEntityChip(label: word, style: .theme)
                case .stat(let word):
                    NoticingEntityChip(label: word, style: .stat)
                }
            }
        }
    }

    private enum BriefToken {
        case word(String)
        case mood(String)
        case theme(String)
        case stat(String)
    }

    /// Prose split into words so the flow layout can wrap naturally around chips.
    private var tokens: [BriefToken] {
        brief.segments.flatMap { segment -> [BriefToken] in
            switch segment {
            case .text(let text):
                return text.split(separator: " ").map { .word(String($0)) }
            case .mood(let word):
                return [.mood(word)]
            case .theme(let word):
                return [.theme(word)]
            case .stat(let word):
                return [.stat(word)]
            }
        }
    }
}

// MARK: - Entity chip

private struct NoticingEntityChip: View {
    @Environment(\.sanctuaryPalette) private var palette

    enum Style {
        case mood
        case theme
        case stat
    }

    let label: String
    let style: Style

    private var foreground: Color {
        if palette.isNight { return ABY.Color.starlight }
        switch style {
        case .mood: return ABY.Color.moodPeachText
        case .theme: return ABY.Color.pillPurple
        case .stat: return ABY.Color.pillTeal
        }
    }

    private var fill: Color {
        if palette.isNight { return Color.white.opacity(0.12) }
        switch style {
        case .mood: return ABY.Color.moodPeach
        case .theme: return ABY.Color.pillPurple.opacity(0.14)
        case .stat: return ABY.Color.pillTeal.opacity(0.14)
        }
    }

    var body: some View {
        Text(label)
            .font(ABY.Font.captionMedium)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(fill)
            .clipShape(Capsule())
    }
}

// MARK: - Skeleton shimmer

private struct NoticingSkeleton: View {
    @Environment(\.sanctuaryPalette) private var palette
    @State private var sweep = false

    private var barFill: Color {
        palette.isNight ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            skeletonBar(width: 190)
            skeletonBar(width: 128)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: false)) {
                sweep = true
            }
        }
    }

    private func skeletonBar(width: CGFloat) -> some View {
        Capsule()
            .fill(barFill)
            .frame(width: width, height: 11)
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            (palette.isNight ? Color.white : ABY.Color.meshGold).opacity(0.35),
                            .clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: sweep ? geo.size.width : -geo.size.width * 0.7)
                }
                .clipShape(Capsule())
            }
    }
}

// MARK: - Centered flow layout

/// Wrapping flow that vertically centers each row's items, so word tokens
/// sit on the same visual line as the slightly taller chips.
private struct AmbientBriefLayout: Layout {
    var horizontalSpacing: CGFloat = 4
    var verticalSpacing: CGFloat = 5

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.origin.x, y: bounds.minY + frame.origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var rowStart = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        func closeRow(endingAt end: Int) {
            for index in rowStart..<end {
                frames[index].origin.y = y + (rowHeight - frames[index].height) / 2
            }
            y += rowHeight + verticalSpacing
            rowStart = end
            x = 0
            rowHeight = 0
        }

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                closeRow(endingAt: index)
            }
            frames.append(CGRect(x: x, y: 0, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + horizontalSpacing
            maxX = max(maxX, x - horizontalSpacing)
        }

        if rowStart < subviews.count {
            for index in rowStart..<subviews.count {
                frames[index].origin.y = y + (rowHeight - frames[index].height) / 2
            }
            y += rowHeight
        }

        return (CGSize(width: maxX, height: y), frames)
    }
}

#if DEBUG
#Preview("Brief light") {
    VStack(alignment: .leading, spacing: 24) {
        AmbientNoticingBrief(brief: AmbientEmpathy.StoryBrief(
            title: "The story so far",
            segments: [
                .text("This week you returned"),
                .stat("3 mornings"),
                .text("."),
                .text("You have felt"),
                .mood("overwhelmed"),
                .text("3 times."),
                .theme("Peace"),
                .text("keeps returning in your reflections."),
            ],
            narrative: nil
        ))

        ChaplainGlowPill { }
    }
    .padding(24)
    .background(ABY.Color.background)
}

#Preview("Brief night") {
    VStack(alignment: .leading, spacing: 24) {
        AmbientNoticingBrief(brief: AmbientEmpathy.StoryBrief(
            title: "The story so far",
            segments: [
                .text("This week you returned"),
                .stat("2 mornings"),
                .text("."),
                .text("You have felt"),
                .mood("restless"),
                .text("twice."),
            ],
            narrative: "This week you returned to stillness even when evenings felt heavy."
        ))

        ChaplainGlowPill { }
    }
    .padding(24)
    .background(ABY.Color.eveningReflectionMid)
    .environment(\.sanctuaryPalette, .night)
    .preferredColorScheme(.dark)
}
#endif
