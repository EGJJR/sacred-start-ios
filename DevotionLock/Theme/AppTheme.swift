//
//  AppTheme.swift
//  test1
//

import SwiftUI

enum AppTheme {
    static let background = DevotionTheme.background
    static let surface = DevotionTheme.surface
    static let surfaceElevated = DevotionTheme.surfaceGlow

    static let accentCyan = DevotionTheme.teal
    static let accentMagenta = DevotionTheme.sage
    static let accentGreen = DevotionTheme.sage

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.35)

    static let aiGradient = DevotionTheme.accentGradient

    static let springSnappy = Animation.spring(response: 0.38, dampingFraction: 0.82)
    static let springGentle = Animation.spring(response: 0.55, dampingFraction: 0.86)
    static let easeOut = Animation.easeOut(duration: 0.35)
}

enum DevotionTheme {
    static let background = Color(red: 0.04, green: 0.06, blue: 0.10)
    static let sage = Color(red: 0.48, green: 0.68, blue: 0.56)
    static let teal = Color(red: 0.36, green: 0.71, blue: 0.64)
    static let deepBlue = Color(red: 0.24, green: 0.35, blue: 0.50)
    static let warmCream = Color(red: 0.92, green: 0.88, blue: 0.82)
    static let surface = Color(red: 0.08, green: 0.11, blue: 0.16)
    static let surfaceGlow = Color.white.opacity(0.04)

    static let accentGradient = LinearGradient(
        colors: [sage, teal, deepBlue.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [sage.opacity(0.9), teal.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct DevotionBackground: View {
    var body: some View {
        ZStack {
            DevotionTheme.background.ignoresSafeArea()
            RadialGradient(
                colors: [
                    DevotionTheme.teal.opacity(0.12),
                    DevotionTheme.deepBlue.opacity(0.08),
                    .clear,
                ],
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
            RadialGradient(
                colors: [
                    DevotionTheme.sage.opacity(0.06),
                    .clear,
                ],
                center: .init(x: 0.8, y: 0.3),
                startRadius: 10,
                endRadius: 280
            )
            .ignoresSafeArea()
        }
    }
}

struct AppBackground: View {
    var body: some View {
        DevotionBackground()
    }
}

struct StatusTopBar: View {
    var batteryLevel: String = "96%"

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(DevotionTheme.sage)
                    .frame(width: 7, height: 7)
                Text(batteryLevel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.9))
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary.opacity(0.85))
                .rotationEffect(.degrees(90))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

struct DarkGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.72

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        Color.white.opacity(0.02),
                                        DevotionTheme.teal.opacity(0.04),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                    }
            }
    }
}

extension View {
    func darkGlass(cornerRadius: CGFloat = 16, opacity: Double = 0.72) -> some View {
        modifier(DarkGlassModifier(cornerRadius: cornerRadius, opacity: opacity))
    }

    func devotionFrostedCard() -> some View {
        darkGlass()
    }
}
