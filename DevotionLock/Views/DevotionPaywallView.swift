//
//  DevotionPaywallView.swift
//  test1
//
//  Mobbin refs: Tide trial timeline, Open plan cards, Ten Percent Happier bottom sheet, Calm CTA.
//

import InAppKit
import StoreKit
import SwiftUI

struct DevotionPaywallView: View {
    let context: PaywallContext
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var inAppKit = InAppKit.shared
    @State private var selectedProduct: Product?
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

    private var selectedHasTrial: Bool {
        selectedProduct?.subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ABYOnboardingMeshBackground()

            VStack(spacing: 0) {
                heroSection
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 52)
                    .padding(.bottom, 16)

                paywallSheet
            }

            closeButton
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                LegalDocumentView(document: .termsOfService)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack {
                LegalDocumentView(document: .privacyPolicy)
            }
        }
        .onAppear {
            if selectedProduct == nil {
                selectedProduct = products.first(where: { $0.id == DevotionProducts.annual }) ?? sortedProducts.first
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            VoiceOrb(state: .idle, size: 64)

            Text("Start your sacred rhythm")
                .font(ABY.Font.onboardingTitle)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Morning devotion, AI Chaplain, prayer circles, and app shield — all in one peaceful subscription.")
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.onboardingTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(ABY.Color.accentDot)
                }
                Text("Built for daily devotion")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.onboardingTextMuted)
            }
        }
    }

    // MARK: - Bottom sheet

    private var paywallSheet: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Ready to begin?")
                        .font(ABY.Font.title2)
                        .foregroundStyle(ABY.Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    PaywallFeatureChecklist()

                    if selectedHasTrial {
                        PaywallTrialTimeline(trialDays: 5)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    plansSection
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 28)
                .padding(.bottom, 16)
            }

            bottomBar
        }
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(ABY.Color.gradientTop)
                .shadow(color: .black.opacity(0.12), radius: 24, y: -8)
                .ignoresSafeArea(edges: .bottom)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedHasTrial)
    }

    private var closeButton: some View {
        Button {
            onDismiss?()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(ABY.Font.iconMedium)
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.18))
                .clipShape(Circle())
        }
        .accessibilityLabel("Close paywall")
        .padding(.top, 12)
        .padding(.trailing, ABY.Spacing.screen)
    }

    @ViewBuilder
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose your plan")
                .font(ABY.Font.section)
                .foregroundStyle(ABY.Color.textTertiary)
                .textCase(.uppercase)
                .tracking(0.6)

            if sortedProducts.isEmpty {
                loadingPlans
            } else {
                ForEach(sortedProducts, id: \.id) { product in
                    SacredPaywallPlanCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        badge: inAppKit.badge(for: product.id),
                        badgeColor: inAppKit.badgeColor(for: product.id),
                        promoText: inAppKit.promoText(for: product.id) ?? discountPromo(for: product),
                        onSelect: { selectedProduct = product }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var loadingPlans: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading plans…")
                .font(ABY.Font.footnote)
                .foregroundStyle(ABY.Color.textSecondary)
            #if DEBUG
            debugPlanFallback
            #endif
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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
        @unknown default: period.value
        }
    }

    #if DEBUG
    private var debugPlanFallback: some View {
        VStack(spacing: 8) {
            Text("StoreKit products unavailable in simulator.")
                .font(ABY.Font.caption)
                .foregroundStyle(ABY.Color.textTertiary)
                .multilineTextAlignment(.center)
            Text("Enable “Bypass paywall” in You → Developer, or add DevotionLock.storekit to the scheme.")
                .font(ABY.Font.caption)
                .foregroundStyle(ABY.Color.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
    #endif

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if let product = selectedProduct {
                ABYPrimaryButton(
                    title: purchaseTitle(for: product),
                    icon: inAppKit.isPurchasing ? nil : (selectedHasTrial ? "gift.fill" : "checkmark")
                ) {
                    Task { await purchase(product) }
                }
                .disabled(inAppKit.isPurchasing || inAppKit.isPurchased(product.id))
                .opacity(inAppKit.isPurchasing ? 0.7 : 1)

                Text(ctaSubtitle(for: product))
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                ABYPrimaryButton(title: "Continue") {
                    #if DEBUG
                    PaywallBypass.setEnabled(true)
                    closePaywall()
                    #endif
                }
            }

            HStack(spacing: 16) {
                Button("Restore") {
                    Task { await restore() }
                }
                .disabled(isRestoring)

                Text("·").foregroundStyle(ABY.Color.textTertiary)

                Button("Terms") { showTerms = true }

                Text("·").foregroundStyle(ABY.Color.textTertiary)

                Button("Privacy") { showPrivacy = true }
            }
            .font(ABY.Font.caption.weight(.medium))
            .foregroundStyle(ABY.Color.textSecondary)

            subscriptionDisclosure
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(.ultraThinMaterial)
    }

    private func ctaSubtitle(for product: Product) -> String {
        if selectedHasTrial {
            return "5 days free, then \(product.displayPrice)/year. Cancel anytime."
        }
        guard let subscription = product.subscription else {
            return "Billed \(product.displayPrice). Cancel anytime."
        }
        switch subscription.subscriptionPeriod.unit {
        case .week:
            return "Billed \(product.displayPrice) weekly. Cancel anytime."
        case .month:
            return "Billed \(product.displayPrice) monthly. Cancel anytime."
        case .year:
            return "Billed \(product.displayPrice) yearly. Cancel anytime."
        default:
            return "Cancel anytime in Settings."
        }
    }

    private var subscriptionDisclosure: some View {
        VStack(spacing: 6) {
            Text("Payment is charged to your Apple ID. Subscriptions auto-renew unless canceled at least 24 hours before the end of the current period. Free trial converts to a paid subscription unless canceled before the trial ends.")
                .font(.system(size: 10))
                .foregroundStyle(ABY.Color.textTertiary)
                .multilineTextAlignment(.center)
            Link("Manage subscriptions", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                .font(.system(size: 10, weight: .medium))
        }
    }

    private func purchaseTitle(for product: Product) -> String {
        if inAppKit.isPurchased(product.id) { return "Subscribed" }
        if inAppKit.isPurchasing { return "Processing…" }
        if product.subscription?.introductoryOffer != nil {
            return "Start free trial"
        }
        return "Subscribe · \(product.displayPrice)"
    }

    @MainActor
    private func purchase(_ product: Product) async {
        do {
            try await inAppKit.purchase(product)
            if inAppKit.hasAnyPurchase {
                await UserPreferencesSync.shared.updatePremium(true)
                closePaywall()
            }
        } catch {
            // StoreKit surfaces errors via inAppKit.purchaseError
        }
    }

    @MainActor
    private func restore() async {
        isRestoring = true
        await inAppKit.restorePurchases()
        isRestoring = false
        if inAppKit.hasAnyPurchase {
            await UserPreferencesSync.shared.updatePremium(true)
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
