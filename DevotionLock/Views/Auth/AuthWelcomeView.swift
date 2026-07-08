//
//  AuthWelcomeView.swift
//  DevotionLock
//
//  Pool-style welcome: sanctuary gradient + floating card with value carousel.
//

import SwiftUI

/// First impression — quiet white screen with the quatrefoil mark alone
/// (ABY Journal entry pattern), then a blur-dissolve into the welcome card.
struct AuthHeroView: View {
    var onNext: () -> Void

    @State private var markRevealed = false
    @State private var textRevealed = false
    @State private var buttonRevealed = false
    @State private var breathing = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                DevotionLockBrandMark(size: 128, showsShadow: true)
                    .scaleEffect(breathing ? 1.03 : 1.0)
                    .blurReveal(markRevealed, blurRadius: 18, scale: 1.06)

                VStack(spacing: 8) {
                    Text("Sacred Start")
                        .font(ABY.Font.editorialLargeTitle)
                        .foregroundStyle(ABY.Color.textPrimary)
                    Text("Begin each day in Scripture")
                        .font(ABY.Font.callout)
                        .foregroundStyle(ABY.Color.textSecondary)
                }
                .padding(.top, 36)
                .blurReveal(textRevealed, blurRadius: 8, scale: 1.02)

                Spacer()

                AuthPrimaryCapsuleButton(title: "Continue", action: onNext)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 28)
                    .blurReveal(buttonRevealed, blurRadius: 6, scale: 1.01)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(AppTheme.springGentle.delay(0.1)) { markRevealed = true }
            withAnimation(AppTheme.springGentle.delay(0.28)) { textRevealed = true }
            withAnimation(AppTheme.springGentle.delay(0.44)) { buttonRevealed = true }
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true).delay(0.6)) {
                breathing = true
            }
        }
    }
}

struct AuthWelcomeView: View {
    var onContinue: () -> Void
    var onSignIn: () -> Void

    @State private var carouselIndex = 0

    private let slides: [OnboardingValueSlide] = [
        OnboardingValueSlide(
            title: "Begin each morning in Scripture",
            subtitle: "A guided devotion with mood, gratitude, and today's verse.",
            systemImage: "sun.horizon.fill"
        ),
        OnboardingValueSlide(
            title: "Journal what matters",
            subtitle: "Capture reflections and conversations with your Chaplain.",
            systemImage: "book.closed.fill"
        ),
    ]

    var body: some View {
        ZStack {
            ABYWarmSanctuaryBackground()

            OnboardingFloatingCard {
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            OnboardingValueCarousel(slides: slides, selectedIndex: $carouselIndex)
                                .padding(.top, 24)
                        }
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 12)
                    }

                    VStack(spacing: 12) {
                        AuthPrimaryCapsuleButton(title: "Sign up", action: onContinue)

                        AuthSecondaryCapsuleButton(title: "Sign in", action: onSignIn)

                        AuthTermsFooter()
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 28)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    AuthWelcomeView(onContinue: {}, onSignIn: {})
        .environment(\.authManager, AuthManager.shared)
}
