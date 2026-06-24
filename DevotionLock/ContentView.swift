//
//  ContentView.swift
//  DevotionLock
//

import SwiftUI

/// Root routing: splash → auth → onboarding → main tabs. Paywall presents after onboarding
/// when the user has no active trial/subscription.
struct ContentView: View {
    private var auth = AuthManager.shared

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showOnboardingAfterSignOut") private var showOnboardingAfterSignOut = false
    @AppStorage("hasDismissedPaywall") private var hasDismissedPaywall = false
    @State private var showPaywall = false

    var body: some View {
        #if DEBUG
        if DesignTour.isActive {
            DesignTourView()
        } else {
            appContent
        }
        #else
        appContent
        #endif
    }

    @ViewBuilder
    private var appContent: some View {
        Group {
            if !auth.hasResolvedInitialSession {
                Color.clear
            } else if !auth.isAuthenticated && showOnboardingAfterSignOut {
                OnboardingFlowView {
                    withAnimation(AppTheme.springGentle) {
                        showOnboardingAfterSignOut = false
                        hasCompletedOnboarding = true
                    }
                }
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

#Preview {
    ContentView()
}
