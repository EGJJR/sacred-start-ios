//
//  DevotionProducts.swift
//  test1
//

import InAppKit
import StoreKit
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
    private static let premiumConfirmedAtKey = "devotionPremiumConfirmedAt"
    private static let entitlementGrace: TimeInterval = 15 * 60

    static let statusDidChange = Notification.Name("devotionPremiumStatusDidChange")

    /// Updated by silent `Transaction.currentEntitlements` reads (no Apple ID prompt).
    @MainActor
    private static var silentEntitlementActive = false

    private static var premiumProductIDs: Set<String> {
        Set(DevotionProducts.all.map(\.id))
    }

    @MainActor
    static var hasPremium: Bool {
        if PaywallBypass.isEnabled { return true }
        if InAppKit.shared.hasAnyPurchase { return true }
        if silentEntitlementActive { return true }
        if hasRecentPurchaseConfirmation { return true }
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

    /// Call after StoreKit reports a successful purchase or restore.
    @MainActor
    static func markPurchaseSucceeded() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: premiumConfirmedAtKey)
        NotificationCenter.default.post(name: statusDidChange, object: nil)
    }

    @MainActor
    static func clearPurchaseConfirmation() {
        UserDefaults.standard.removeObject(forKey: premiumConfirmedAtKey)
        NotificationCenter.default.post(name: statusDidChange, object: nil)
    }

    /// Reconcile StoreKit entitlements on launch / foreground without `AppStore.sync()`.
    @MainActor
    static func syncFromStoreKit() async {
        silentEntitlementActive = await hasActiveStoreEntitlement()
        reconcilePremiumFlags()
    }

    /// User-initiated restore — may prompt for Apple ID; only call from Restore actions.
    @MainActor
    static func restorePurchasesFromStore() async {
        await InAppKit.shared.restorePurchases()
        silentEntitlementActive = await hasActiveStoreEntitlement()
        reconcilePremiumFlags()
    }

    /// Run after a purchase completes so entitlements can catch up in sandbox.
    @MainActor
    static func confirmPurchaseCompleted() async {
        markPurchaseSucceeded()
        await UserPreferencesSync.shared.updatePremium(true)

        if InAppKit.shared.hasAnyPurchase {
            silentEntitlementActive = true
            markPurchaseSucceeded()
            return
        }

        for _ in 0..<5 {
            try? await Task.sleep(for: .milliseconds(400))
            silentEntitlementActive = await hasActiveStoreEntitlement()
            if InAppKit.shared.hasAnyPurchase || silentEntitlementActive {
                markPurchaseSucceeded()
                return
            }
        }
    }

    @MainActor
    private static func reconcilePremiumFlags() {
        if InAppKit.shared.hasAnyPurchase || silentEntitlementActive {
            markPurchaseSucceeded()
        } else if !hasRecentPurchaseConfirmation {
            clearPurchaseConfirmation()
        }
    }

    @MainActor
    private static func hasActiveStoreEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard premiumProductIDs.contains(transaction.productID) else { continue }
            switch transaction.productType {
            case .autoRenewable, .nonRenewable, .nonConsumable:
                return true
            default:
                continue
            }
        }
        return false
    }

    @MainActor
    private static var hasRecentPurchaseConfirmation: Bool {
        let timestamp = UserDefaults.standard.double(forKey: premiumConfirmedAtKey)
        guard timestamp > 0 else { return false }
        return Date().timeIntervalSince1970 - timestamp < entitlementGrace
    }
}
