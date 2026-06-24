//
//  AuthFlowView.swift
//  DevotionLock
//

import SwiftUI

private enum AuthStep: Equatable {
    case welcome
    case authenticate(AuthIntent)
}

struct AuthFlowView: View {
    @State private var step: AuthStep = .welcome

    var body: some View {
        Group {
            switch step {
            case .welcome:
                AuthWelcomeView(
                    onContinue: {
                        withAnimation(AppTheme.onboardingStepOut) {
                            step = .authenticate(.signUp)
                        }
                    },
                    onSignIn: {
                        withAnimation(AppTheme.onboardingStepOut) {
                            step = .authenticate(.signIn)
                        }
                    }
                )
                .transition(.opacity.combined(with: .offset(y: 6)))

            case .authenticate(let intent):
                AuthSocialView(intent: intent) {
                    withAnimation(AppTheme.onboardingStepOut) {
                        step = .welcome
                    }
                }
                .transition(.opacity.combined(with: .offset(y: 6)))
            }
        }
        .animation(AppTheme.onboardingStepIn, value: step)
    }
}

#Preview {
    AuthFlowView()
        .environment(\.authManager, AuthManager.shared)
}
