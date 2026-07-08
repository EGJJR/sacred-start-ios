//
//  ContentView.swift
//  DevotionLock
//

import Notelet
import SwiftUI

/// Root routing: splash → auth → onboarding → main tabs. Paywall presents after onboarding
/// when the user has no active trial/subscription.
struct ContentView: View {
    private var auth = AuthManager.shared

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
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
            } else if auth.pendingPasswordUpdate {
                PasswordUpdateView()
            } else if !auth.isAuthenticated {
                AuthFlowView()
            } else if !hasCompletedOnboarding {
                OnboardingFlowView {
                    NoteletStorage.markCurrentVersionAsSeen()
                    withAnimation(AppTheme.springGentle) {
                        hasCompletedOnboarding = true
                    }
                    presentPaywallIfNeeded()
                }
            } else {
                MainTabView()
                    .noteletSheet(
                        notes: SacredStartReleaseNotes.all,
                        version: .current,
                        configuration: SacredStartReleaseNotes.configuration
                    )
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
        .onOpenURL { url in
            Task { await auth.handleAuthURL(url) }
        }
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
