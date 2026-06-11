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
    static let weekly = "com.devotionlock.mobile.premium.weekly.v2"
    static let monthly = "com.devotionlock.mobile.premium.monthly.v2"
    static let annual = "com.devotionlock.mobile.premium.annual.v2"

    static let displayOrder: [String] = [annual, monthly, weekly]

    static let all: [ProductDefinition] = [
        Product(annual, features: DevotionFeature.allCases)
            .withBadge("Best Value", color: .black)
            .withRelativeDiscount(comparedTo: monthly)
            .withMarketingFeatures([
                "Everything in Premium",
                "5-day free trial",
                "Spiritual theme insights",
            ]),
        Product(monthly, features: DevotionFeature.allCases)
            .withMarketingFeatures([
                "AI Chaplain voice sessions",
                "Morning devotion timeline",
                "App shield & prayer circles",
            ]),
        Product(weekly, features: DevotionFeature.allCases)
            .withBadge("Flexible")
            .withMarketingFeatures([
                "Full premium access",
                "Cancel anytime",
                "Try before you commit",
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

/// Single gate for premium features. v1 is subscription-only (5-day trial via StoreKit intro offer).
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
