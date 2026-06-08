//
//  DevotionPaywallSetup.swift
//  DevotionLock
//

import InAppKit
import SwiftUI

extension View {
    /// InAppKit purchase + paywall wiring for the app root.
    func devotionPaywallRoot(
        showPaywall: Binding<Bool>,
        hasDismissedPaywall: Binding<Bool>
    ) -> some View {
        withPurchases(products: DevotionProducts.all)
            .withPaywall { context in
                DevotionPaywallView(context: context)
            }
            .withTerms(url: URL(string: "https://apps.apple.com/account/subscriptions")!)
            .withPrivacy(url: URL(string: "https://apps.apple.com/account/subscriptions")!)
            .task {
                PaywallBypass.syncIfNeeded()
            }
            .fullScreenCover(isPresented: showPaywall) {
                DevotionPaywallView(
                    context: PaywallContext(
                        triggeredBy: "post_onboarding",
                        availableProducts: InAppKit.shared.availableProducts
                    ),
                    onDismiss: { hasDismissedPaywall.wrappedValue = true }
                )
            }
    }
}
