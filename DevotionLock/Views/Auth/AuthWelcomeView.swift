//
//  AuthWelcomeView.swift
//  DevotionLock
//
//  Pool-style welcome: sanctuary gradient + floating card with value carousel.
//

import SwiftUI

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
                        AuthPrimaryCapsuleButton(title: "Continue with email", action: onContinue)

                        Button(action: onSignIn) {
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .foregroundStyle(ABY.Color.textSecondary)
                                Text("Sign in")
                                    .font(ABY.Font.footnoteSemibold)
                                    .underline()
                                    .foregroundStyle(ABY.Color.textPrimary)
                            }
                            .font(ABY.Font.footnote)
                        }
                        .buttonStyle(.plain)

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
