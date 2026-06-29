//
//  DevotionPaywallView.swift
//  DevotionLock
//
//  Premium paywall — dark navy layout (Beside / Grok / FocusFlight synthesis).
//

import InAppKit
import StoreKit
import SwiftUI

struct DevotionPaywallView: View {
    let context: PaywallContext
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var inAppKit = InAppKit.shared
    @State private var selectedProductID: String = DevotionProducts.annual
    @State private var isRestoring = false
    @State private var showTerms = false
    @State private var showPrivacy = false

    private var products: [Product] {
        context.availableProducts.isEmpty ? inAppKit.availableProducts : context.availableProducts
    }

    private var sortedProducts: [Product] {
        DevotionProducts.displayOrder.compactMap { id in
            products.first(where: { $0.id == id })
        } + products.filter { !DevotionProducts.displayOrder.contains($0.id) }
    }

    private var selectedProduct: Product? {
        sortedProducts.first(where: { $0.id == selectedProductID }) ?? sortedProducts.first
    }

    private var usesMockPlans: Bool {
        #if DEBUG
        sortedProducts.isEmpty && (context.triggeredBy == "design-tour" || DesignTour.isActive)
        #else
        false
        #endif
    }

    private var planOptions: [PaywallPlanOption] {
        if usesMockPlans {
            return PaywallPlanOption.mockPair
        }
        let pairIDs = [DevotionProducts.monthly, DevotionProducts.annual]
        return pairIDs.compactMap { id in
            guard let product = sortedProducts.first(where: { $0.id == id }) else { return nil }
            let promo = inAppKit.promoText(for: id) ?? discountPromo(for: product) ?? annualBadge(for: product)
            return PaywallPlanOption.from(product: product, promo: promo)
        }
    }

    private var selectedHasTrial: Bool {
        selectedProduct?.subscription?.introductoryOffer?.paymentMode == .freeTrial
            || (usesMockPlans && selectedProductID == DevotionProducts.annual)
    }

    private var hasWeeklyPlan: Bool {
        usesMockPlans || sortedProducts.contains(where: { $0.id == DevotionProducts.weekly })
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ABYPaywallBackground()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Color.clear.frame(height: 40)

                    PaywallBrandMark()

                    PaywallHeroBlock()

                    PaywallBenefitsCard(benefits: PaywallBenefit.premium, compact: true)

                    planSection
                }
                .padding(.horizontal, ABY.Spacing.screen)

                Spacer(minLength: 8)

                PaywallPurchaseFooter(
                    ctaTitle: subscribeTitle,
                    pricingNote: pricingNote,
                    isPurchasing: inAppKit.isPurchasing,
                    isDisabled: inAppKit.isPurchasing || (planOptions.isEmpty && !usesMockPlans),
                    isRestoring: isRestoring,
                    purchase: { Task { await purchaseSelected() } },
                    restore: { Task { await restore() } },
                    showTerms: { showTerms = true },
                    showPrivacy: { showPrivacy = true }
                )
            }

            closeButton
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack { LegalDocumentView(document: .termsOfService) }
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack { LegalDocumentView(document: .privacyPolicy) }
        }
        .onAppear {
            if let annual = sortedProducts.first(where: { $0.id == DevotionProducts.annual }) {
                selectedProductID = annual.id
            } else if let first = planOptions.first {
                selectedProductID = first.id
            }
            #if DEBUG
            if usesMockPlans {
                selectedProductID = DevotionProducts.annual
            }
            #endif
        }
    }

    private var closeButton: some View {
        Button {
            onDismiss?()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(ABY.Font.bodyMedium)
                .foregroundStyle(ABY.Color.paywallTextPrimary)
                .frame(width: 36, height: 36)
                .background(ABY.Color.paywallCloseFill)
                .clipShape(Circle())
        }
        .accessibilityLabel("Close paywall")
        .padding(.top, 12)
        .padding(.trailing, ABY.Spacing.screen)
    }

    @ViewBuilder
    private var planSection: some View {
        if planOptions.isEmpty && !usesMockPlans {
            loadingPlans
        } else {
            VStack(spacing: 14) {
                Text("Choose your plan")
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.paywallTextTertiary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 10) {
                    ForEach(planOptions) { option in
                        PaywallPlanCard(
                            option: option,
                            isSelected: selectedProductID == option.id,
                            onSelect: { selectedProductID = option.id }
                        )
                    }
                }
                .padding(.top, planOptions.contains(where: { $0.promoBadge != nil }) ? 8 : 0)

                if hasWeeklyPlan {
                    PaywallWeeklyOptionLink(
                        isWeeklySelected: selectedProductID == DevotionProducts.weekly,
                        action: { selectedProductID = DevotionProducts.weekly }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var loadingPlans: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(ABY.Color.paywallTextPrimary)
            Text("Loading plans…")
                .font(ABY.Font.footnote)
                .foregroundStyle(ABY.Color.paywallTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func annualBadge(for product: Product) -> String? {
        guard product.id == DevotionProducts.annual else { return nil }
        return inAppKit.badge(for: product.id) ?? "Best value"
    }

    @MainActor
    private func discountPromo(for product: Product) -> String? {
        guard let rule = inAppKit.discountRule(for: product.id),
              let base = products.first(where: { $0.id == rule.comparedTo }),
              let currentSub = product.subscription,
              let baseSub = base.subscription else { return nil }

        let monthsInCurrent = months(in: currentSub.subscriptionPeriod)
        let baseMonthly = base.price / Decimal(months(in: baseSub.subscriptionPeriod))
        let totalBase = baseMonthly * Decimal(monthsInCurrent)
        let savings = totalBase - product.price
        guard savings > 0 else { return nil }

        let pct = Int((savings as NSDecimalNumber).dividing(by: totalBase as NSDecimalNumber).multiplying(by: 100).doubleValue.rounded())
        return pct > 0 ? "Save \(pct)%" : nil
    }

    private func months(in period: Product.SubscriptionPeriod) -> Int {
        switch period.unit {
        case .day: max(1, period.value / 30)
        case .week: max(1, period.value / 4)
        case .month: period.value
        case .year: period.value * 12
        default: period.value
        }
    }

    private var subscribeTitle: String {
        if inAppKit.isPurchasing { return "Processing…" }
        if selectedHasTrial { return "Start free trial" }
        return "Subscribe to Plus"
    }

    private var pricingNote: String? {
        if usesMockPlans {
            if selectedProductID == DevotionProducts.annual {
                return "5-day free trial, then $39.99/year. Cancel anytime."
            }
            return "$9.99/month. Cancel anytime."
        }
        guard let product = selectedProduct else { return nil }
        if selectedHasTrial {
            return "5-day free trial, then \(product.displayPrice). Cancel anytime."
        }
        return "\(product.displayPrice). Cancel anytime."
    }

    @MainActor
    private func purchaseSelected() async {
        #if DEBUG
        if usesMockPlans {
            PaywallBypass.setEnabled(true)
            closePaywall()
            return
        }
        #endif
        guard let product = selectedProduct else { return }
        do {
            try await inAppKit.purchase(product)
            await PaywallAccess.confirmPurchaseCompleted()
            closePaywall()
        } catch {
            inAppKit.purchaseError = error
        }
    }

    @MainActor
    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        await inAppKit.restorePurchases()
        if inAppKit.hasAnyPurchase {
            await PaywallAccess.confirmPurchaseCompleted()
            closePaywall()
        }
    }

    private func closePaywall() {
        onDismiss?()
        dismiss()
    }
}

#Preview {
    DevotionPaywallView(
        context: PaywallContext(triggeredBy: "preview", availableProducts: [])
    )
}
