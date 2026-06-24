//
//  SacredHeartComponents.swift
//  DevotionLock
//
//  Sacred Heart vector mark for onboarding + in-app branding.
//

import SwiftUI

// MARK: - Vector brand mark

/// Simplified Sacred Heart — heart, thorns, cross, rays. Sized for icon + onboarding.
struct SacredHeartIconMark: View {
    var size: CGFloat = 112
    var showsBackground = true
    var showsShadow = true

    private let heartRed = Color(red: 0.78, green: 0.18, blue: 0.22)
    private let gold = Color(red: 0.92, green: 0.76, blue: 0.38)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.93)

    var body: some View {
        ZStack {
            if showsBackground {
                RoundedRectangle(cornerRadius: size * 0.224, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.96, green: 0.93, blue: 0.98), cream],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            SacredHeartIconGlyph()
                .padding(size * 0.14)
        }
        .frame(width: size, height: size)
        .shadow(
            color: heartRed.opacity(showsShadow ? 0.22 : 0),
            radius: size * 0.1,
            y: size * 0.04
        )
    }
}

/// Core glyph — layout proportional to container (iOS icon safe zone).
private struct SacredHeartIconGlyph: View {
    private let heartRed = Color(red: 0.78, green: 0.18, blue: 0.22)
    private let gold = Color(red: 0.92, green: 0.76, blue: 0.38)
    private let thorn = Color(red: 0.42, green: 0.28, blue: 0.20)

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    Capsule()
                        .fill(gold.opacity(0.5))
                        .frame(width: max(1, side * 0.022), height: side * 0.38)
                        .position(
                            x: center.x + cos(angle(for: index, count: 12)) * side * 0.01,
                            y: center.y + sin(angle(for: index, count: 12)) * side * 0.01
                        )
                        .offset(y: -side * 0.19)
                        .rotationEffect(.degrees(Double(index) * 30))
                }

                Ellipse()
                    .stroke(thorn.opacity(0.85), style: StrokeStyle(lineWidth: side * 0.014, dash: [side * 0.02, side * 0.028]))
                    .frame(width: side * 0.58, height: side * 0.48)
                    .position(center)

                Image(systemName: "heart.fill")
                    .font(.system(size: side * 0.42, weight: .semibold))
                    .foregroundStyle(heartRed)
                    .shadow(color: heartRed.opacity(0.3), radius: side * 0.02, y: side * 0.01)
                    .position(x: center.x, y: center.y + side * 0.02)

                Image(systemName: "plus")
                    .font(.system(size: side * 0.09, weight: .bold))
                    .foregroundStyle(gold)
                    .position(x: center.x, y: center.y - side * 0.28)

                Image(systemName: "flame.fill")
                    .font(.system(size: side * 0.1, weight: .regular))
                    .foregroundStyle(Color(red: 0.98, green: 0.62, blue: 0.22))
                    .position(x: center.x, y: center.y - side * 0.38)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func angle(for index: Int, count: Int) -> CGFloat {
        CGFloat(index) / CGFloat(count) * .pi * 2 - .pi / 2
    }
}

#Preview("Icon mark") {
    VStack(spacing: 24) {
        SacredHeartIconMark(size: 120)
        SacredHeartIconMark(size: 60)
        SacredHeartIconMark(size: 180)
    }
    .padding()
    .background(ABYWarmSanctuaryBackground())
}
