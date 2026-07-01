//
//  SacredPrayerComponents.swift
//  DevotionLock
//
//  Two guided-prayer prototypes:
//  A) Threshold Chapel — breath-paced, orb-backed, liturgical labels
//  B) Liturgy Weave — mood/focus words woven into prayer lines
//

import SwiftUI

// MARK: - Experience style

enum GuidedPrayerExperienceStyle: String, CaseIterable, Identifiable {
    case threshold
    case liturgyWeave

    var id: String { rawValue }

    var title: String {
        switch self {
        case .threshold: "Threshold Chapel"
        case .liturgyWeave: "Liturgy Weave"
        }
    }

    var subtitle: String {
        switch self {
        case .threshold: "Breath, silence, one line at a time"
        case .liturgyWeave: "Your mood & focus become the prayer"
        }
    }
}

// MARK: - Liturgy weave model

struct LiturgyWeaveContext: Equatable {
    var mood: String
    var focus: FocusTag?
    var userName: String = ""
    var passage: SpiritualPassage?

    static let preview = LiturgyWeaveContext(
        mood: "Peaceful",
        focus: .family,
        userName: "Alex",
        passage: SpiritualPassageCatalog.today
    )
}

struct LiturgyBeat: Identifiable, Equatable {
    let id = UUID()
    let section: String
    let fullText: String
    let highlight: String?
}

enum LiturgyWeaveBuilder {
    static func wovenBeats(context: LiturgyWeaveContext) -> [LiturgyBeat] {
        let mood = context.mood.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let focusPhrase = context.focus?.label.lowercased() ?? "this day"
        let name = context.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let greeting = name.isEmpty ? "Lord" : "Lord"

        var beats: [LiturgyBeat] = [
            LiturgyBeat(
                section: "Arrival",
                fullText: "\(greeting), I arrive feeling \(mood) before this day begins.",
                highlight: mood
            ),
            LiturgyBeat(
                section: "Offering",
                fullText: "Today I hold \(focusPhrase) before you.",
                highlight: focusPhrase
            ),
        ]

        if let passage = context.passage {
            let snippet = passage.text
                .components(separatedBy: .whitespacesAndNewlines)
                .prefix(14)
                .joined(separator: " ")
            beats.append(
                LiturgyBeat(
                    section: "Word",
                    fullText: "Your word reminds me — \(snippet)…",
                    highlight: nil
                )
            )
            beats.append(
                LiturgyBeat(
                    section: "Carry",
                    fullText: "Let \(passage.attribution) anchor me as I step forward.",
                    highlight: passage.attribution
                )
            )
        }

        beats.append(
            LiturgyBeat(
                section: "Release",
                fullText: "Receive my honest morning — \(mood) and all — and walk with me today.",
                highlight: mood
            )
        )
        return beats
    }

    static func wovenBeats(prayer: GuidedPrayer, context: LiturgyWeaveContext) -> [LiturgyBeat] {
        repeatablePrayerBeats(prayer: prayer, context: context)
    }

    /// Speakable, first-person prayer lines the user follows and repeats aloud.
    static func repeatablePrayerBeats(prayer: GuidedPrayer, context: LiturgyWeaveContext) -> [LiturgyBeat] {
        let sections = prayer.liturgicalSections
        let mood = context.mood.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let focusPhrase = context.focus?.label.lowercased() ?? ""
        let name = context.userName.trimmingCharacters(in: .whitespacesAndNewlines)

        let lines = prayer.steps.enumerated().map { index, template in
            personalizeLine(
                template,
                prayerID: prayer.id,
                index: index,
                mood: mood,
                focus: focusPhrase,
                name: name
            )
        }

        return lines.enumerated().map { index, line in
            let section = index < sections.count ? sections[index] : "Prayer"
            let highlight: String?
            if !mood.isEmpty, line.localizedCaseInsensitiveContains(mood) {
                highlight = mood
            } else if !focusPhrase.isEmpty, line.localizedCaseInsensitiveContains(focusPhrase) {
                highlight = focusPhrase
            } else {
                highlight = nil
            }
            return LiturgyBeat(section: section, fullText: line, highlight: highlight)
        }
    }

    private static func personalizeLine(
        _ template: String,
        prayerID: String,
        index: Int,
        mood: String,
        focus: String,
        name: String
    ) -> String {
        switch prayerID {
        case "morning":
            switch index {
            case 0:
                if !name.isEmpty, !mood.isEmpty {
                    return "Lord, I bring you this day before it begins — arriving \(mood), \(name)."
                }
                if !mood.isEmpty {
                    return "Lord, I bring you this \(mood) morning before it begins."
                }
                return template
            case 2 where !focus.isEmpty:
                return morningKindnessLine(focusLabel: focus)
            default:
                return template
            }
        case "anxiety":
            if index == 0, !mood.isEmpty {
                return "Father, you see the \(mood) weight I am carrying."
            }
            return template
        case "gratitude":
            if index == 0, !mood.isEmpty {
                return "Thank you for this \(mood) heart and the grace of this moment."
            }
            return template
        case "evening":
            if index == 3, !name.isEmpty {
                return "Receive me as I am tonight, \(name), and guard my rest."
            }
            return template
        case "others":
            if index == 0, !focus.isEmpty {
                return "Father, I lift up \(focus) before you now."
            }
            return template
        default:
            return template
        }
    }

    /// Third beat of the morning prayer — woven from today's focus tag.
    private static func morningKindnessLine(focusLabel: String) -> String {
        switch focusLabel.lowercased() {
        case "family":
            return "Show me one way to love my family with kindness today."
        case "work":
            return "Help me meet today's work with integrity and grace."
        case "rest":
            return "Teach me to receive rest without guilt today."
        case "faith":
            return "Deepen my faith with one small act of trust today."
        case "health":
            return "Help me care for my body with one gentle choice today."
        case "relationships":
            return "Show me one way to love someone well today."
        default:
            return "Show me one way to walk in kindness today."
        }
    }
}

extension GuidedPrayer {
    var liturgicalSections: [String] {
        switch id {
        case "morning": ["Arrival", "Stillness", "Kindness", "Grace"]
        case "anxiety": ["Naming", "Honesty", "Peace", "Nearness"]
        case "gratitude": ["Breath", "People", "Mercy", "Wonder"]
        case "evening": ["Presence", "Review", "Gratitude", "Rest"]
        case "others": ["Remember", "Comfort", "Wisdom", "Peace"]
        default:
            (0..<steps.count).map { $0 == steps.count - 1 ? "Amen" : "Prayer" }
        }
    }
}

// MARK: - Immersive sanctuary (Mobbin: Calm Sleep, Open, Insight Timer)

struct PrayerSanctuaryAtmosphere: View {
    let tint: Color
    var breathScale: CGFloat = 1

    @State private var drift = false

    private static let starField: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = [
        (0.14, 0.10, 1.5, 0.28), (0.32, 0.16, 1.0, 0.18), (0.58, 0.08, 1.5, 0.22),
        (0.76, 0.12, 1.0, 0.16), (0.88, 0.20, 1.5, 0.24), (0.22, 0.26, 1.0, 0.12),
        (0.48, 0.22, 1.5, 0.20), (0.68, 0.30, 1.0, 0.14), (0.40, 0.36, 1.0, 0.10),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: ABY.Color.nightGradientTop, location: 0),
                    .init(color: ABY.Color.nightGradientMid, location: 0.46),
                    .init(color: ABY.Color.nightGradientBottom, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            chapelBlob(ABY.Color.nightMeshIndigo, size: 340, blur: 95, x: -90, y: -180)
            chapelBlob(ABY.Color.nightMeshPlum, size: 300, blur: 85, x: 110, y: 60)
            chapelBlob(tint, size: 280, blur: 100, x: -40, y: 320)
            chapelBlob(ABY.Color.nightMeshViolet, size: 240, blur: 75, x: 130, y: -60)

            GeometryReader { geo in
                ForEach(Array(Self.starField.enumerated()), id: \.offset) { _, star in
                    Circle()
                        .fill(Color.white.opacity(star.opacity))
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
                }
            }

            RadialGradient(
                colors: [.clear, Color.black.opacity(0.42)],
                center: .center,
                startRadius: 80,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func chapelBlob(_ color: Color, size: CGFloat, blur: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(drift ? 0.32 : 0.20))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(x: x, y: y)
            .scaleEffect(breathScale)
    }
}

/// SacredOrbShell focal point — breath-synced, phase label below (Mobbin: Breathwrk, Calm Tools).
struct PrayerBreathOrb: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var snapshot: PrayerBreathSnapshot
    var tint: Color
    var size: CGFloat = 200
    var rhythmProgress: CGFloat = 0
    var visualStyle: SacredOrbVisualStyle = .calm
    var phaseLabel: String? = nil
    var showsPhaseLabel: Bool = true
    var onHoldAdvance: (() -> Void)? = nil

    private var shellSize: CGFloat { size * 0.74 }
    private var displayLabel: String { phaseLabel ?? snapshot.phaseLabel }

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                if !reduceMotion {
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        .frame(width: size, height: size)
                        .scaleEffect(snapshot.ringScale)
                }

                SacredOrbShell(
                    size: shellSize,
                    visualStyle: visualStyle,
                    rhythmProgress: rhythmProgress,
                    showsNudge: false,
                    showsMark: true,
                    showsGlow: true,
                    extraScale: snapshot.ringScale,
                    locksScaleToBreath: true
                )
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .onTapGesture { onHoldAdvance?() }
            .onLongPressGesture(minimumDuration: 0.45) { onHoldAdvance?() }

            if showsPhaseLabel {
                Text(displayLabel)
                    .font(ABY.Font.section)
                    .foregroundStyle(.white.opacity(0.48))
                    .textCase(.uppercase)
                    .tracking(2.2)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.35), value: displayLabel)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(displayLabel)
        .accessibilityAddTraits(onHoldAdvance != nil ? .isButton : [])
    }
}

/// Threshold breath progress — three quiet dots, no numbers in the orb.
struct PrayerBreathCountDots: View {
    let total: Int
    let remaining: Int

    private var completed: Int { max(0, total - remaining) }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(dotOpacity(for: index))
                    .frame(width: dotSize(for: index), height: dotSize(for: index))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: completed)
    }

    private func dotOpacity(for index: Int) -> Color {
        if index < completed {
            Color.white.opacity(0.52)
        } else if index == completed, remaining > 0 {
            Color.white.opacity(0.30)
        } else {
            Color.white.opacity(0.12)
        }
    }

    private func dotSize(for index: Int) -> CGFloat {
        index == completed && remaining > 0 ? 6 : 5
    }
}

struct PrayerImmersiveChrome: View {
    var beatCount: Int = 0
    var currentBeat: Int = 0
    var showsBeatDots: Bool = false
    let onClose: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.07))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                if showsBeatDots, beatCount > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<beatCount, id: \.self) { index in
                            Capsule()
                                .fill(Color.white.opacity(index <= currentBeat ? 0.42 : 0.14))
                                .frame(width: index == currentBeat ? 14 : 5, height: 4)
                                .animation(.easeInOut(duration: 0.35), value: currentBeat)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()
        }
    }
}

// MARK: - Breath ring (legacy / morning weave)

struct PrayerBreathRing: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var phase: BreathPhase
    var tint: Color
    var size: CGFloat = 220

    enum BreathPhase: Equatable {
        case inhale
        case hold
        case exhale
        case still
    }

    private var outerScale: CGFloat {
        switch phase {
        case .inhale: 1.12
        case .hold: 1.08
        case .exhale: 0.94
        case .still: 1.0
        }
    }

    private var innerOpacity: Double {
        switch phase {
        case .inhale: 0.55
        case .hold: 0.45
        case .exhale: 0.2
        case .still: 0.3
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.12), lineWidth: 1)
                .frame(width: size * 1.35, height: size * 1.35)
                .scaleEffect(reduceMotion ? 1 : outerScale)
                .animation(reduceMotion ? nil : .easeInOut(duration: 4.2), value: phase)

            Circle()
                .stroke(tint.opacity(0.22), lineWidth: 2)
                .frame(width: size, height: size)
                .scaleEffect(reduceMotion ? 1 : outerScale * 0.98)
                .animation(reduceMotion ? nil : .easeInOut(duration: 4.2), value: phase)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(innerOpacity), tint.opacity(0.04), .clear],
                        center: .center,
                        startRadius: size * 0.05,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 0.72, height: size * 0.72)
                .scaleEffect(reduceMotion ? 1 : outerScale * 0.9)
                .animation(reduceMotion ? nil : .easeInOut(duration: 4.2), value: phase)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Highlighted prayer line

struct PrayerLineText: View {
    @Environment(\.sanctuaryPalette) private var palette
    let text: String
    var highlight: String?
    var tint: Color = ABY.Color.pillTeal
    var immersive: Bool = false

    private var primaryColor: Color { immersive ? .white.opacity(0.94) : palette.textPrimary }

    var body: some View {
        if let highlight, !highlight.isEmpty,
           let range = text.range(of: highlight, options: .caseInsensitive) {
            let before = String(text[text.startIndex..<range.lowerBound])
            let match = String(text[range])
            let after = String(text[range.upperBound...])
            Text(prayerLineAttributedText(before: before, match: match, after: after))
                .font(immersive ? ABY.Font.editorialLargeTitle : ABY.Font.editorialHeadline)
                .foregroundStyle(primaryColor)
                .multilineTextAlignment(.center)
                .lineSpacing(immersive ? 10 : 9)
        } else {
            Text(text)
                .font(immersive ? ABY.Font.editorialLargeTitle : ABY.Font.editorialHeadline)
                .foregroundStyle(primaryColor)
                .multilineTextAlignment(.center)
                .lineSpacing(immersive ? 10 : 9)
        }
    }

    private func prayerLineAttributedText(before: String, match: String, after: String) -> AttributedString {
        var result = AttributedString(before)
        var highlighted = AttributedString(match)
        highlighted.foregroundColor = immersive ? tint.opacity(0.95) : tint
        highlighted.inlinePresentationIntent = .stronglyEmphasized
        result.append(highlighted)
        result.append(AttributedString(after))
        return result
    }
}

// MARK: - Threshold Chapel (prototype A)

struct ThresholdPrayerFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let prayer: GuidedPrayer
    var prayerBeats: [LiturgyBeat] = []
    var onComplete: () -> Void

    @State private var phase: SessionPhase = .threshold
    @State private var thresholdExhalesRemaining = 3
    @State private var beatIndex = 0
    @State private var breathAnchor = Date()
    @State private var dwellReady = false
    @State private var lineRevealed = false
    @State private var amenGlow = false
    @State private var breathSessionStartedAt = Date()

    private enum SessionPhase {
        case threshold
        case praying
        case amen
    }

    private var tint: Color { prayer.tintColor }
    private var beats: [LiturgyBeat] {
        prayerBeats.isEmpty
            ? LiturgyWeaveBuilder.repeatablePrayerBeats(prayer: prayer, context: .preview)
            : prayerBeats
    }

    private var beatCount: Int { beats.count }

    var body: some View {
        PrayerBreathTimeline(
            profile: .threshold,
            anchor: breathAnchor,
            onExhaleEnded: handleExhaleEnded
        ) { snapshot in
            ZStack {
                PrayerSanctuaryAtmosphere(
                    tint: tint,
                    breathScale: snapshot.atmosphereScale
                )

                PrayerImmersiveChrome(
                    beatCount: beatCount,
                    currentBeat: phase == .praying ? beatIndex : 0,
                    showsBeatDots: phase == .praying,
                    onClose: { dismiss() }
                )

                Group {
                    if phase == .threshold {
                        thresholdContent(snapshot: snapshot)
                    } else if phase == .praying {
                        prayingContent(snapshot: snapshot)
                    } else {
                        amenContent
                    }
                }
                .padding(.bottom, 36)
            }
            .onChange(of: snapshot.phaseLabel) { _, label in
                syncBreathLiveActivity(
                    phaseLabel: label,
                    breathsRemaining: phase == .threshold ? thresholdExhalesRemaining : 0
                )
            }
            .onChange(of: thresholdExhalesRemaining) { _, remaining in
                syncBreathLiveActivity(phaseLabel: snapshot.phaseLabel, breathsRemaining: remaining)
            }
        }
        .preferredColorScheme(.dark)
        .animation(AppTheme.springGentle, value: phase)
        .animation(AppTheme.springGentle, value: beatIndex)
        .onAppear {
            breathAnchor = Date()
            thresholdExhalesRemaining = 3
            breathSessionStartedAt = Date()
            JournalLiveActivityManager.startPrayerBreathIfAvailable(
                title: prayer.title,
                breathsRemaining: 3,
                phaseLabel: "Inhale"
            )
        }
        .onDisappear {
            JournalLiveActivityManager.end()
        }
        .onChange(of: beatIndex) { _, _ in beginDwell() }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .praying { beginDwell() }
        }
    }

    private func handleExhaleEnded() {
        if phase == .threshold {
            guard thresholdExhalesRemaining > 0 else { return }
            thresholdExhalesRemaining -= 1
            DevotionHaptics.light()
            if thresholdExhalesRemaining == 0 {
                withAnimation(AppTheme.springGentle) { phase = .praying }
            }
            return
        }
        if phase == .praying, !dwellReady {
            dwellReady = true
        }
    }

    private func thresholdContent(snapshot: PrayerBreathSnapshot) -> some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Prepare to pray")
                .font(ABY.Font.editorialSubhead)
                .foregroundStyle(.white.opacity(0.68))
                .padding(.bottom, 44)

            PrayerBreathOrb(
                snapshot: snapshot,
                tint: tint,
                size: 210,
                rhythmProgress: snapshot.cycleProgress,
                visualStyle: .calm,
                onHoldAdvance: skipThreshold
            )

            PrayerBreathCountDots(total: 3, remaining: thresholdExhalesRemaining)
                .padding(.top, 30)

            Text(thresholdExhalesRemaining == 1 ? "One more breath" : "Three quiet breaths")
                .font(ABY.Font.caption)
                .foregroundStyle(.white.opacity(0.34))
                .padding(.top, 14)

            Spacer()

            Button(action: skipThreshold) {
                Text("Enter now")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(.white.opacity(0.32))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .transition(.opacity.combined(with: .scale(scale: 1.02)))
    }

    private func prayingContent(snapshot: PrayerBreathSnapshot) -> some View {
        let beat = beats[safe: beatIndex]
        return VStack(spacing: 0) {
            Spacer(minLength: 52)

            Text(beat?.section.uppercased() ?? "PRAYER")
                .font(ABY.Font.section)
                .tracking(2.4)
                .foregroundStyle(.white.opacity(0.38))
                .padding(.bottom, 36)

            PrayerBreathOrb(
                snapshot: snapshot,
                tint: tint,
                size: 200,
                rhythmProgress: CGFloat(beatIndex + 1) / CGFloat(max(beatCount, 1)),
                visualStyle: .calm,
                showsPhaseLabel: false,
                onHoldAdvance: dwellReady ? { advanceBeat() } : nil
            )
            .padding(.bottom, 40)

            if let beat {
                PrayerLineText(
                    text: beat.fullText,
                    highlight: beat.highlight,
                    tint: tint,
                    immersive: true
                )
                .padding(.horizontal, 36)
                .blurReveal(lineRevealed, blurRadius: 10, scale: 1.01)
                .frame(minHeight: 130)

                Text("Pray this line with me")
                    .font(ABY.Font.caption)
                    .foregroundStyle(.white.opacity(0.28))
                    .padding(.top, 18)
            }

            Spacer()

            if dwellReady {
                Text(beatIndex == beatCount - 1 ? "Amen" : "Tap the orb when ready")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(.white.opacity(0.36))
                    .padding(.bottom, 16)
            }
        }
        .transition(.opacity)
    }

    private var amenContent: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Appreciate this moment")
                .font(ABY.Font.editorialSubhead)
                .foregroundStyle(.white.opacity(0.82))
            Text("of prayer")
                .font(ABY.Font.editorialCallout)
                .foregroundStyle(.white.opacity(0.52))

            Text("Amen")
                .font(ABY.Font.editorialLargeTitle)
                .foregroundStyle(tint.opacity(0.92))
                .padding(.top, 28)
                .scaleEffect(amenGlow ? 1 : 0.94)
                .opacity(amenGlow ? 1 : 0.5)

            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .onAppear {
            DevotionHaptics.success()
            withAnimation(AppTheme.springGentle) { amenGlow = true }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.2))
                onComplete()
                dismiss()
            }
        }
    }

    private func skipThreshold() {
        if phase == .threshold {
            withAnimation(AppTheme.springGentle) { phase = .praying }
        }
    }

    private func beginDwell() {
        dwellReady = false
        lineRevealed = false
        withAnimation(AppTheme.springGentle) { lineRevealed = true }
    }

    private func advanceBeat() {
        if beatIndex < beatCount - 1 {
            DevotionHaptics.light()
            withAnimation(AppTheme.springSnappy) { beatIndex += 1 }
        } else {
            withAnimation(AppTheme.springGentle) { phase = .amen }
        }
    }

    private func syncBreathLiveActivity(phaseLabel: String, breathsRemaining: Int) {
        JournalLiveActivityManager.updatePrayerBreath(
            title: prayer.title,
            breathsRemaining: breathsRemaining,
            phaseLabel: phaseLabel,
            elapsedSeconds: Int(Date().timeIntervalSince(breathSessionStartedAt))
        )
    }
}

// MARK: - Liturgy Weave session (prototype B)

struct LiturgyWeavePrayerView: View {
    @Environment(\.dismiss) private var dismiss

    let beats: [LiturgyBeat]
    var title: String = "Morning prayer"
    var tint: Color = ABY.Color.pillTeal
    var isEnriching: Bool = false
    var onComplete: () -> Void

    @State private var beatIndex = 0
    @State private var revealed = false
    @State private var matchedHighlight = false
    @State private var dwellReady = false
    @State private var breathAnchor = Date()
    @State private var breathSessionStartedAt = Date()
    @Namespace private var weaveNamespace

    private var progress: CGFloat {
        CGFloat(beatIndex + 1) / CGFloat(max(beats.count, 1))
    }

    var body: some View {
        PrayerBreathTimeline(
            profile: .liturgy,
            anchor: breathAnchor,
            onExhaleEnded: { dwellReady = true }
        ) { snapshot in
            ZStack {
                PrayerSanctuaryAtmosphere(tint: tint, breathScale: snapshot.atmosphereScale)
                PrayerImmersiveChrome(
                    beatCount: beats.count,
                    currentBeat: beatIndex,
                    showsBeatDots: true,
                    onClose: { dismiss() }
                )

                VStack(spacing: 0) {
                    Spacer(minLength: 56)

                    if let beat = beats[safe: beatIndex] {
                        Text(beat.section.uppercased())
                            .font(ABY.Font.section)
                            .tracking(2.2)
                            .foregroundStyle(.white.opacity(0.38))
                            .matchedGeometryEffect(id: "section", in: weaveNamespace)
                            .padding(.bottom, 36)

                        PrayerBreathOrb(
                            snapshot: snapshot,
                            tint: tint,
                            size: 190,
                            rhythmProgress: progress,
                            visualStyle: .calm,
                            showsPhaseLabel: false,
                            onHoldAdvance: dwellReady ? { advance() } : nil
                        )
                        .padding(.bottom, 32)

                        if let highlight = beat.highlight {
                            Text(highlight)
                                .font(ABY.Font.captionMedium)
                                .foregroundStyle(tint.opacity(0.88))
                                .textCase(.uppercase)
                                .tracking(1.6)
                                .matchedGeometryEffect(id: "highlight", in: weaveNamespace)
                                .scaleEffect(matchedHighlight ? 1 : 0.94)
                                .opacity(matchedHighlight ? 1 : 0)
                                .padding(.bottom, 18)
                        }

                        PrayerLineText(
                            text: beat.fullText,
                            highlight: beat.highlight,
                            tint: tint,
                            immersive: true
                        )
                        .padding(.horizontal, 32)
                        .blurReveal(revealed, blurRadius: 10, scale: 1.01)
                        .id(beat.id)

                        Text("Pray this line with me")
                            .font(ABY.Font.caption)
                            .foregroundStyle(.white.opacity(0.28))
                            .padding(.top, 14)
                    }

                    Spacer()

                    if dwellReady {
                        Text(beatIndex == beats.count - 1 ? "Amen" : "Tap the orb when ready")
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(.white.opacity(0.36))
                            .padding(.bottom, 16)
                    }
                }
                .padding(.bottom, 36)
            }
            .onChange(of: snapshot.phaseLabel) { _, label in
                JournalLiveActivityManager.updatePrayerBreath(
                    title: title,
                    breathsRemaining: 0,
                    phaseLabel: label,
                    elapsedSeconds: Int(Date().timeIntervalSince(breathSessionStartedAt))
                )
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            breathAnchor = Date()
            breathSessionStartedAt = Date()
            dwellReady = false
            JournalLiveActivityManager.startPrayerBreathIfAvailable(
                title: title,
                breathsRemaining: 0,
                phaseLabel: "Inhale"
            )
            withAnimation(AppTheme.springGentle.delay(0.1)) {
                revealed = true
                matchedHighlight = true
            }
        }
        .onDisappear {
            JournalLiveActivityManager.end()
        }
        .onChange(of: beatIndex) { _, _ in
            dwellReady = false
            revealed = false
            matchedHighlight = false
            withAnimation(AppTheme.springGentle.delay(0.08)) {
                revealed = true
                matchedHighlight = true
            }
        }
    }

    private func advance() {
        if beatIndex < beats.count - 1 {
            DevotionHaptics.light()
            withAnimation(AppTheme.springSnappy) { beatIndex += 1 }
        } else {
            DevotionHaptics.success()
            onComplete()
            dismiss()
        }
    }
}

// MARK: - Router

struct GuidedPrayerExperienceView: View {
    let prayer: GuidedPrayer
    let style: GuidedPrayerExperienceStyle
    var weaveContext: LiturgyWeaveContext = .preview
    var onComplete: () -> Void

    @ObservedObject private var composer = GuidedPrayerComposer.shared

    var body: some View {
        Group {
            switch style {
            case .threshold:
                ThresholdPrayerFlowView(
                    prayer: prayer,
                    prayerBeats: LiturgyWeaveBuilder.repeatablePrayerBeats(prayer: prayer, context: weaveContext),
                    onComplete: onComplete
                )
            case .liturgyWeave:
                LiturgyWeavePrayerView(
                    beats: composer.beats.isEmpty
                        ? LiturgyWeaveBuilder.repeatablePrayerBeats(prayer: prayer, context: weaveContext)
                        : composer.beats,
                    title: prayer.title,
                    tint: prayer.tintColor,
                    isEnriching: composer.isEnriching,
                    onComplete: onComplete
                )
            }
        }
        .onAppear {
            if style == .liturgyWeave {
                composer.load(prayer: prayer, context: weaveContext)
            }
        }
        .onDisappear {
            if style == .liturgyWeave {
                composer.reset()
            }
        }
    }
}

extension GuidedPrayer {
    var tintColor: Color {
        Color(
            red: Double((tintHex >> 16) & 0xFF) / 255,
            green: Double((tintHex >> 8) & 0xFF) / 255,
            blue: Double(tintHex & 0xFF) / 255
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
