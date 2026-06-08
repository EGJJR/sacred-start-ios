//
//  AuthWelcomeView.swift
//  DevotionLock
//

import SwiftUI

struct AuthWelcomeView: View {
    var onContinue: () -> Void
    var onSignIn: () -> Void

    @State private var appeared = false

    var body: some View {
        AuthMeshScreen {
            VStack(spacing: 0) {
                Spacer(minLength: 32)

                VStack(spacing: 28) {
                    AuthSunriseHero()
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.92)

                    VStack(spacing: 10) {
                        Text("Begin each day\nwith intention.")
                            .font(ABY.Font.largeTitle)
                            .foregroundStyle(ABY.Color.onboardingText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)

                        Text("Morning devotion, gentle guidance, and prayer with others.")
                            .font(ABY.Font.callout)
                            .foregroundStyle(ABY.Color.onboardingTextSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 12)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                }
                .padding(.horizontal, ABY.Spacing.screen)

                Spacer()

                AuthBottomPanel {
                    AuthPrimaryCapsuleButton(title: "Get started", action: onContinue)

                    AuthSecondaryTextLink(
                        prompt: "Already have an account?",
                        actionLabel: "Log in",
                        action: onSignIn
                    )

                    AuthTermsFooter()
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(AppTheme.springGentle.delay(0.08)) { appeared = true }
        }
    }
}

#Preview {
    AuthWelcomeView(onContinue: {}, onSignIn: {})
}
