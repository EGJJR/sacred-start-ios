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
            .allowsHitTesting(isRevealed)
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
            .blurReveal(revealed, blurRadius: 4, scale: 1.004)
            .onAppear {
                withAnimation(.easeOut(duration: 0.32).delay(delay + Double(index) * stagger)) {
                    revealed = true
                }
            }
    }
}

/// Soft fade + drift for onboarding / auth step changes (no heavy blur).
struct OnboardingStepRevealModifier: ViewModifier {
    let isRevealed: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed ? 0 : 6)
    }
}

extension View {
    func blurRevealOnAppear(index: Int, stagger: Double = 0.06, delay: Double = 0) -> some View {
        modifier(BlurRevealOnAppear(index: index, stagger: stagger, delay: delay))
    }

    func onboardingStepReveal(_ isRevealed: Bool) -> some View {
        modifier(OnboardingStepRevealModifier(isRevealed: isRevealed))
    }
}

enum OnboardingStepTransition {
    static func animateChange(
        revealed: Binding<Bool>,
        applyChange: @escaping () -> Void
    ) {
        withAnimation(AppTheme.onboardingStepOut) {
            revealed.wrappedValue = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.onboardingStepTransitionDelay) {
            applyChange()
            withAnimation(AppTheme.onboardingStepIn) {
                revealed.wrappedValue = true
            }
        }
    }
}
