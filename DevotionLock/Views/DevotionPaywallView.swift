//
//  DevotionPaywallView.swift
//  test1
//

import InAppKit
import StoreKit
import SwiftUI

// ABY Journal–inspired paywall (Mobbin ref: ABY premium unlock screen)
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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ABYOnboardingMeshBackground()
                .opacity(0.85)

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        header
                        trialCTA
                        featuresCard
                        plansSection
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 56)
                    .padding(.bottom, 24)
                }

                bottomBar
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
                selectedProduct = products.first(where: { $0.id == DevotionProducts.annual }) ?? products.first
            }
        }
    }

    private var closeButton: some View {
        Button {
            onDismiss?()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(ABY.Font.iconMedium)
                .foregroundStyle(ABY.Color.textSecondary)
                .frame(width: 36, height: 36)
                .background(ABY.Color.surface.opacity(0.9))
                .clipShape(Circle())
        }
        .accessibilityLabel("Close paywall")
        .padding(.top, 12)
        .padding(.trailing, ABY.Spacing.screen)
    }

    private var header: some View {
        VStack(spacing: 10) {
            VoiceOrb(state: .idle, size: 72)
            Text("Unlock your full devotional rhythm")
                .font(ABY.Font.title2)
                .foregroundStyle(ABY.Color.textPrimary)
                .multilineTextAlignment(.center)
            Text("AI-powered Chaplain, morning devotion, prayer circles, app shield, and your complete journal — one peaceful subscription.")
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var trialCTA: some View {
        VStack(spacing: 8) {
            Text("Start your 3-day free trial")
                .font(ABY.Font.headline)
                .foregroundStyle(ABY.Color.textPrimary)
            Text("Full access · cancel anytime before you're charged")
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .abyGlassCard(cornerRadius: ABY.Radius.glass, padding: 14)
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Everything in Premium")
                .font(ABY.Font.headline)
                .foregroundStyle(ABY.Color.textPrimary)
            paywallFeature(icon: "waveform", color: ABY.Color.pillPurple, title: "AI Chaplain", detail: "Voice and text spiritual companion")
            paywallFeature(icon: "sun.horizon.fill", color: ABY.Color.pillTeal, title: "Morning devotion", detail: "Guided scripture, reflection, and journaling")
            paywallFeature(icon: "lock.shield.fill", color: ABY.Color.pillOrange, title: "App shield", detail: "Protect mornings from distraction")
            paywallFeature(icon: "hands.sparkles.fill", color: ABY.Color.pillPink, title: "Prayer wall & circles", detail: "Share prayers with your community")
        }
        .abyCard(cornerRadius: ABY.Radius.glass)
    }

    private func paywallFeature(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(ABY.Font.iconMedium)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ABY.Font.body.weight(.medium))
                    .foregroundStyle(ABY.Color.textPrimary)
                Text(detail)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(ABY.Color.textSecondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var plansSection: some View {
        if products.isEmpty {
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
        } else {
            VStack(spacing: 10) {
                ForEach(products, id: \.id) { product in
                    PurchaseOptionCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        onSelect: { selectedProduct = product },
                        badge: inAppKit.badge(for: product.id),
                        badgeColor: inAppKit.badgeColor(for: product.id),
                        features: inAppKit.marketingFeatures(for: product.id),
                        promoText: inAppKit.promoText(for: product.id)
                    )
                }
            }
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

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if let product = selectedProduct {
                ABYPrimaryButton(
                    title: purchaseTitle(for: product),
                    icon: inAppKit.isPurchasing ? nil : "checkmark"
                ) {
                    Task { await purchase(product) }
                }
                .disabled(inAppKit.isPurchasing || inAppKit.isPurchased(product.id))
                .opacity(inAppKit.isPurchasing ? 0.7 : 1)
            } else {
                ABYPrimaryButton(title: "Continue") {
                    #if DEBUG
                    PaywallBypass.setEnabled(true)
                    closePaywall()
                    #endif
                }
            }

            Button("Restore Purchases") {
                Task { await restore() }
            }
            .font(ABY.Font.footnote.weight(.medium))
            .foregroundStyle(ABY.Color.textSecondary)
            .disabled(isRestoring)

            subscriptionDisclosure

            HStack(spacing: 16) {
                Button("Terms") { showTerms = true }
                Text("·").foregroundStyle(ABY.Color.textTertiary)
                Button("Privacy") { showPrivacy = true }
            }
            .font(ABY.Font.caption)
            .foregroundStyle(ABY.Color.textSecondary)
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(.ultraThinMaterial)
    }

    private var subscriptionDisclosure: some View {
        VStack(spacing: 6) {
            Text("Payment is charged to your Apple ID. Subscriptions auto-renew unless canceled at least 24 hours before the end of the current period. Free trial converts to a paid subscription unless canceled before the trial ends.")
                .font(ABY.Font.caption)
                .foregroundStyle(ABY.Color.textTertiary)
                .multilineTextAlignment(.center)
            Link("Manage subscriptions", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                .font(ABY.Font.caption.weight(.medium))
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
