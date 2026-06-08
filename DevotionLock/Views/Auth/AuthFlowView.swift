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
                        withAnimation(AppTheme.springSnappy) {
                            step = .authenticate(.signUp)
                        }
                    },
                    onSignIn: {
                        withAnimation(AppTheme.springSnappy) {
                            step = .authenticate(.signIn)
                        }
                    }
                )
                .transition(.opacity.combined(with: .offset(y: 8)))

            case .authenticate(let intent):
                AuthSocialView(intent: intent) {
                    withAnimation(AppTheme.springSnappy) {
                        step = .welcome
                    }
                }
                .transition(.opacity.combined(with: .offset(x: 20)))
            }
        }
        .animation(AppTheme.springSnappy, value: step)
    }
}

#Preview {
    AuthFlowView()
}
