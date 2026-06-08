//
//  AmbientOrb.swift
//  test1
//

import SwiftUI

enum OrbPalette {
    case vibrant
    case devotion

    var ringColors: (Color, Color) {
        switch self {
        case .vibrant:
            (AppTheme.accentCyan, AppTheme.accentMagenta)
        case .devotion:
            (DevotionTheme.teal, DevotionTheme.sage)
        }
    }

    var glowColors: (primary: Color, secondary: Color, highlight: Color) {
        switch self {
        case .vibrant:
            (AppTheme.accentCyan, AppTheme.accentMagenta, Color.white.opacity(0.15))
        case .devotion:
            (DevotionTheme.teal, DevotionTheme.sage, DevotionTheme.deepBlue.opacity(0.2))
        }
    }

    var coreColors: [Color] {
        switch self {
        case .vibrant:
            [Color.white.opacity(0.9), AppTheme.accentCyan.opacity(0.4), AppTheme.accentMagenta.opacity(0.2)]
        case .devotion:
            [Color.white.opacity(0.7), DevotionTheme.teal.opacity(0.35), DevotionTheme.sage.opacity(0.2)]
        }
    }

    var breatheDuration: Double {
        switch self {
        case .vibrant: 2.8
        case .devotion: 3.5
        }
    }
}

struct AmbientOrb: View {
    var size: CGFloat = 220
    var intensity: CGFloat = 1.0
    var palette: OrbPalette = .vibrant

    @State private var breathe = false
    @State private var drift = false

    var body: some View {
        let (ringA, ringB) = palette.ringColors

        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                ringA.opacity(0.3 - Double(ring) * 0.08),
                                ringB.opacity(0.25 - Double(ring) * 0.06),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(
                        width: size * (breathe ? 1.12 + CGFloat(ring) * 0.14 : 1.0 + CGFloat(ring) * 0.12),
                        height: size * (breathe ? 1.12 + CGFloat(ring) * 0.14 : 1.0 + CGFloat(ring) * 0.12)
                    )
                    .opacity(breathe ? 0.6 - Double(ring) * 0.15 : 0.35 - Double(ring) * 0.1)
                    .animation(
                        .easeInOut(duration: palette.breatheDuration + Double(ring) * 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(ring) * 0.3),
                        value: breathe
                    )
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: {
                            let g = palette.glowColors
                            return [
                                g.primary.opacity(0.55 * intensity),
                                g.secondary.opacity(0.45 * intensity),
                                g.highlight.opacity(intensity),
                                Color.clear,
                            ]
                        }(),
                        center: drift ? .init(x: 0.35, y: 0.3) : .init(x: 0.65, y: 0.7),
                        startRadius: 0,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 0.75, height: size * 0.75)
                .blur(radius: 28)
                .scaleEffect(breathe ? 1.06 : 0.94)

            Circle()
                .fill(
                    RadialGradient(
                        colors: palette.coreColors,
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.22
                    )
                )
                .frame(width: size * 0.28, height: size * 0.28)
                .blur(radius: 2)
                .scaleEffect(breathe ? 1.04 : 0.96)
        }
        .onAppear {
            breathe = true
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

struct DevotionOrb: View {
    var size: CGFloat = 180
    var intensity: CGFloat = 0.85

    var body: some View {
        ZStack {
            AmbientOrb(size: size, intensity: intensity, palette: .devotion)
            LowPolyDove()
                .frame(width: size * 0.45, height: size * 0.45)
                .opacity(0.4)
        }
    }
}

struct FloatingParticles: View {
    var count: Int = 18
    var tint: Color = .white
    var maxOpacity: Double = 0.08

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let seed = Double(i) * 1.7
                    let x = (sin(t * 0.3 + seed) * 0.5 + 0.5) * size.width
                    let y = (cos(t * 0.25 + seed * 1.3) * 0.5 + 0.5) * size.height
                    let alpha = maxOpacity + sin(t + seed) * (maxOpacity * 0.5)
                    let r: CGFloat = 1.5 + CGFloat(sin(t * 0.5 + seed)) * 0.8
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct DevotionParticles: View {
    var body: some View {
        FloatingParticles(count: 10, tint: DevotionTheme.sage, maxOpacity: 0.06)
    }
}
