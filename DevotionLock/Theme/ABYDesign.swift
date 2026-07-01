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
        static let linkBlue = SwiftUI.Color(red: 0.0, green: 0.478, blue: 1.0)
        static let fieldFill = SwiftUI.Color(red: 0.949, green: 0.949, blue: 0.969)
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

        static let onboardingTop = SwiftUI.Color(red: 0.91, green: 0.36, blue: 0.27)
        static let onboardingBottom = SwiftUI.Color(red: 0.95, green: 0.72, blue: 0.19)

        // Sanctuary mesh — lavender, pink, periwinkle, sky (Mobbin ABY refs)
        static let meshLilac = SwiftUI.Color(red: 0.72, green: 0.58, blue: 0.88)
        static let meshLavender = SwiftUI.Color(red: 0.88, green: 0.70, blue: 0.86)
        static let meshPeriwinkle = SwiftUI.Color(red: 0.58, green: 0.64, blue: 0.90)
        static let meshSky = SwiftUI.Color(red: 0.52, green: 0.74, blue: 0.94)
        static let meshSage = SwiftUI.Color(red: 0.62, green: 0.78, blue: 0.88)

        static let meshCoral = SwiftUI.Color(red: 0.85, green: 0.25, blue: 0.30)
        static let meshAmber = SwiftUI.Color(red: 0.98, green: 0.55, blue: 0.22)
        static let meshGold = SwiftUI.Color(red: 0.99, green: 0.78, blue: 0.35)
        static let meshRose = SwiftUI.Color(red: 0.92, green: 0.45, blue: 0.35)
        static let meshHoney = SwiftUI.Color(red: 0.88, green: 0.62, blue: 0.38)

        // Bold onboarding sunset (personalization screens only)
        static let sunsetGradientTop = SwiftUI.Color(red: 0.70, green: 0.14, blue: 0.21)
        static let sunsetGradientMid = SwiftUI.Color(red: 0.91, green: 0.36, blue: 0.27)
        static let sunsetGradientBottom = SwiftUI.Color(red: 0.95, green: 0.72, blue: 0.19)

        // Soft lavender sanctuary — ABY home, journal, main tabs (Mobbin 0e8b2fff / fdb91744)
        static let sanctuaryGradientTop = SwiftUI.Color(red: 0.90, green: 0.84, blue: 0.96)
        static let sanctuaryGradientMid = SwiftUI.Color(red: 0.94, green: 0.86, blue: 0.94)
        static let sanctuaryGradientBottom = SwiftUI.Color(red: 0.86, green: 0.92, blue: 0.98)

        /// Near-flat wash for main tab shells (Home, Chaplain, You) — ABY / Alan Mind home surfaces.
        static let tabWashTop = SwiftUI.Color(red: 0.984, green: 0.982, blue: 0.992)
        static let tabWashMid = SwiftUI.Color(red: 0.976, green: 0.974, blue: 0.986)
        static let tabWashBottom = SwiftUI.Color(red: 0.970, green: 0.974, blue: 0.988)
        static let tabWashHint = SwiftUI.Color(red: 0.94, green: 0.90, blue: 0.97)

        static let brandGreenTop = SwiftUI.Color(red: 0.72, green: 0.88, blue: 0.34)
        static let brandGreenBottom = SwiftUI.Color(red: 0.58, green: 0.78, blue: 0.28)

        /// ABY guided write — Finish pill & prompt accent (Mobbin e3f97f9b)
        static let journalFinish = SwiftUI.Color(red: 0.75, green: 0.60, blue: 0.32)
        static let journalPromptAccent = SwiftUI.Color(red: 0.62, green: 0.48, blue: 0.24)

        static let gradientTop = sanctuaryGradientTop
        static let gradientMid = sanctuaryGradientMid
        static let gradientBottom = sanctuaryGradientBottom

        // Night sanctuary — Evening reflection twilight (Mobbin ABY / Close the day)
        /// Warm champagne off-white — primary CTA on evening sanctuary (Apple Starlight).
        static let starlight = SwiftUI.Color(red: 0.958, green: 0.938, blue: 0.902)

        static let eveningReflectionTop = SwiftUI.Color(red: 0.10, green: 0.09, blue: 0.18)
        static let eveningReflectionMid = SwiftUI.Color(red: 0.14, green: 0.12, blue: 0.24)
        static let eveningReflectionBottom = SwiftUI.Color(red: 0.08, green: 0.10, blue: 0.16)
        /// Opaque elevated surface — cards & composer on evening tabs (not alpha-stacked on safe area).
        static let eveningSurfaceElevated = SwiftUI.Color(red: 0.22, green: 0.20, blue: 0.32)
        static let nightGradientTop = eveningReflectionTop
        static let nightGradientMid = eveningReflectionMid
        static let nightGradientBottom = eveningReflectionBottom
        static let nightMeshIndigo = SwiftUI.Color(red: 0.14, green: 0.12, blue: 0.30)
        static let nightMeshPlum = SwiftUI.Color(red: 0.22, green: 0.14, blue: 0.36)
        static let nightMeshViolet = SwiftUI.Color(red: 0.18, green: 0.14, blue: 0.32)

        static let onboardingText = SwiftUI.Color.white
        static let onboardingTextSecondary = SwiftUI.Color.white.opacity(0.78)
        static let onboardingTextMuted = SwiftUI.Color.white.opacity(0.55)
        static let onboardingButtonText = SwiftUI.Color(red: 0.46, green: 0.50, blue: 0.76)
        static let glassFill = SwiftUI.Color.white.opacity(0.16)
        static let glassStroke = SwiftUI.Color.white.opacity(0.32)

        // Dark premium paywall — navy gradient, white type, glass cards
        static let paywallTextPrimary = SwiftUI.Color.white
        static let paywallTextSecondary = SwiftUI.Color.white.opacity(0.72)
        static let paywallTextTertiary = SwiftUI.Color.white.opacity(0.48)
        static let paywallGlassFill = SwiftUI.Color.white.opacity(0.08)
        static let paywallGlassStroke = SwiftUI.Color.white.opacity(0.14)
        static let paywallPlanFill = SwiftUI.Color.white.opacity(0.06)
        static let paywallPlanBorder = SwiftUI.Color.white.opacity(0.22)
        static let paywallCloseFill = SwiftUI.Color.white.opacity(0.12)
        static let paywallOrbPurple = nightMeshPlum
        static let paywallOrbBlue = nightMeshIndigo
        static let paywallOrbViolet = nightMeshViolet
    }

    /// Mobile typography scale — aligned to legibility guidelines (10pt floor, clear hierarchy).
    ///
    /// | Role | Token | Size | Weight |
    /// |------|-------|------|--------|
    /// | Large page title | `largeTitle` / `title` / `title2` | 34 / 28 / 24 | semibold |
    /// | Nav bar title | `navTitle` / `headline` | 16 / 17 | semibold |
    /// | Primary body | `body` | 15 | regular–medium |
    /// | List title / menu row | `listTitle` | 14 | medium |
    /// | Descriptive text | `listSubtitle` / `footnote` | 13 | regular |
    /// | Secondary descriptive | `caption` | 12 | regular |
    /// | Tertiary / timestamps | `tertiary` / `section` | 11 | regular–medium |
    /// | Tab bar floor | `tabLabel` | 11 | medium |
    /// | Primary CTA | `button` | 17 | semibold |
    /// | Secondary CTA | `buttonSecondary` | 14 | semibold |
    enum Font {
        // MARK: - Display & page titles (24–34pt, semibold)

        static var largeTitle: SwiftUI.Font { AppFont.font(size: 34, weight: .semibold) }
        static var title: SwiftUI.Font { AppFont.font(size: 28, weight: .semibold) }
        static var title2: SwiftUI.Font { AppFont.font(size: 24, weight: .semibold) }
        static var onboardingTitle: SwiftUI.Font { AppFont.font(size: 26, weight: .semibold) }

        // MARK: - Navigation & emphasis (14–17pt, semibold)

        static var navTitle: SwiftUI.Font { AppFont.font(size: 16, weight: .semibold) }
        static var headline: SwiftUI.Font { AppFont.font(size: 17, weight: .semibold) }

        // MARK: - Primary text (14–18pt, regular–medium)

        static var body: SwiftUI.Font { AppFont.font(size: 15, weight: .regular) }
        static var bodyMedium: SwiftUI.Font { AppFont.font(size: 15, weight: .medium) }
        static var bodySemibold: SwiftUI.Font { AppFont.font(size: 15, weight: .semibold) }
        static var callout: SwiftUI.Font { AppFont.font(size: 14, weight: .regular) }
        static var calloutMedium: SwiftUI.Font { AppFont.font(size: 14, weight: .medium) }
        static var calloutSemibold: SwiftUI.Font { AppFont.font(size: 14, weight: .semibold) }
        static var subheadline: SwiftUI.Font { AppFont.font(size: 15, weight: .regular) }

        // MARK: - List rows (title 14pt, subtitle 12–13pt)

        static var listTitle: SwiftUI.Font { calloutMedium }
        static var listSubtitle: SwiftUI.Font { footnote }

        // MARK: - Descriptive & tertiary (11–13pt, muted in palette)

        static var footnote: SwiftUI.Font { AppFont.font(size: 13, weight: .regular) }
        static var footnoteMedium: SwiftUI.Font { AppFont.font(size: 13, weight: .medium) }
        static var footnoteSemibold: SwiftUI.Font { AppFont.font(size: 13, weight: .semibold) }
        static var caption: SwiftUI.Font { AppFont.font(size: 12, weight: .regular) }
        static var captionMedium: SwiftUI.Font { AppFont.font(size: 12, weight: .medium) }
        static var captionSemibold: SwiftUI.Font { AppFont.font(size: 12, weight: .semibold) }
        static var tertiary: SwiftUI.Font { AppFont.font(size: 11, weight: .regular) }
        static var tertiaryMedium: SwiftUI.Font { AppFont.font(size: 11, weight: .medium) }
        static var section: SwiftUI.Font { AppFont.font(size: 11, weight: .medium) }

        // MARK: - Buttons (primary 15–17pt, secondary 13–14pt)

        static var button: SwiftUI.Font { AppFont.font(size: 17, weight: .semibold) }
        static var buttonSecondary: SwiftUI.Font { AppFont.font(size: 14, weight: .semibold) }
        static var buttonCompact: SwiftUI.Font { AppFont.font(size: 13, weight: .semibold) }

        // MARK: - Editorial serif (brand headlines — Instrument Serif)

        static var editorialTitle: SwiftUI.Font { AppFont.serif(size: 28) }
        static var editorialLargeTitle: SwiftUI.Font { AppFont.serif(size: 34) }
        static var editorialHeadline: SwiftUI.Font { AppFont.serif(size: 22) }
        static var editorialBody: SwiftUI.Font { AppFont.serif(size: 17) }
        static var editorialCallout: SwiftUI.Font { AppFont.serif(size: 16) }
        static var editorialAccent: SwiftUI.Font { AppFont.serif(size: 17, style: .italic) }
        static var editorialSubhead: SwiftUI.Font { AppFont.serif(size: 19) }
        static var editorialFootnote: SwiftUI.Font { AppFont.serif(size: 13) }

        // MARK: - Badges & minimum floor (10pt — tab bar is the legibility floor)

        static var micro: SwiftUI.Font { AppFont.font(size: 10, weight: .semibold) }
        static var microBold: SwiftUI.Font { AppFont.font(size: 10, weight: .semibold) }

        // MARK: - Display numerals

        static var displayLarge: SwiftUI.Font { AppFont.font(size: 52, weight: .bold) }
        static var displayHero: SwiftUI.Font { AppFont.font(size: 56, weight: .bold) }

        // MARK: - Paywall

        static var paywallBrand: SwiftUI.Font { AppFont.serif(size: 24) }
        static var paywallBadge: SwiftUI.Font { AppFont.font(size: 11, weight: .semibold) }
        static var paywallHeadline: SwiftUI.Font { AppFont.font(size: 26, weight: .semibold) }
        static var paywallFeature: SwiftUI.Font { AppFont.font(size: 16, weight: .medium) }
        static var paywallPlanLabel: SwiftUI.Font { AppFont.font(size: 13, weight: .regular) }
        static var paywallPrice: SwiftUI.Font { AppFont.font(size: 22, weight: .semibold) }
        static var paywallCTA: SwiftUI.Font { AppFont.font(size: 17, weight: .semibold) }
        static var paywallPromoBadge: SwiftUI.Font { AppFont.font(size: 10, weight: .semibold) }

        // MARK: - SF Symbols (system font — icons only)

        static let iconSmall = SwiftUI.Font.system(size: 13, weight: .medium)
        static let iconMedium = SwiftUI.Font.system(size: 15, weight: .medium)
        static let iconLarge = SwiftUI.Font.system(size: 16, weight: .medium)
        static let tabIcon = SwiftUI.Font.system(size: 18, weight: .regular)
        static let tabIconSelected = SwiftUI.Font.system(size: 18, weight: .semibold)
        static let tabLabel = SwiftUI.Font.system(size: 11, weight: .medium)
        static let tabLabelSelected = SwiftUI.Font.system(size: 11, weight: .semibold)
        static let heroIcon = SwiftUI.Font.system(size: 40, weight: .light)
        static let checkmark = SwiftUI.Font.system(size: 20, weight: .regular)
        static let checkmarkLarge = SwiftUI.Font.system(size: 24, weight: .semibold)
        static let emojiSmall = SwiftUI.Font.system(size: 11, weight: .regular)
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

// MARK: - ABY Journal onboarding (Mobbin ref)

enum ABYJournalOnboardingStyle: Equatable {
    case warmSunset
    case lavenderSky

    var buttonStyle: ABYJournalOnboardingButtonStyle {
        switch self {
        case .warmSunset: .black
        case .lavenderSky: .white
        }
    }
}

enum ABYJournalOnboardingButtonStyle {
    case black
    case white
}

/// ABY Journal education screens — soft off-white (Mobbin "Self-discovery through reflection" ref).
struct ABYJournalLightBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.94, green: 0.95, blue: 0.99),
                Color(red: 0.90, green: 0.93, blue: 0.98),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Blurred photo-mosaic tiles (Mobbin ABY welcome scrub screen).
private struct ABYJournalMosaicGrid: View {
    private let tileColors: [Color] = [
        Color(red: 0.82, green: 0.72, blue: 0.88),
        Color(red: 0.68, green: 0.78, blue: 0.92),
        Color(red: 0.95, green: 0.82, blue: 0.72),
        Color(red: 0.72, green: 0.86, blue: 0.80),
        Color(red: 0.90, green: 0.76, blue: 0.68),
        Color(red: 0.78, green: 0.70, blue: 0.94),
    ]

    var body: some View {
        GeometryReader { proxy in
            let columns = 5
            let tile = proxy.size.width / CGFloat(columns)
            let rows = Int(ceil(proxy.size.height / tile)) + 1

            VStack(spacing: 3) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<columns, id: \.self) { column in
                            let index = row * columns + column
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(tileColors[index % tileColors.count].opacity(0.72))
                                .frame(width: tile - 3, height: tile - 3)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .blur(radius: 26)
            .opacity(0.9)
        }
        .allowsHitTesting(false)
    }
}

/// ABY Journal welcome — blurred mosaic + frosted veil (Mobbin "Your Smarter Journal" ref).
struct ABYJournalWelcomeBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.97)
            ABYJournalMosaicGrid()

            welcomeBlob(Color(red: 0.74, green: 0.66, blue: 0.93), size: 280, blur: 70, x: -90, y: -120)
            welcomeBlob(Color(red: 0.58, green: 0.76, blue: 0.72), size: 240, blur: 65, x: 110, y: -40)
            welcomeBlob(Color(red: 0.98, green: 0.85, blue: 0.72), size: 260, blur: 68, x: -40, y: 280)
            welcomeBlob(Color(red: 0.56, green: 0.66, blue: 0.91), size: 220, blur: 60, x: 100, y: 360)

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.62)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func welcomeBlob(_ color: Color, size: CGFloat, blur: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(drift ? 0.38 : 0.26))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(x: x, y: y)
            .allowsHitTesting(false)
    }
}

/// Soft 3D cloud mark inspired by ABY splash / welcome logo.
struct SacredStartCloudMark: View {
    var size: CGFloat = 112

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.72, blue: 0.82),
                            Color(red: 0.62, green: 0.78, blue: 0.96),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.92, height: size * 0.58)
                .offset(y: size * 0.04)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.80, blue: 0.88),
                            Color(red: 0.48, green: 0.82, blue: 0.94),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.62, height: size * 0.44)
                .offset(x: -size * 0.18, y: -size * 0.08)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.90, green: 0.74, blue: 0.92),
                            Color(red: 0.40, green: 0.76, blue: 0.92),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.54, height: size * 0.40)
                .offset(x: size * 0.20, y: -size * 0.04)
        }
        .frame(width: size, height: size)
        .shadow(color: Color(red: 0.48, green: 0.62, blue: 0.90).opacity(0.22), radius: 18, y: 8)
    }
}

struct DevotionLockBrandMark: View {
    var size: CGFloat = 112
    var showsShadow = true

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [ABY.Color.brandGreenTop, ABY.Color.brandGreenBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            SacredStartCloudMark(size: size * 0.52)
                .offset(y: -size * 0.02)
        }
        .shadow(
            color: ABY.Color.brandGreenBottom.opacity(showsShadow ? 0.28 : 0),
            radius: size * 0.14,
            y: size * 0.05
        )
    }
}

/// Premium paywall — dark navy gradient with purple/blue glow orbs.
struct ABYPaywallBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ABY.Color.nightGradientTop,
                    ABY.Color.nightGradientMid,
                    ABY.Color.nightGradientBottom,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(ABY.Color.paywallOrbPurple.opacity(0.55))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -90, y: -200)

            Circle()
                .fill(ABY.Color.paywallOrbBlue.opacity(0.45))
                .frame(width: 240, height: 240)
                .blur(radius: 65)
                .offset(x: 130, y: -80)

            Circle()
                .fill(ABY.Color.paywallOrbViolet.opacity(0.35))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: -30, y: 340)
        }
        .ignoresSafeArea()
    }
}

struct ABYJournalOnboardingBackground: View {
    let style: ABYJournalOnboardingStyle
    @State private var drift = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )

            if style == .warmSunset {
                warmBlobs
            } else {
                lavenderBlobs
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private var gradientColors: [Color] {
        switch style {
        case .warmSunset:
            [ABY.Color.sunsetGradientTop, ABY.Color.sunsetGradientMid, ABY.Color.sunsetGradientBottom]
        case .lavenderSky:
            [
                ABY.Color.meshPeriwinkle,
                ABY.Color.meshSky,
                Color(red: 0.42, green: 0.56, blue: 0.86),
            ]
        }
    }

    @ViewBuilder
    private var warmBlobs: some View {
        journalBlob(ABY.Color.meshCoral, size: 320, blur: 80, x: -120, y: -200)
        journalBlob(ABY.Color.meshAmber, size: 280, blur: 70, x: 140, y: 60)
        journalBlob(ABY.Color.meshGold, size: 300, blur: 75, x: -60, y: 380)
    }

    @ViewBuilder
    private var lavenderBlobs: some View {
        journalBlob(ABY.Color.meshSky, size: 300, blur: 75, x: -100, y: -180)
        journalBlob(ABY.Color.meshPeriwinkle, size: 280, blur: 70, x: 120, y: 120)
        journalBlob(Color(red: 0.48, green: 0.68, blue: 0.92), size: 260, blur: 65, x: -80, y: 360)
    }

    private func journalBlob(_ color: Color, size: CGFloat, blur: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(drift ? 0.42 : 0.28))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(x: x, y: y)
            .allowsHitTesting(false)
    }
}

private struct ABYJournalOnboardingStyleKey: EnvironmentKey {
    static let defaultValue: ABYJournalOnboardingStyle = .warmSunset
}

extension EnvironmentValues {
    var abyJournalOnboardingStyle: ABYJournalOnboardingStyle {
        get { self[ABYJournalOnboardingStyleKey.self] }
        set { self[ABYJournalOnboardingStyleKey.self] = newValue }
    }
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

    enum Style {
        /// Full sanctuary gradient + mesh (immersive flows, Journal tab).
        case app
        /// Near-flat wash for main tab browsing surfaces.
        case tabShell
        case onboarding
    }

    var body: some View {
        ZStack {
            switch style {
            case .app:
                ABYCleanGradientBackground()
            case .tabShell:
                ABYFlatTabWashBackground()
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

/// Night sanctuary gradient / evening reflection dark UI.
enum SanctuaryAppearance {
    static let nightGradientEnabled = true
}

enum SanctuaryGradientMode: String, CaseIterable, Identifiable {
    case light
    case night

    static let storageKey = "sanctuaryGradientMode"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: "Light sanctuary"
        case .night: "Evening sanctuary"
        }
    }

    var subtitle: String {
        switch self {
        case .light: "Soft lavender, pink & sky blue mist"
        case .night: "Twilight plum & indigo — like Close the day"
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
        surfaceMuted: Color(red: 0.99, green: 0.95, blue: 0.90),
        surfaceElevated: ABY.Color.surface,
        background: ABY.Color.sanctuaryGradientTop,
        divider: ABY.Color.divider,
        track: ABY.Color.track,
        trackFill: ABY.Color.trackFill,
        buttonFill: ABY.Color.textPrimary,
        buttonForeground: Color.white,
        navBarFill: Color.white.opacity(0.80),
        navBarStrokeTop: Color.black.opacity(0.06),
        navBarStrokeBottom: Color.black.opacity(0.03),
        glassFill: ABY.Color.glassFill,
        glassStroke: ABY.Color.glassStroke,
        cardShadowOpacity: 0.04
    )

    /// Evening reflection — frosted cards on twilight plum (Mobbin ABY).
    static let night = SanctuaryPalette(
        textPrimary: Color.white.opacity(0.94),
        textSecondary: Color.white.opacity(0.72),
        textTertiary: Color.white.opacity(0.45),
        surface: Color.white.opacity(0.10),
        surfaceMuted: Color.white.opacity(0.07),
        surfaceElevated: Color.white.opacity(0.14),
        background: ABY.Color.eveningReflectionTop,
        divider: Color.white.opacity(0.10),
        track: Color.white.opacity(0.12),
        trackFill: Color.white,
        buttonFill: ABY.Color.starlight,
        buttonForeground: ABY.Color.eveningReflectionTop,
        navBarFill: Color.white.opacity(0.10),
        navBarStrokeTop: Color.white.opacity(0.18),
        navBarStrokeBottom: Color.white.opacity(0.08),
        glassFill: Color.white.opacity(0.08),
        glassStroke: Color.white.opacity(0.14),
        cardShadowOpacity: 0.22
    )

    static func forMode(_ mode: SanctuaryGradientMode) -> SanctuaryPalette {
        SanctuaryGradientMode.resolved(mode) == .night ? .night : .light
    }

    var isNight: Bool { self == .night }

    /// Grouped list / explore card — white in light, opaque plum in night.
    var cardFill: Color { isNight ? ABY.Color.eveningSurfaceElevated : .white }

    /// Floating composer pills and compact banners.
    var composerFill: Color { isNight ? ABY.Color.eveningSurfaceElevated : Color.white.opacity(0.96) }
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

/// Soft, near-flat background for Home / Chaplain / Profile tabs — white cards stay the focus.
struct ABYFlatTabWashBackground: View {
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue

    private var mode: SanctuaryGradientMode {
        SanctuaryGradientMode.resolved(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    var body: some View {
        Group {
            switch mode {
            case .light:
                lightWash
            case .night:
                nightWash
            }
        }
        .ignoresSafeArea()
    }

    private var lightWash: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ABY.Color.tabWashTop,
                    ABY.Color.tabWashMid,
                    ABY.Color.tabWashBottom,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [ABY.Color.tabWashHint.opacity(0.14), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 420
            )
            .allowsHitTesting(false)
        }
    }

    private var nightWash: some View {
        ABYEveningReflectionBackground()
    }
}

/// Shared twilight gradient — Evening reflection sheet & night sanctuary mode.
struct ABYEveningReflectionBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                ABY.Color.eveningReflectionTop,
                ABY.Color.eveningReflectionMid,
                ABY.Color.eveningReflectionBottom,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ABYWarmSanctuaryBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ABY.Color.sanctuaryGradientTop,
                    ABY.Color.sanctuaryGradientMid,
                    ABY.Color.sanctuaryGradientBottom,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            sanctuaryBlob(ABY.Color.meshLilac, size: 340, blur: 95, x: -110, y: -190)
            sanctuaryBlob(ABY.Color.meshLavender, size: 300, blur: 85, x: 130, y: 70)
            sanctuaryBlob(ABY.Color.meshSky, size: 280, blur: 80, x: -70, y: 360)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func sanctuaryBlob(_ color: Color, size: CGFloat, blur: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(drift ? 0.28 : 0.18))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(x: x, y: y)
            .allowsHitTesting(false)
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
        ABYWarmSanctuaryBackground()
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
            ABYEveningReflectionBackground()

            // Soft plum glow — pillowtalk / ABY evening refs
            nightBlob(ABY.Color.nightMeshPlum, size: 320, blur: 88, x: -90, y: -160)
            nightBlob(ABY.Color.nightMeshIndigo, size: 280, blur: 78, x: 110, y: 40)
            nightBlob(ABY.Color.nightMeshViolet, size: 240, blur: 72, x: -60, y: 300)

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
                        lineWidth: 0.5
                    )
            }
            .shadow(color: .black.opacity(palette.isNight ? 0.35 : 0.06), radius: 20, y: 8)
            .shadow(color: .black.opacity(palette.isNight ? 0.18 : 0.025), radius: 5, y: 2)
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
            .background(palette.cardFill)
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

    /// Tab roots sit above `ABYBackground` in `MainTabView` — keep stacks and scroll views transparent.
    func abyTabShell() -> some View {
        background(Color.clear)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct ABYOnboardingPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var style: ABYJournalOnboardingButtonStyle? = nil
    var isEnabled = true
    let action: () -> Void

    @Environment(\.abyJournalOnboardingStyle) private var journalStyle

    private var resolvedStyle: ABYJournalOnboardingButtonStyle {
        style ?? journalStyle.buttonStyle
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(ABY.Font.button)
                if let icon {
                    Image(systemName: icon)
                        .font(ABY.Font.iconSmall)
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isEnabled ? 0.10 : 0), radius: 12, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private var foregroundColor: Color {
        switch resolvedStyle {
        case .black: .white
        case .white: ABY.Color.meshPeriwinkle
        }
    }

    private var backgroundColor: Color {
        switch resolvedStyle {
        case .black: .black.opacity(isEnabled ? 1 : 0.55)
        case .white: .white.opacity(isEnabled ? 1 : 0.55)
        }
    }
}

struct ABYOnboardingProgressBar: View {
    let total: Int
    let current: Int
    var style: OnboardingSurface = .gradient(.warmSunset)

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(fillColor(for: index))
                    .frame(height: 3)
                    .animation(AppTheme.springSnappy, value: current)
            }
        }
    }

    private func fillColor(for index: Int) -> Color {
        let filled = index <= current
        switch style {
        case .welcome, .light, .plain:
            return filled ? ABY.Color.textPrimary : ABY.Color.track
        case .gradient:
            return filled ? Color.white : Color.white.opacity(0.28)
        }
    }
}

enum OnboardingSurface: Equatable {
    case welcome
    case light
    case plain
    case gradient(ABYJournalOnboardingStyle)
}

// MARK: - ABY Journal screen shell

struct ABYJournalBackground: View {
    let surface: OnboardingSurface

    var body: some View {
        switch surface {
        case .welcome:
            ABYJournalWelcomeBackground()
        case .light:
            ABYJournalLightBackground()
        case .plain:
            Color.white.ignoresSafeArea()
        case .gradient(let style):
            ABYJournalOnboardingBackground(style: style)
        }
    }
}

/// Crossfades between onboarding surfaces instead of hard-swapping gradients.
struct ABYJournalCrossfadeBackground: View {
    let surface: OnboardingSurface

    @State private var topSurface: OnboardingSurface
    @State private var bottomSurface: OnboardingSurface?
    @State private var topOpacity: Double = 1

    init(surface: OnboardingSurface) {
        self.surface = surface
        _topSurface = State(initialValue: surface)
    }

    var body: some View {
        ZStack {
            if let bottomSurface {
                ABYJournalBackground(surface: bottomSurface)
            }
            ABYJournalBackground(surface: topSurface)
                .opacity(topOpacity)
        }
        .onChange(of: surface) { _, newSurface in
            guard newSurface != topSurface else { return }
            bottomSurface = topSurface
            topSurface = newSurface
            topOpacity = 0
            withAnimation(AppTheme.onboardingBackgroundFade) {
                topOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.onboardingBackgroundFadeDuration + 0.05) {
                bottomSurface = nil
            }
        }
    }
}

struct ABYJournalScreen<Content: View>: View {
    let surface: OnboardingSurface
    @ViewBuilder let content: () -> Content

    private var journalStyle: ABYJournalOnboardingStyle {
        switch surface {
        case .welcome, .light, .plain: .warmSunset
        case .gradient(let style): style
        }
    }

    private var usesDarkChrome: Bool {
        if case .gradient = surface { return true }
        return false
    }

    var body: some View {
        ZStack {
            ABYJournalBackground(surface: surface)
            content()
        }
        .environment(\.onboardingSurface, surface)
        .environment(\.abyJournalOnboardingStyle, journalStyle)
        .preferredColorScheme(usesDarkChrome ? .dark : .light)
    }
}

struct ABYJournalCTAButton: View {
    let title: String
    var icon: String? = nil
    var isEnabled = true
    let action: () -> Void

    @Environment(\.onboardingSurface) private var surface

    var body: some View {
        switch surface {
        case .welcome, .light, .plain:
            ABYLightOnboardingPrimaryButton(title: title, isEnabled: isEnabled, action: action)
        case .gradient:
            ABYOnboardingPrimaryButton(title: title, icon: icon, isEnabled: isEnabled, action: action)
        }
    }
}

private struct OnboardingSurfaceKey: EnvironmentKey {
    static let defaultValue: OnboardingSurface = .gradient(.warmSunset)
}

extension EnvironmentValues {
    var onboardingSurface: OnboardingSurface {
        get { self[OnboardingSurfaceKey.self] }
        set { self[OnboardingSurfaceKey.self] = newValue }
    }
}

struct ABYLightOnboardingPrimaryButton: View {
    @Environment(\.sanctuaryPalette) private var palette

    let title: String
    var isEnabled = true
    let action: () -> Void

    private var fill: Color {
        palette.buttonFill.opacity(isEnabled ? 1 : 0.45)
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ABY.Font.button)
                .foregroundStyle(palette.buttonForeground.opacity(isEnabled ? 1 : 0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(fill)
                .clipShape(Capsule())
                .shadow(
                    color: .black.opacity(isEnabled ? (palette.isNight ? 0.28 : 0.08) : 0),
                    radius: palette.isNight ? 20 : 12,
                    y: palette.isNight ? 8 : 4
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
    }
}

/// Compact filled pill inside cards — e.g. "Start writing →" on the Prompts tab.
struct SanctuaryInlinePill: View {
    @Environment(\.sanctuaryPalette) private var palette

    let title: String
    var showsArrow: Bool = true

    private var labelColor: Color {
        palette.isNight ? ABY.Color.eveningReflectionTop : .white
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(ABY.Font.captionMedium)
            if showsArrow {
                Image(systemName: "arrow.right")
                    .font(ABY.Font.emojiSmall)
            }
        }
        .foregroundStyle(labelColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(palette.buttonFill)
        .clipShape(Capsule())
    }
}

struct ABYOnboardingHeadline: View {
    let eyebrow: String?
    let title: String
    let subtitle: String
    var alignment: TextAlignment = .center
    /// Use Instrument Serif for the title (default: on light education screens).
    var serifTitle: Bool?

    @Environment(\.onboardingSurface) private var surface

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String,
        alignment: TextAlignment = .center,
        serifTitle: Bool? = nil
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.alignment = alignment
        self.serifTitle = serifTitle
    }

    var body: some View {
        VStack(alignment: alignment == .leading ? .leading : .center, spacing: 10) {
            if let eyebrow {
                Text(eyebrow)
                    .font(ABY.Font.callout)
                    .foregroundStyle(subtitleColor)
                    .multilineTextAlignment(alignment)
            }
            Text(title)
                .font(titleFont)
                .foregroundStyle(titleColor)
                .multilineTextAlignment(alignment)
                .lineSpacing(usesSerifTitle ? 2 : 0)
            Text(subtitle)
                .font(ABY.Font.callout)
                .foregroundStyle(subtitleColor)
                .multilineTextAlignment(alignment)
                .lineSpacing(4)
        }
    }

    private var usesSerifTitle: Bool {
        if let serifTitle { return serifTitle }
        if case .light = surface { return true }
        return false
    }

    private var titleFont: Font {
        usesSerifTitle ? ABY.Font.editorialTitle : ABY.Font.onboardingTitle
    }

    private var titleColor: Color {
        isLightSurface ? ABY.Color.textPrimary : ABY.Color.onboardingText
    }

    private var subtitleColor: Color {
        isLightSurface ? ABY.Color.textSecondary : ABY.Color.onboardingTextSecondary
    }

    private var isLightSurface: Bool {
        switch surface {
        case .welcome, .light, .plain: true
        case .gradient: false
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
