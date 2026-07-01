//
//  SacredOrbShell.swift
//  DevotionLock
//
//  Nav capture orb (Meta AI–style radiant ring) + full shell for guided prayer.
//
//  Mobbin refs: WhatsApp Meta AI ring
//  https://mobbin.com/screens/0a61868a-a9dc-4018-b482-cbdc121d9389
//  https://mobbin.com/screens/6474d2b9-3803-4bd3-90ee-143cf9dda044
//

import SwiftUI

// MARK: - Nav FAB — Meta AI hollow gradient ring

struct RadiantCaptureOrb: View {
    @Environment(\.sanctuaryPalette) private var palette

    var size: CGFloat = 52
    var rhythmProgress: CGFloat = 0
    var showsNudge: Bool = false
    var isMenuExpanded: Bool = false
    var isPressing: Bool = false
    var embeddedInBar: Bool = false
    var extraScale: CGFloat = 1

    @State private var breathe = false

    /// Thin stroke like Meta AI chrome icons (WhatsApp search / header).
    private var ringWidth: CGFloat {
        if embeddedInBar {
            return max(2.25, size * 0.095)
        }
        return max(3.5, size * 0.072)
    }

    var body: some View {
        ZStack {
            if embeddedInBar {
                navBarBloom
            } else {
                metaBloomRing(blur: size * 0.09, opacity: bloomOpacity * 0.85, scale: 1.06)
                metaBloomRing(blur: size * 0.04, opacity: bloomOpacity, scale: 1.0)
            }

            Circle()
                .stroke(
                    AngularGradient(colors: ringColors, center: .center),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: size, height: size)

            if !embeddedInBar {
                Circle()
                    .fill(innerGlow)
                    .frame(width: size * 0.62, height: size * 0.62)
                    .blur(radius: size * 0.04)
            }

            if rhythmProgress > 0, !embeddedInBar {
                Circle()
                    .trim(from: 0, to: max(0.08, rhythmProgress) * 0.88)
                    .stroke(
                        AngularGradient(colors: ringColors, center: .center),
                        style: StrokeStyle(lineWidth: ringWidth * 0.45, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: size + ringWidth * 1.4, height: size + ringWidth * 1.4)
                    .opacity(0.5)
            }

            if showsNudge {
                Circle()
                    .fill(ABY.Color.pillOrange)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .offset(x: size * 0.33, y: -size * 0.33)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(extraScale * (breathe ? 1.025 : 0.99))
        .animation(AppTheme.springMenu, value: isMenuExpanded)
        .onAppear { startAnimations() }
        .onChange(of: palette.isNight) { _, _ in startAnimations() }
        .onChange(of: isPressing) { _, pressing in
            if pressing {
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    breathe = true
                }
            } else {
                breathe = false
                startAnimations()
            }
        }
    }

    private func metaBloomRing(blur: CGFloat, opacity: Double, scale: CGFloat) -> some View {
        Circle()
            .stroke(
                AngularGradient(colors: ringColors, center: .center),
                style: StrokeStyle(lineWidth: ringWidth * 1.15, lineCap: .round)
            )
            .frame(width: size * scale, height: size * scale)
            .blur(radius: blur)
            .opacity(opacity)
    }

    /// Single soft halo — matches Meta bottom-nav ring (icon-sized, hollow center).
    private var navBarBloom: some View {
        Circle()
            .stroke(
                AngularGradient(colors: ringColors, center: .center),
                style: StrokeStyle(lineWidth: ringWidth * 1.2, lineCap: .round)
            )
            .frame(width: size, height: size)
            .blur(radius: size * 0.10)
            .opacity(palette.isNight ? 0.50 : 0.58)
    }

    private var bloomOpacity: Double {
        if isMenuExpanded { return palette.isNight ? 0.72 : 0.58 }
        if isPressing { return palette.isNight ? 0.62 : 0.5 }
        return palette.isNight ? 0.48 : 0.38
    }

    private var innerGlow: RadialGradient {
        RadialGradient(
            colors: [
                ringColors[0].opacity(palette.isNight ? 0.14 : 0.08),
                ringColors[2].opacity(palette.isNight ? 0.08 : 0.04),
                .clear,
            ],
            center: .center,
            startRadius: 0,
            endRadius: size * 0.34
        )
    }

    /// Meta AI spectrum — cyan → blue → violet → magenta; sanctuary-tuned per mode.
    private var ringColors: [Color] {
        if palette.isNight {
            [
                metaCyan,
                metaBlue,
                metaViolet,
                metaMagenta,
                metaCyan,
            ]
        } else {
            [
                metaCyan,
                metaBlue,
                metaViolet,
                metaMagenta,
                metaCyan,
            ]
        }
    }

    private var metaCyan: Color {
        palette.isNight
            ? Color(red: 0.20, green: 0.84, blue: 0.98)
            : Color(red: 0.08, green: 0.76, blue: 0.94)
    }

    private var metaBlue: Color {
        palette.isNight
            ? Color(red: 0.24, green: 0.54, blue: 0.98)
            : Color(red: 0.10, green: 0.44, blue: 0.96)
    }

    private var metaViolet: Color {
        palette.isNight
            ? Color(red: 0.54, green: 0.36, blue: 0.96)
            : Color(red: 0.44, green: 0.32, blue: 0.92)
    }

    private var metaMagenta: Color {
        palette.isNight
            ? Color(red: 0.86, green: 0.34, blue: 0.90)
            : Color(red: 0.76, green: 0.26, blue: 0.82)
    }

    private func startAnimations() {
        guard !isPressing, !embeddedInBar else {
            breathe = false
            return
        }
        breathe = false
        withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
            breathe = true
        }
    }
}

// MARK: - Full shell (guided prayer, weaving overlay)

struct SacredOrbShell: View {
    var size: CGFloat = 52
    var visualStyle: SacredOrbVisualStyle = .calm
    var rhythmProgress: CGFloat = 0
    var showsNudge: Bool = false
    var showsMark: Bool = true
    var showsGlow: Bool = true
    var isMenuExpanded: Bool = false
    var extraScale: CGFloat = 1
    /// When true, scale comes only from `extraScale` (breath timeline) — no internal pulse.
    var locksScaleToBreath: Bool = false

    @State private var orbPulse = false
    @State private var orbBreathe = false

    private var markScale: CGFloat { size / 52 }

    var body: some View {
        ZStack {
            if showsGlow {
                orbGlow
            }

            Circle()
                .fill(orbGradient)
                .frame(width: size, height: size)
                .overlay { orbHighlight }
                .overlay { orbBorder }
                .overlay { orbRhythmArc }
                .shadow(color: orbShadowColor, radius: orbShadowRadius, y: size * 0.1)
                .scaleEffect(effectiveScale)

            if showsMark {
                SacredOrbMark(
                    visualStyle: visualStyle,
                    showsNudge: showsNudge,
                    isMenuExpanded: isMenuExpanded,
                    scale: markScale
                )
            }
        }
        .frame(width: size, height: size)
        .onAppear { startOrbAnimations() }
        .onChange(of: visualStyle) { _, _ in startOrbAnimations() }
    }

    @ViewBuilder
    private var orbGlow: some View {
        if visualStyle != .rest {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ABY.Color.orbTeal.opacity(glowStrength),
                            ABY.Color.orbSage.opacity(0.08),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.38, height: size * 1.38)
                .scaleEffect(locksScaleToBreath ? extraScale : glowScale)
                .blur(radius: size * 0.08)
        }
    }

    private var effectiveScale: CGFloat {
        locksScaleToBreath ? extraScale : orbScale * extraScale
    }

    private var glowScale: CGFloat {
        switch visualStyle {
        case .pulse, .weaving:
            orbPulse ? 1.08 : 0.94
        default:
            1.0
        }
    }

    private var glowStrength: Double {
        switch visualStyle {
        case .pulse: 0.34
        case .weaving: 0.26
        case .calm: 0.18
        case .rest: 0
        }
    }

    private var orbGradient: AngularGradient {
        switch visualStyle {
        case .pulse:
            AngularGradient(
                colors: [
                    ABY.Color.orbTeal,
                    ABY.Color.orbSage,
                    ABY.Color.pillPurple.opacity(0.9),
                    ABY.Color.meshSky.opacity(0.85),
                    ABY.Color.orbTeal,
                ],
                center: .center
            )
        case .weaving:
            AngularGradient(
                colors: [
                    ABY.Color.orbTeal,
                    ABY.Color.pillPurple.opacity(0.88),
                    ABY.Color.orbSage,
                    ABY.Color.meshPeriwinkle.opacity(0.82),
                    ABY.Color.orbTeal.opacity(0.95),
                ],
                center: .center
            )
        case .calm:
            AngularGradient(
                colors: [
                    ABY.Color.orbSage,
                    ABY.Color.pillPurple.opacity(0.75),
                    ABY.Color.meshPeriwinkle.opacity(0.8),
                    ABY.Color.orbTeal.opacity(0.9),
                    ABY.Color.orbSage,
                ],
                center: .center
            )
        case .rest:
            AngularGradient(
                colors: [
                    ABY.Color.meshPeriwinkle.opacity(0.85),
                    ABY.Color.orbSage.opacity(0.75),
                    ABY.Color.meshLavender.opacity(0.8),
                    ABY.Color.meshPeriwinkle.opacity(0.85),
                ],
                center: .center
            )
        }
    }

    private var orbHighlight: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(visualStyle == .rest ? 0.18 : 0.28),
                        Color.clear,
                    ],
                    center: .init(x: 0.35, y: 0.3),
                    startRadius: 0,
                    endRadius: size * 0.54
                )
            )
    }

    private var orbBorder: some View {
        Circle()
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(visualStyle == .rest ? 0.45 : 0.75),
                        Color.white.opacity(0.25),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: max(0.5, size * 0.02)
            )
    }

    @ViewBuilder
    private var orbRhythmArc: some View {
        let progress = max(0.08, rhythmProgress)
        if rhythmProgress > 0 {
            Circle()
                .trim(from: 0, to: progress * 0.92)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(visualStyle == .rest ? 0.35 : 0.65),
                            Color.white.opacity(0.15),
                            Color.white.opacity(visualStyle == .rest ? 0.35 : 0.65),
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: max(1, size * 0.029), lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(size * 0.058)
                .opacity(visualStyle == .rest ? 0.7 : 1)
        }
    }

    private var orbScale: CGFloat {
        switch visualStyle {
        case .pulse:
            orbPulse ? 1.05 : 0.96
        case .weaving:
            orbBreathe ? 1.04 : 0.96
        case .calm:
            orbBreathe ? 1.02 : 0.98
        case .rest:
            1.0
        }
    }

    private var orbShadowColor: Color {
        switch visualStyle {
        case .pulse:
            ABY.Color.orbTeal.opacity(0.36)
        case .weaving:
            ABY.Color.orbTeal.opacity(0.28)
        case .calm:
            ABY.Color.pillPurple.opacity(0.22)
        case .rest:
            ABY.Color.meshPeriwinkle.opacity(0.18)
        }
    }

    private var orbShadowRadius: CGFloat {
        switch visualStyle {
        case .pulse: size * 0.31
        case .weaving: size * 0.27
        case .calm: size * 0.23
        case .rest: size * 0.15
        }
    }

    private func startOrbAnimations() {
        orbPulse = false
        orbBreathe = false

        guard !locksScaleToBreath else { return }

        switch visualStyle {
        case .pulse:
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                orbPulse = true
            }
        case .weaving:
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                orbBreathe = true
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                orbPulse = true
            }
        case .calm:
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                orbBreathe = true
            }
        case .rest:
            break
        }
    }
}

/// Constant sacred mark — cross at center, orbiting dots, shell carries state through motion.
struct SacredOrbMark: View {
    let visualStyle: SacredOrbVisualStyle
    var showsNudge: Bool = false
    var isMenuExpanded: Bool = false
    var scale: CGFloat = 1

    @State private var coreGlow = false

    private var usesSacredGlyph: Bool {
        !isMenuExpanded && (visualStyle == .pulse || visualStyle == .weaving)
    }

    private var dotOpacity: Double {
        switch visualStyle {
        case .pulse: 0.96
        case .weaving: 0.94
        case .calm: 0.82
        case .rest: 0.68
        }
    }

    private var rotationDuration: Double {
        switch visualStyle {
        case .pulse: 14
        case .weaving: 10
        case .calm: 28
        case .rest: 40
        }
    }

    var body: some View {
        ZStack {
            if visualStyle == .pulse || visualStyle == .weaving, !isMenuExpanded {
                Circle()
                    .fill(Color.white.opacity(coreGlow ? 0.22 : 0.08))
                    .frame(width: 10 * scale, height: 10 * scale)
                    .blur(radius: 2)
                    .scaleEffect(coreGlow ? 1.35 : 0.85)
            }

            if usesSacredGlyph {
                DotPatternIcon(
                    dotColor: .white.opacity(dotOpacity),
                    rotationDuration: rotationDuration
                )
                .frame(width: 28 * scale, height: 28 * scale)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }

            Image(systemName: isMenuExpanded ? "xmark" : "plus")
                .font(.system(size: 15 * scale, weight: .semibold))
                .foregroundStyle(.white.opacity(isMenuExpanded ? 0.98 : 0.94))
                .scaleEffect(isMenuExpanded ? 1.05 : 1)
                .opacity(usesSacredGlyph ? 0 : 1)
                .animation(AppTheme.springMenu, value: isMenuExpanded)

            if showsNudge, !isMenuExpanded {
                Circle()
                    .fill(ABY.Color.pillOrange)
                    .frame(width: 5 * scale, height: 5 * scale)
                    .offset(x: 10 * scale, y: -10 * scale)
            }
        }
        .animation(AppTheme.springMenu, value: isMenuExpanded)
        .animation(AppTheme.springGentle, value: visualStyle)
        .onAppear { startCoreGlow() }
        .onChange(of: visualStyle) { _, _ in startCoreGlow() }
    }

    private func startCoreGlow() {
        coreGlow = false
        guard visualStyle == .pulse || visualStyle == .weaving else { return }
        let duration = visualStyle == .weaving ? 1.6 : 2.4
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            coreGlow = true
        }
    }
}

/// Guided prayer — weaving shell over the breath orb while Chaplain enriches beats.
struct SacredOrbWeavingOverlay: View {
    var label: String = "Weaving your prayer…"
    var shellSize: CGFloat = 64

    var body: some View {
        VStack(spacing: 14) {
            SacredOrbShell(
                size: shellSize,
                visualStyle: .weaving,
                showsNudge: false
            )
            Text(label)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(.white.opacity(0.58))
                .multilineTextAlignment(.center)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.94)))
    }
}

#Preview("Nav ring light") {
    RadiantCaptureOrb(size: 26, embeddedInBar: true)
        .padding(40)
        .background(ABYFlatTabWashBackground())
}

#Preview("Nav ring night") {
    RadiantCaptureOrb(size: 26, embeddedInBar: true)
        .padding(40)
        .background(ABYEveningReflectionBackground())
        .environment(\.sanctuaryPalette, .night)
        .preferredColorScheme(.dark)
}

#Preview("Hero ring light") {
    RadiantCaptureOrb(size: 52, embeddedInBar: false)
        .padding(40)
        .background(ABYFlatTabWashBackground())
}

#Preview("Shell styles") {
    HStack(spacing: 20) {
        SacredOrbShell(size: 52, visualStyle: .pulse, rhythmProgress: 0.35)
        SacredOrbShell(size: 40, visualStyle: .weaving)
        SacredOrbShell(size: 28, visualStyle: .weaving)
    }
    .padding()
    .background(ABYFlatTabWashBackground())
}
