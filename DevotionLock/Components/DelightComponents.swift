//
//  DelightComponents.swift
//  DevotionLock
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum DevotionHaptics {
    static func light() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func medium() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    /// Soft tick for live speech partials — use sparingly.
    static func soft() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.55)
        #endif
    }
}

struct ConfettiView: View {
    var isActive: Bool
    var pieceCount: Int = 48

    @State private var pieces: [ConfettiPiece] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard isActive else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                for piece in pieces {
                    let y = (piece.y + CGFloat(time) * piece.speed).truncatingRemainder(dividingBy: size.height + 40) - 20
                    let x = piece.x + sin(time * piece.wobble + piece.phase) * 12
                    var rect = CGRect(x: x, y: y, width: piece.width, height: piece.height)
                    rect = rect.offsetBy(dx: -piece.width / 2, dy: -piece.height / 2)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(piece.color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { regenerate(in: CGSize(width: 390, height: 844)) }
        .onChange(of: isActive) { _, active in
            if active { regenerate(in: CGSize(width: 390, height: 844)) }
        }
    }

    private func regenerate(in size: CGSize) {
        let colors: [Color] = [
            ABY.Color.pillPink, ABY.Color.pillOrange, ABY.Color.pillTeal,
            ABY.Color.pillPurple, ABY.Color.orbSage, ABY.Color.accentDot,
        ]
        pieces = (0..<pieceCount).map { index in
            ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -size.height...0),
                width: CGFloat.random(in: 5...9),
                height: CGFloat.random(in: 8...14),
                speed: CGFloat.random(in: 55...110),
                wobble: Double.random(in: 1.2...2.4),
                phase: Double(index) * 0.7,
                color: colors[index % colors.count]
            )
        }
    }
}

private struct ConfettiPiece {
    let x, y, width, height, speed: CGFloat
    let wobble, phase: Double
    let color: Color
}

struct PiVoiceHillsView: View {
    var intensity: CGFloat = 1.0

    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue
    @State private var drift = false

    private var isNight: Bool {
        SanctuaryGradientMode.resolved(SanctuaryGradientMode(rawValue: modeRaw) ?? .light) == .night
    }

    private var hillColors: [Color] {
        if isNight {
            return [
                ABY.Color.nightMeshIndigo.opacity(0.28),
                ABY.Color.nightMeshPlum.opacity(0.36),
                ABY.Color.nightMeshViolet.opacity(0.44),
                Color(red: 0.16, green: 0.20, blue: 0.42).opacity(0.55),
            ]
        }
        return [
            ABY.Color.orbTeal.opacity(0.18),
            ABY.Color.orbSage.opacity(0.22),
            ABY.Color.pillTeal.opacity(0.28),
            ABY.Color.orbTeal.opacity(0.34),
        ]
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                ForEach(Array(hillColors.enumerated()), id: \.offset) { index, color in
                    hillLayer(
                        width: w,
                        height: h,
                        index: index,
                        color: color.opacity(intensity),
                        lift: 0.10 + CGFloat(index) * 0.05
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func hillLayer(width: CGFloat, height: CGFloat, index: Int, color: Color, lift: CGFloat) -> some View {
        let amplitude = (8 + CGFloat(index) * 4) * intensity
        let offset = drift ? amplitude : -amplitude
        return PiHillShape(lift: lift)
            .fill(color)
            .frame(height: height * (0.38 + CGFloat(index) * 0.045))
            .offset(y: offset)
    }
}

private struct PiHillShape: Shape {
    var lift: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h))
        path.addCurve(
            to: CGPoint(x: w, y: h),
            control1: CGPoint(x: w * 0.25, y: h * (1 - lift)),
            control2: CGPoint(x: w * 0.72, y: h * (1 - lift * 0.85))
        )
        path.addLine(to: CGPoint(x: w, y: h + 40))
        path.addLine(to: CGPoint(x: 0, y: h + 40))
        path.closeSubpath()
        return path
    }
}

struct ShepherdRefreshIndicator: View {
    let progress: CGFloat

    var body: some View {
        VStack(spacing: 10) {
            ShepherdLogoView(size: 44, lightBackdrop: true)
            OnboardingProgressRing(progress: progress, style: .light)
        }
        .padding(.top, 8)
    }
}

struct SoftLightFieldView: View {
    var intensity: CGFloat = 1

    @State private var dots: [SoftLightDot] = []

    private let palette: [Color] = [
        ABY.Color.pillTeal.opacity(0.85),
        ABY.Color.pillPurple.opacity(0.8),
        ABY.Color.orbSage.opacity(0.75),
        ABY.Color.meshLilac.opacity(0.7),
        ABY.Color.meshPeriwinkle.opacity(0.65),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for dot in dots {
                    let pulse = 0.55 + 0.45 * sin(time * dot.speed + dot.phase)
                    let x = dot.x * size.width
                    let y = dot.y * size.height
                    let radius = dot.radius * pulse * intensity
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    let color = palette[dot.colorIndex % palette.count]
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(color.opacity(dot.opacity * pulse))
                    )
                    context.fill(
                        Path(ellipseIn: rect.insetBy(dx: -radius * 0.6, dy: -radius * 0.6)),
                        with: .color(color.opacity(dot.opacity * 0.18 * pulse))
                    )
                }
            }
        }
        .onAppear { regenerateDots() }
    }

    private func regenerateDots() {
        var generated: [SoftLightDot] = []
        let columns = 13
        let rows = 18
        var id = 0
        for row in 0..<rows {
            for col in 0..<columns {
                let stagger = row.isMultiple(of: 2) ? 0.5 / CGFloat(columns) : 0
                let nx = (CGFloat(col) + 0.5) / CGFloat(columns) + stagger
                let ny = (CGFloat(row) + 0.5) / CGFloat(rows)
                let centerPull = 1 - hypot(nx - 0.5, ny - 0.46) * 1.35
                guard centerPull > 0.05 else { continue }
                let prominence = max(0.2, centerPull)
                generated.append(
                    SoftLightDot(
                        id: id,
                        x: nx,
                        y: ny,
                        phase: Double.random(in: 0...(Double.pi * 2)),
                        speed: Double.random(in: 0.7...1.6),
                        radius: CGFloat.random(in: 1.4...3.8) * prominence + 0.8,
                        opacity: Double.random(in: 0.25...0.75) * Double(prominence),
                        colorIndex: Int.random(in: 0..<palette.count)
                    )
                )
                id += 1
            }
        }
        dots = generated
    }
}

private struct SoftLightDot: Identifiable {
    let id: Int
    let x, y: CGFloat
    let phase, speed: Double
    let radius: CGFloat
    let opacity: Double
    let colorIndex: Int
}

struct SanctuarySplashBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.90, blue: 0.97),
                    Color(red: 0.95, green: 0.92, blue: 0.98),
                    Color(red: 0.94, green: 0.91, blue: 0.97),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [
                    ABY.Color.meshLilac.opacity(0.22),
                    Color.clear,
                ],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
        }
    }
}
