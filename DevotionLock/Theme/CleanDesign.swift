//
//  CleanDesign.swift
//  DevotionLock
//
//  Design experiment: clean-app visual system (one accent, whitespace,
//  one radius, 2–3 type sizes, Open Runde, Solar Duotone).
//

import SwiftUI
import UIKit

enum CleanExperiment {
    static let storageKey = "debugCleanHomeDesignEnabled"

    /// On this experiment branch the clean shell is the default experience.
    /// Flip off in Profile → Developer to compare against the production home.
    static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: storageKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: storageKey)
    }
}

enum CleanDesign {
    /// Single shared corner radius for cards and icon wells.
    static let radius: CGFloat = 22

    enum Color {
        /// Sacred green — sole brand accent.
        static let accent = SwiftUI.Color(red: 0.18, green: 0.36, blue: 0.28)
        /// Soft tint of the accent (icon wells, tip chip, selected nav blob).
        static let accentSoft = SwiftUI.Color(red: 0.18, green: 0.36, blue: 0.28).opacity(0.14)
        static let accentMuted = SwiftUI.Color(red: 0.18, green: 0.36, blue: 0.28).opacity(0.55)

        static let background = SwiftUI.Color(red: 0.965, green: 0.962, blue: 0.955)
        static let surface = SwiftUI.Color.white
        static let textPrimary = SwiftUI.Color(red: 0.14, green: 0.22, blue: 0.18)
        static let textSecondary = SwiftUI.Color(red: 0.42, green: 0.48, blue: 0.44)
        static let textTertiary = SwiftUI.Color(red: 0.58, green: 0.62, blue: 0.58)

        /// Semantic exception for streak flame only — not a second brand accent.
        static let flame = SwiftUI.Color(red: 0.95, green: 0.55, blue: 0.22)
        static let flameSoft = SwiftUI.Color(red: 0.95, green: 0.55, blue: 0.22).opacity(0.18)
    }

    /// Two–three type sizes only (Open Runde).
    enum Font {
        /// Greeting / streak hero number.
        static var display: SwiftUI.Font { CleanFont.font(size: 28, weight: .semibold) }
        /// Card titles, tip body, streak subtitle.
        static var title: SwiftUI.Font { CleanFont.font(size: 17, weight: .semibold) }
        /// Status line, card descriptions, nav labels.
        static var body: SwiftUI.Font { CleanFont.font(size: 14, weight: .regular) }
        static var bodyMedium: SwiftUI.Font { CleanFont.font(size: 14, weight: .medium) }
        /// Large streak metric.
        static var metric: SwiftUI.Font { CleanFont.font(size: 64, weight: .bold) }
    }

    enum Spacing {
        static let screen: CGFloat = 24
        static let grid: CGFloat = 14
        static let section: CGFloat = 28
    }

    /// Injected into `sanctuaryPalette` so Chaplain, Profile, Journal, and sheets
    /// pick up Clean colors without per-screen rewrites.
    static let palette = SanctuaryPalette(
        textPrimary: Color.textPrimary,
        textSecondary: Color.textSecondary,
        textTertiary: Color.textTertiary,
        surface: Color.surface,
        surfaceMuted: Color.accentSoft,
        surfaceElevated: Color.surface,
        background: Color.background,
        divider: Color.accent.opacity(0.10),
        track: Color.accent.opacity(0.12),
        trackFill: Color.accent,
        buttonFill: Color.accent,
        buttonForeground: .white,
        navBarFill: Color.surface.opacity(0.92),
        navBarStrokeTop: Color.accent.opacity(0.06),
        navBarStrokeBottom: Color.accent.opacity(0.03),
        glassFill: Color.surface.opacity(0.88),
        glassStroke: Color.accent.opacity(0.10),
        cardShadowOpacity: 0.05
    )
}

/// Open Runde — geometric rounded sans for the Clean experiment.
enum CleanFont {
    enum Weight {
        case regular
        case medium
        case semibold
        case bold

        var postScriptName: String {
            switch self {
            case .regular: "OpenRunde-Regular"
            case .medium: "OpenRunde-Medium"
            case .semibold: "OpenRunde-Semibold"
            case .bold: "OpenRunde-Bold"
            }
        }

        var systemWeight: Font.Weight {
            switch self {
            case .regular: .regular
            case .medium: .medium
            case .semibold: .semibold
            case .bold: .bold
            }
        }
    }

    static func font(size: CGFloat, weight: Weight = .regular) -> Font {
        if UIFont(name: weight.postScriptName, size: size) != nil {
            return .custom(weight.postScriptName, size: size)
        }
        // Rounded system fallback if Open Runde failed to register.
        return .system(size: size, weight: weight.systemWeight, design: .rounded)
    }
}
