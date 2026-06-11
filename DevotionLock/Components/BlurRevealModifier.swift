//
//  BlurRevealModifier.swift
//  DevotionLock
//

import SwiftUI

/// ABY-style blur-to-sharp reveal (extracted from AppLoadingView).
struct BlurRevealModifier: ViewModifier {
    let isRevealed: Bool
    var blurRadius: CGFloat = 16
    var scale: CGFloat = 1.03

    func body(content: Content) -> some View {
        content
            .blur(radius: isRevealed ? 0 : blurRadius)
            .opacity(isRevealed ? 1 : 0)
            .scaleEffect(isRevealed ? 1 : scale)
    }
}

extension View {
    func blurReveal(
        _ isRevealed: Bool,
        blurRadius: CGFloat = 16,
        scale: CGFloat = 1.03
    ) -> some View {
        modifier(BlurRevealModifier(isRevealed: isRevealed, blurRadius: blurRadius, scale: scale))
    }
}

/// Staggered appear for list items (cards, verses).
struct BlurRevealOnAppear: ViewModifier {
    let index: Int
    var stagger: Double = 0.06
    var delay: Double = 0

    @State private var revealed = false

    func body(content: Content) -> some View {
        content
            .blurReveal(revealed, blurRadius: 12, scale: 1.02)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(delay + Double(index) * stagger)) {
                    revealed = true
                }
            }
    }
}

extension View {
    func blurRevealOnAppear(index: Int, stagger: Double = 0.06, delay: Double = 0) -> some View {
        modifier(BlurRevealOnAppear(index: index, stagger: stagger, delay: delay))
    }
}
