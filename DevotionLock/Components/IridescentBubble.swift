//
//  IridescentBubble.swift
//  DevotionLock
//
//  Restrained "liquid glass" iridescent sheen for the active tab jewel.
//
//  Design note: DESIGN-PHILOSOPHY reserves saturated gradients — the tab bar gets
//  exactly one "jewel." Historically that was only the Sacred Orb; this sheen extends
//  the same idea to the active tab as a soft, slow-drifting holographic tint. It echoes
//  the Sacred Orb palette (teal / sky / periwinkle / sage) at low opacity rather than a
//  neon rainbow, so it reads as a specular highlight on glass, not a saturated fill.
//

import SwiftUI

/// A holographic, slowly rotating gradient meant to be clipped to a shape (Circle for
/// the spec's "bubble", Capsule for the tab highlight) and layered over a light glass
/// surface. Keep `intensity` low; this is a sheen, not a paint fill.
struct IridescentBubble: View {
    /// Enables the slow drift. Disabled automatically under Reduce Motion.
    var animates: Bool = true
    /// Overall opacity of the iridescent wash. Nav-bar sheen stays subtle (~0.3).
    var intensity: Double = 0.30
    /// Rotation period, seconds. Longer = calmer.
    var period: Double = 16

    @State private var phase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Calm iridescent stops — first and last match so rotation loops seamlessly.
    private static let stops: [Color] = [
        ABY.Color.orbTeal,
        ABY.Color.meshSky,
        ABY.Color.meshPeriwinkle,
        ABY.Color.pillPurple,
        ABY.Color.orbSage,
        ABY.Color.orbTeal,
    ]

    var body: some View {
        GeometryReader { geo in
            let dim = min(geo.size.width, geo.size.height)

            AngularGradient(colors: Self.stops, center: .center)
                .rotationEffect(.degrees(phase))
                .blur(radius: dim * 0.16)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .opacity(intensity)
        .allowsHitTesting(false)
        .onAppear(perform: startDriftIfNeeded)
    }

    private func startDriftIfNeeded() {
        guard animates, !reduceMotion else { return }
        withAnimation(.linear(duration: period).repeatForever(autoreverses: false)) {
            phase = 360
        }
    }
}

#Preview("Bubble on dark") {
    ZStack {
        Color.black
        IridescentBubble(intensity: 0.7)
            .frame(width: 120, height: 120)
            .clipShape(Circle())
        Image(systemName: "bell.fill")
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(.white)
    }
}

#Preview("Capsule sheen on light") {
    ZStack {
        Color(white: 0.96)
        ZStack {
            Capsule().fill(.white)
            IridescentBubble()
                .clipShape(Capsule())
            Capsule().strokeBorder(.black.opacity(0.06), lineWidth: 0.5)
        }
        .frame(width: 120, height: 48)
    }
}
