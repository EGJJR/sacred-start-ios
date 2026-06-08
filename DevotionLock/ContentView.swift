//
//  ContentView.swift
//  DevotionLock
//

import SwiftUI

/// Root routing: splash → auth → onboarding → main tabs. Paywall presents after onboarding
/// when the user has no active trial/subscription.
struct ContentView: View {
    @State private var auth = AuthManager.shared

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasDismissedPaywall") private var hasDismissedPaywall = false
    @State private var showPaywall = false

    var body: some View {
        Group {
            if !auth.hasResolvedInitialSession {
                Color.clear
            } else if !auth.isAuthenticated {
                AuthFlowView()
            } else if !hasCompletedOnboarding {
                OnboardingFlowView {
                    withAnimation(AppTheme.springGentle) {
                        hasCompletedOnboarding = true
                    }
                    presentPaywallIfNeeded()
                }
            } else {
                MainTabView()
            }
        }
        .devotionPaywallRoot(
            showPaywall: $showPaywall,
            hasDismissedPaywall: $hasDismissedPaywall
        )
        .environment(\.presentDevotionPaywall) {
            showPaywall = true
        }
        .environment(\.authManager, auth)
    }

    private func presentPaywallIfNeeded() {
        Task { @MainActor in
            PaywallBypass.syncIfNeeded()
            if !PaywallAccess.hasPremium && !hasDismissedPaywall {
                showPaywall = true
            }
        }
    }
}

private struct PresentDevotionPaywallKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct AuthManagerKey: EnvironmentKey {
    static let defaultValue = AuthManager.shared
}

extension EnvironmentValues {
    var presentDevotionPaywall: () -> Void {
        get { self[PresentDevotionPaywallKey.self] }
        set { self[PresentDevotionPaywallKey.self] = newValue }
    }

    var authManager: AuthManager {
        get { self[AuthManagerKey.self] }
        set { self[AuthManagerKey.self] = newValue }
    }
}

#Preview {
    ContentView()
}
