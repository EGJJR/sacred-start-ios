//
//  DevotionProducts.swift
//  test1
//

import InAppKit
import SwiftUI

enum DevotionFeature: String, AppFeature {
    case aiChaplain = "ai_chaplain"
    case unlimitedJournal = "unlimited_journal"
    case appShield = "app_shield"
    case spiritualInsights = "spiritual_insights"
}

enum DevotionProducts {
    static let weekly = "com.devotionlock.mobile.premium.weekly"
    static let annual = "com.devotionlock.mobile.premium.annual"

    static let all: [ProductDefinition] = [
        Product(weekly, features: DevotionFeature.allCases)
            .withBadge("Flexible")
            .withMarketingFeatures([
                "AI Chaplain voice sessions",
                "Morning devotion timeline",
                "App shield",
            ]),
        Product(annual, features: DevotionFeature.allCases)
            .withBadge("Best Value", color: .black)
            .withRelativeDiscount(comparedTo: weekly)
            .withMarketingFeatures([
                "Everything in Weekly",
                "Spiritual theme insights",
                "Priority Chaplain reflections",
            ]),
    ]
}

enum PaywallBypass {
    static let storageKey = "paywallBypassEnabled"

    static var isEnabled: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: storageKey)
        #else
        false
        #endif
    }

    @MainActor
    static func syncIfNeeded() {
        #if DEBUG
        if isEnabled {
            InAppKit.shared.simulatePurchase(DevotionProducts.annual)
        }
        #endif
    }

    @MainActor
    static func setEnabled(_ enabled: Bool) {
        #if DEBUG
        UserDefaults.standard.set(enabled, forKey: storageKey)
        if enabled {
            InAppKit.shared.simulatePurchase(DevotionProducts.annual)
        } else {
            InAppKit.shared.clearPurchases()
        }
        #endif
    }
}

/// Single gate for premium features. v1 is subscription-only (3-day trial via StoreKit intro offer).
/// Call `guardPremium` from feature entry points; browsing without premium is allowed.
enum PaywallAccess {
    @MainActor
    static var hasPremium: Bool {
        if PaywallBypass.isEnabled { return true }
        if InAppKit.shared.hasAnyPurchase { return true }
        return false
    }

    @MainActor
    static func guardPremium(presentPaywall: @escaping () -> Void, action: @escaping () -> Void) {
        if hasPremium {
            action()
        } else {
            presentPaywall()
        }
    }
}
