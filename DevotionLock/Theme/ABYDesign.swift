//
//  ABYDesign.swift
//  test1
//

import SwiftUI

// Mobbin ABY Journal: iOS grouped light gray, white cards, black accents, SF Pro hierarchy
enum ABY {
    enum Color {
        static let background = SwiftUI.Color(red: 0.949, green: 0.949, blue: 0.969)
        static let surface = SwiftUI.Color.white
        static let textPrimary = SwiftUI.Color.black
        static let textSecondary = SwiftUI.Color(red: 0.557, green: 0.557, blue: 0.576)
        static let textTertiary = SwiftUI.Color(red: 0.682, green: 0.682, blue: 0.698)
        static let divider = SwiftUI.Color.black.opacity(0.06)
        static let track = SwiftUI.Color.black.opacity(0.08)
        static let trackFill = SwiftUI.Color.black

        static let moodPeach = SwiftUI.Color(red: 1.0, green: 0.93, blue: 0.88)
        static let moodPeachText = SwiftUI.Color(red: 0.72, green: 0.45, blue: 0.28)
        static let accentDot = SwiftUI.Color(red: 0.95, green: 0.78, blue: 0.22)

        static let pillPink = SwiftUI.Color(red: 0.92, green: 0.45, blue: 0.58)
        static let pillOrange = SwiftUI.Color(red: 0.92, green: 0.55, blue: 0.32)
        static let pillTeal = SwiftUI.Color(red: 0.30, green: 0.62, blue: 0.58)
        static let pillPurple = SwiftUI.Color(red: 0.55, green: 0.48, blue: 0.72)

        static let orbSage = SwiftUI.Color(red: 0.48, green: 0.68, blue: 0.56)
        static let orbTeal = SwiftUI.Color(red: 0.36, green: 0.71, blue: 0.64)

        static let onboardingTop = SwiftUI.Color(red: 0.88, green: 0.86, blue: 0.96)
        static let onboardingBottom = SwiftUI.Color(red: 0.78, green: 0.82, blue: 0.94)

        // ABY-inspired mesh: lilac → periwinkle → sky (Devotion Lock adds a whisper of sage)
        static let meshLilac = SwiftUI.Color(red: 0.74, green: 0.66, blue: 0.93)
        static let meshLavender = SwiftUI.Color(red: 0.66, green: 0.62, blue: 0.90)
        static let meshPeriwinkle = SwiftUI.Color(red: 0.56, green: 0.66, blue: 0.91)
        static let meshSky = SwiftUI.Color(red: 0.50, green: 0.72, blue: 0.94)
        static let meshSage = SwiftUI.Color(red: 0.58, green: 0.76, blue: 0.72)

        // Clean screen gradient — lilac mist → warm cream (voice, loading, journal)
        static let gradientTop = SwiftUI.Color(red: 0.975, green: 0.968, blue: 0.992)
        static let gradientMid = SwiftUI.Color(red: 0.928, green: 0.918, blue: 0.958)
        static let gradientBottom = SwiftUI.Color(red: 0.984, green: 0.948, blue: 0.908)

        // Night sanctuary — Headspace midnight navy → Calm indigo/violet (Mobbin ref)
        // Top ~#0A0D21, mid ~#141838, bottom ~#1E1648
        static let nightGradientTop = SwiftUI.Color(red: 0.039, green: 0.051, blue: 0.129)
        static let nightGradientMid = SwiftUI.Color(red: 0.078, green: 0.094, blue: 0.220)
        static let nightGradientBottom = SwiftUI.Color(red: 0.118, green: 0.086, blue: 0.282)
        static let nightMeshIndigo = SwiftUI.Color(red: 0.165, green: 0.149, blue: 0.376)
        static let nightMeshPlum = SwiftUI.Color(red: 0.243, green: 0.169, blue: 0.522)
        static let nightMeshViolet = SwiftUI.Color(red: 0.290, green: 0.278, blue: 0.639)

        static let onboardingText = SwiftUI.Color.white
        static let onboardingTextSecondary = SwiftUI.Color.white.opacity(0.78)
        static let onboardingTextMuted = SwiftUI.Color.white.opacity(0.55)
        static let onboardingButtonText = SwiftUI.Color(red: 0.46, green: 0.50, blue: 0.76)
        static let glassFill = SwiftUI.Color.white.opacity(0.16)
        static let glassStroke = SwiftUI.Color.white.opacity(0.32)
    }

    enum Font {
        static var largeTitle: SwiftUI.Font { AppFont.font(size: 34, weight: .bold) }
        static var title: SwiftUI.Font { AppFont.font(size: 28, weight: .bold) }
        static var title2: SwiftUI.Font { AppFont.font(size: 22, weight: .bold) }
        static var headline: SwiftUI.Font { AppFont.font(size: 17, weight: .semibold) }
        static var body: SwiftUI.Font { AppFont.font(size: 15, weight: .regular) }
        static var callout: SwiftUI.Font { AppFont.font(size: 14, weight: .regular) }
        static var subheadline: SwiftUI.Font { AppFont.font(size: 15, weight: .regular) }
        static var footnote: SwiftUI.Font { AppFont.font(size: 13, weight: .regular) }
        static var caption: SwiftUI.Font { AppFont.font(size: 12, weight: .regular) }
        static var captionMedium: SwiftUI.Font { AppFont.font(size: 12, weight: .medium) }
        static var section: SwiftUI.Font { AppFont.font(size: 12, weight: .medium) }
        static var button: SwiftUI.Font { AppFont.font(size: 17, weight: .semibold) }
        static var onboardingTitle: SwiftUI.Font { AppFont.font(size: 26, weight: .bold) }

        // SF Symbols — keep system font so icons render correctly
        static let iconSmall = SwiftUI.Font.system(size: 13, weight: .medium)
        static let iconMedium = SwiftUI.Font.system(size: 15, weight: .medium)
        static let iconLarge = SwiftUI.Font.system(size: 16, weight: .medium)
        static let tabIcon = SwiftUI.Font.system(size: 18, weight: .regular)
        static let tabIconSelected = SwiftUI.Font.system(size: 18, weight: .semibold)
        static let tabLabel = SwiftUI.Font.system(size: 9, weight: .medium)
        static let tabLabelSelected = SwiftUI.Font.system(size: 9, weight: .semibold)
        static let heroIcon = SwiftUI.Font.system(size: 40, weight: .light)
        static let checkmark = SwiftUI.Font.system(size: 20, weight: .regular)
        static let checkmarkLarge = SwiftUI.Font.system(size: 24, weight: .semibold)
        static let emojiSmall = SwiftUI.Font.system(size: 11)
        static let emojiMedium = SwiftUI.Font.system(size: 16)
    }

    enum Radius {
        static let card: CGFloat = 12
        static let cardLarge: CGFloat = 16
        static let glass: CGFloat = 20
        static let chip: CGFloat = 10
    }

    enum Spacing {
        static let screen: CGFloat = 20
        static let card: CGFloat = 16
        static let stack: CGFloat = 12
    }
}

enum ABYLightTheme {
    static let textPrimary = ABY.Color.textPrimary
    static let textSecondary = ABY.Color.textSecondary
    static let textTertiary = ABY.Color.textTertiary
    static let moodPeach = ABY.Color.moodPeach
    static let moodPeachText = ABY.Color.moodPeachText
    static let accentDot = ABY.Color.accentDot
    static let pillPink = ABY.Color.pillPink
    static let pillOrange = ABY.Color.pillOrange
    static let pillTeal = ABY.Color.pillTeal
    static let pillPurple = ABY.Color.pillPurple
    static let track = ABY.Color.track
    static let trackFill = ABY.Color.trackFill
}

struct ABYOnboardingMeshBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ABY.Color.meshLilac, ABY.Color.meshPeriwinkle, ABY.Color.meshSky],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            meshBlob(ABY.Color.meshLavender, size: 340, blur: 70, x: -80, y: -220)
            meshBlob(ABY.Color.meshSky, size: 300, blur: 65, x: 120, y: -60)
            meshBlob(ABY.Color.meshSage.opacity(0.55), size: 260, blur: 60, x: -100, y: 280)
            meshBlob(ABY.Color.meshPeriwinkle, size: 280, blur: 55, x: 140, y: 420)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func meshBlob(_ color: Color, size: CGFloat, blur: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(drift ? 0.85 : 0.65))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(x: x, y: y)
    }
}

struct ABYBackground: View {
    var style: Style = .app
    /// Optional mesh intensity overlay (0 = default clean gradient only).
    var meshOpacity: CGFloat = 0

    enum Style { case app, onboarding }

    var body: some View {
        ZStack {
            switch style {
            case .app:
                ABYCleanGradientBackground()
            case .onboarding:
                ABYOnboardingMeshBackground()
            }

            if meshOpacity > 0 {
                ABYOnboardingMeshBackground()
                    .opacity(meshOpacity)
                    .allowsHitTesting(false)
            }
        }
    }
}

typealias ABYLightBackground = ABYBackground

// MARK: - Night sanctuary feature flag

/// Night sanctuary gradient / dark-mode UI — disabled for now.
enum SanctuaryAppearance {
    static let nightGradientEnabled = false
}

enum SanctuaryGradientMode: String, CaseIterable, Identifiable {
    case light
    case night

    static let storageKey = "sanctuaryGradientMode"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: "Light sanctuary"
        case .night: "Night sanctuary"
        }
    }

    var subtitle: String {
        switch self {
        case .light: "Soft lilac mist and warm cream"
        case .night: "Midnight navy with indigo & violet glow"
        }
    }

    var icon: String {
        switch self {
        case .light: "sun.max.fill"
        case .night: "moon.stars.fill"
        }
    }

    var gradientTop: Color {
        switch self {
        case .light: ABY.Color.gradientTop
        case .night: ABY.Color.nightGradientTop
        }
    }

    var gradientMid: Color {
        switch self {
        case .light: ABY.Color.gradientMid
        case .night: ABY.Color.nightGradientMid
        }
    }

    var gradientBottom: Color {
        switch self {
        case .light: ABY.Color.gradientBottom
        case .night: ABY.Color.nightGradientBottom
        }
    }

    static func resolved(_ mode: SanctuaryGradientMode) -> SanctuaryGradientMode {
        guard SanctuaryAppearance.nightGradientEnabled else { return .light }
        return mode
    }

    static var current: SanctuaryGradientMode {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? SanctuaryGradientMode.light.rawValue
        return resolved(SanctuaryGradientMode(rawValue: raw) ?? .light)
    }
}

/// Semantic colors that adapt between light sanctuary and night sanctuary.
struct SanctuaryPalette: Equatable {
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let surface: Color
    let surfaceMuted: Color
    let surfaceElevated: Color
    let background: Color
    let divider: Color
    let track: Color
    let trackFill: Color
    let buttonFill: Color
    let buttonForeground: Color
    let navBarFill: Color
    let navBarStrokeTop: Color
    let navBarStrokeBottom: Color
    let glassFill: Color
    let glassStroke: Color
    let cardShadowOpacity: Double

    static let light = SanctuaryPalette(
        textPrimary: ABY.Color.textPrimary,
        textSecondary: ABY.Color.textSecondary,
        textTertiary: ABY.Color.textTertiary,
        surface: ABY.Color.surface,
        surfaceMuted: ABY.Color.background,
        surfaceElevated: ABY.Color.surface,
        background: ABY.Color.background,
        divider: ABY.Color.divider,
        track: ABY.Color.track,
        trackFill: ABY.Color.trackFill,
        buttonFill: ABY.Color.textPrimary,
        buttonForeground: Color.white,
        navBarFill: Color.white.opacity(0.62),
        navBarStrokeTop: Color.white.opacity(0.95),
        navBarStrokeBottom: Color.white.opacity(0.35),
        glassFill: ABY.Color.glassFill,
        glassStroke: ABY.Color.glassStroke,
        cardShadowOpacity: 0.04
    )

    /// Headspace Sleep dark — navy cards (#1A1C3D), white/lavender text, dark nav bar.
    static let night = SanctuaryPalette(
        textPrimary: Color(red: 0.941, green: 0.941, blue: 0.973),
        textSecondary: Color(red: 0.690, green: 0.702, blue: 0.839),
        textTertiary: Color(red: 0.541, green: 0.600, blue: 0.788),
        surface: Color(red: 0.102, green: 0.110, blue: 0.239),
        surfaceMuted: Color(red: 0.129, green: 0.145, blue: 0.302),
        surfaceElevated: Color(red: 0.149, green: 0.169, blue: 0.302),
        background: Color(red: 0.082, green: 0.094, blue: 0.176),
        divider: Color.white.opacity(0.08),
        track: Color.white.opacity(0.12),
        trackFill: Color.white,
        buttonFill: Color.white,
        buttonForeground: Color(red: 0.039, green: 0.051, blue: 0.129),
        navBarFill: Color(red: 0.059, green: 0.067, blue: 0.157).opacity(0.94),
        navBarStrokeTop: Color.white.opacity(0.14),
        navBarStrokeBottom: Color.white.opacity(0.06),
        glassFill: Color.white.opacity(0.08),
        glassStroke: Color.white.opacity(0.12),
        cardShadowOpacity: 0.28
    )

    static func forMode(_ mode: SanctuaryGradientMode) -> SanctuaryPalette {
        SanctuaryGradientMode.resolved(mode) == .night ? .night : .light
    }

    var isNight: Bool { self == .night }
}

private struct SanctuaryPaletteKey: EnvironmentKey {
    static let defaultValue = SanctuaryPalette.light
}

extension EnvironmentValues {
    var sanctuaryPalette: SanctuaryPalette {
        get { self[SanctuaryPaletteKey.self] }
        set { self[SanctuaryPaletteKey.self] = newValue }
    }
}

struct ABYCleanGradientBackground: View {
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue

    private var mode: SanctuaryGradientMode {
        SanctuaryGradientMode.resolved(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    var body: some View {
        Group {
            switch mode {
            case .light:
                lightGradient
            case .night:
                ABYNightSanctuaryBackground()
            }
        }
        .ignoresSafeArea()
    }

    private var lightGradient: some View {
        LinearGradient(
            stops: [
                .init(color: ABY.Color.gradientTop, location: 0),
                .init(color: ABY.Color.gradientMid, location: 0.5),
                .init(color: ABY.Color.gradientBottom, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct ABYNightSanctuaryBackground: View {
    @State private var drift = false

    private static let starField: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = [
        (0.12, 0.08, 1.5, 0.35), (0.28, 0.14, 1.0, 0.22), (0.44, 0.06, 1.5, 0.28),
        (0.62, 0.11, 1.0, 0.18), (0.78, 0.07, 1.5, 0.32), (0.91, 0.15, 1.0, 0.20),
        (0.18, 0.22, 1.0, 0.15), (0.55, 0.19, 1.5, 0.25), (0.83, 0.24, 1.0, 0.16),
        (0.35, 0.28, 1.0, 0.12), (0.70, 0.31, 1.5, 0.20), (0.08, 0.18, 1.0, 0.14),
        (0.48, 0.34, 1.0, 0.10), (0.95, 0.28, 1.5, 0.18), (0.22, 0.38, 1.0, 0.08),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: ABY.Color.nightGradientTop, location: 0),
                    .init(color: ABY.Color.nightGradientMid, location: 0.48),
                    .init(color: ABY.Color.nightGradientBottom, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Headspace-style soft indigo/plum mesh glow
            nightBlob(ABY.Color.nightMeshIndigo, size: 340, blur: 90, x: -100, y: -200)
            nightBlob(ABY.Color.nightMeshPlum, size: 300, blur: 80, x: 120, y: -30)
            nightBlob(ABY.Color.nightMeshViolet, size: 260, blur: 75, x: -80, y: 280)
            nightBlob(ABY.Color.nightMeshIndigo.opacity(0.85), size: 280, blur: 70, x: 140, y: 420)

            // Calm-style subtle star field
            GeometryReader { geo in
                ForEach(Array(Self.starField.enumerated()), id: \.offset) { _, star in
                    Circle()
                        .fill(Color.white.opacity(star.opacity))
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func nightBlob(_ color: Color, size: CGFloat, blur: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(drift ? 0.38 : 0.24))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(x: x, y: y)
    }
}

struct SanctuaryGradientBottomFade: View {
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue

    private var bottomColor: Color {
        SanctuaryGradientMode.resolved(SanctuaryGradientMode(rawValue: modeRaw) ?? .light).gradientBottom
    }

    var body: some View {
        LinearGradient(
            colors: [bottomColor.opacity(0), bottomColor],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct ABYJournalGradientBackground: View {
    var body: some View {
        ABYCleanGradientBackground()
    }
}

struct ABYGlassBarBackground: View {
    var cornerRadius: CGFloat = 999
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(palette.navBarFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [palette.navBarStrokeTop, palette.navBarStrokeBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(palette.isNight ? 0.35 : 0.07), radius: 24, y: 10)
            .shadow(color: .black.opacity(palette.isNight ? 0.18 : 0.03), radius: 6, y: 2)
    }
}

struct ABYThinProgressBar: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ABY.Color.track)
                    .frame(height: 3)
                Capsule()
                    .fill(ABY.Color.trackFill)
                    .frame(width: max(0, geo.size.width * min(max(progress, 0), 1)), height: 3)
                    .animation(AppTheme.springSnappy, value: progress)
            }
        }
        .frame(height: 3)
    }
}

struct ABYCardModifier: ViewModifier {
    var cornerRadius: CGFloat = ABY.Radius.cardLarge
    var padding: CGFloat = ABY.Spacing.card
    @Environment(\.sanctuaryPalette) private var palette

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 8, y: 2)
    }
}

struct ABYGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = ABY.Radius.glass
    var padding: CGFloat = ABY.Spacing.card
    @Environment(\.sanctuaryPalette) private var palette

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(palette.glassFill)
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(palette.isNight ? 0.35 : 0.55)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(palette.glassStroke, lineWidth: 1)
            }
    }
}

extension View {
    func abyCard(cornerRadius: CGFloat = ABY.Radius.cardLarge, padding: CGFloat = ABY.Spacing.card) -> some View {
        modifier(ABYCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func abyGlassCard(cornerRadius: CGFloat = ABY.Radius.glass, padding: CGFloat = ABY.Spacing.card) -> some View {
        modifier(ABYGlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func lightGlass(cornerRadius: CGFloat = ABY.Radius.cardLarge) -> some View {
        abyCard(cornerRadius: cornerRadius)
    }

    func abyScreen() -> some View {
        modifier(ABYScreenModifier())
    }

    func abyTransparentScroll() -> some View {
        scrollContentBackground(.hidden)
    }
}

struct ABYOnboardingPrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(ABY.Font.button)
                if let icon {
                    Image(systemName: icon)
                        .font(ABY.Font.iconSmall)
                }
            }
            .foregroundStyle(ABY.Color.onboardingButtonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ABYOnboardingProgressBar: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Color.white : Color.white.opacity(0.28))
                    .frame(height: 3)
                    .animation(AppTheme.springSnappy, value: current)
            }
        }
    }
}

struct ABYOnboardingHeadline: View {
    let eyebrow: String?
    let title: String
    let subtitle: String
    var alignment: TextAlignment = .center

    init(eyebrow: String? = nil, title: String, subtitle: String, alignment: TextAlignment = .center) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.alignment = alignment
    }

    var body: some View {
        VStack(alignment: alignment == .leading ? .leading : .center, spacing: 10) {
            if let eyebrow {
                Text(eyebrow)
                    .font(ABY.Font.callout)
                    .foregroundStyle(ABY.Color.onboardingTextSecondary)
                    .multilineTextAlignment(alignment)
            }
            Text(title)
                .font(ABY.Font.onboardingTitle)
                .foregroundStyle(ABY.Color.onboardingText)
                .multilineTextAlignment(alignment)
            Text(subtitle)
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.onboardingTextSecondary)
                .multilineTextAlignment(alignment)
                .lineSpacing(4)
        }
    }
}

struct ABYSectionHeader: View {
    let title: String
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        Text(title.uppercased())
            .font(ABY.Font.section)
            .foregroundStyle(palette.textSecondary)
            .tracking(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ABYScreenModifier: ViewModifier {
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue

    private var mode: SanctuaryGradientMode {
        SanctuaryGradientMode.resolved(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    func body(content: Content) -> some View {
        content
            .environment(\.sanctuaryPalette, SanctuaryPalette.forMode(mode))
            .preferredColorScheme(mode == .night ? .dark : .light)
    }
}
