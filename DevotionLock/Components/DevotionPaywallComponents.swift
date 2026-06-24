//
//  DevotionPaywallComponents.swift
//  DevotionLock
//
//  Dark premium paywall — Beside / Grok / FocusFlight synthesis.
//

import StoreKit
import SwiftUI

// MARK: - Brand & hero

struct PaywallBrandMark: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Sacred Start")
                .font(ABY.Font.paywallBrand)
                .foregroundStyle(ABY.Color.paywallTextPrimary)

            Text("PLUS")
                .font(ABY.Font.paywallBadge)
                .tracking(0.8)
                .foregroundStyle(ABY.Color.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ABY.Color.paywallTextPrimary)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
    }
}

struct PaywallHeroBlock: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("Unlock your full\nmorning sanctuary")
                .font(ABY.Font.paywallHeadline)
                .foregroundStyle(ABY.Color.paywallTextPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(ABY.Font.emojiSmall)
                        .foregroundStyle(ABY.Color.accentDot)
                }
                Text("(1,000+ mornings)")
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.paywallTextSecondary)
            }

            Text("Worth every peaceful morning")
                .font(ABY.Font.footnote)
                .foregroundStyle(ABY.Color.paywallTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Benefits

struct PaywallBenefit: Identifiable {
    let id: String
    let icon: String
    let tint: Color
    let title: String
    let detail: String

    static let premium: [PaywallBenefit] = [
        PaywallBenefit(
            id: "chaplain",
            icon: "mic.fill",
            tint: ABY.Color.pillPurple,
            title: "Unlimited AI Chaplain",
            detail: "Voice and text sessions that meet you in prayer."
        ),
        PaywallBenefit(
            id: "devotion",
            icon: "book.closed.fill",
            tint: ABY.Color.pillTeal,
            title: "Morning devotion & shield",
            detail: "Scripture, journaling, and app protection in one flow."
        ),
        PaywallBenefit(
            id: "journal",
            icon: "sparkles",
            tint: ABY.Color.meshPeriwinkle,
            title: "Advanced guided journaling",
            detail: "Mad-libs prompts, gratitude, and AI reflections."
        ),
        PaywallBenefit(
            id: "insights",
            icon: "chart.line.uptrend.xyaxis",
            tint: ABY.Color.pillOrange,
            title: "Spiritual theme insights",
            detail: "See patterns in your devotion and mood over time."
        ),
    ]
}

struct PaywallBenefitsCard: View {
    let benefits: [PaywallBenefit]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Everything in Plus")
                .font(ABY.Font.caption)
                .foregroundStyle(ABY.Color.paywallTextTertiary)
                .textCase(.uppercase)
                .tracking(0.6)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(benefits) { benefit in
                    PaywallBenefitRow(benefit: benefit)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ABY.Color.paywallGlassFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(ABY.Color.paywallGlassStroke, lineWidth: 1)
                }
        }
    }
}

struct PaywallBenefitRow: View {
    let benefit: PaywallBenefit

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: benefit.icon)
                .font(ABY.Font.iconMedium)
                .foregroundStyle(ABY.Color.paywallTextPrimary)
                .frame(width: 22, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(benefit.title)
                    .font(ABY.Font.paywallFeature)
                    .foregroundStyle(ABY.Color.paywallTextPrimary)
                Text(benefit.detail)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(ABY.Color.paywallTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Plans

struct PaywallPlanOption: Identifiable {
    let id: String
    let periodLabel: String
    let priceLabel: String
    let billingNote: String
    let promoBadge: String?
    let isRecommended: Bool

    static func from(product: Product, promo: String?) -> PaywallPlanOption? {
        guard let subscription = product.subscription else { return nil }
        let periodLabel: String
        let priceLabel: String
        var billingNote: String
        let isRecommended = product.id == DevotionProducts.annual

        switch subscription.subscriptionPeriod.unit {
        case .month:
            periodLabel = "Monthly"
            priceLabel = product.displayPrice
            billingNote = "Billed monthly"
        case .year:
            periodLabel = "Yearly"
            let monthly = product.price / 12
            let formatted = monthly.formatted(product.priceFormatStyle)
            priceLabel = formatted
            billingNote = "\(product.displayPrice) billed yearly"
        case .week:
            periodLabel = "Weekly"
            priceLabel = product.displayPrice
            billingNote = "Billed weekly"
        default:
            periodLabel = product.displayName
            priceLabel = product.displayPrice
            billingNote = product.displayPrice
        }

        if subscription.introductoryOffer?.paymentMode == .freeTrial {
            billingNote = "5-day free trial · \(billingNote.lowercased())"
        }

        return PaywallPlanOption(
            id: product.id,
            periodLabel: periodLabel,
            priceLabel: priceLabel,
            billingNote: billingNote,
            promoBadge: promo,
            isRecommended: isRecommended
        )
    }

    static var mockPair: [PaywallPlanOption] {
        [
            PaywallPlanOption(
                id: DevotionProducts.monthly,
                periodLabel: "Monthly",
                priceLabel: "$9.99",
                billingNote: "Billed monthly",
                promoBadge: nil,
                isRecommended: false
            ),
            PaywallPlanOption(
                id: DevotionProducts.annual,
                periodLabel: "Yearly",
                priceLabel: "$3.33",
                billingNote: "5-day free trial · $39.99 billed yearly",
                promoBadge: "Best value",
                isRecommended: true
            ),
        ]
    }
}

struct PaywallPlanCard: View {
    let option: PaywallPlanOption
    let isSelected: Bool
    let onSelect: () -> Void

    private var labelColor: Color {
        isSelected ? ABY.Color.textSecondary : ABY.Color.paywallTextSecondary
    }

    private var priceColor: Color {
        isSelected ? ABY.Color.textPrimary : ABY.Color.paywallTextPrimary
    }

    private var noteColor: Color {
        isSelected ? ABY.Color.textTertiary : ABY.Color.paywallTextTertiary
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(option.periodLabel.uppercased())
                        .font(ABY.Font.paywallPlanLabel)
                        .foregroundStyle(labelColor)
                        .tracking(0.4)
                    Spacer(minLength: 0)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(option.priceLabel)
                        .font(ABY.Font.paywallPrice)
                        .foregroundStyle(priceColor)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    if option.id != DevotionProducts.weekly {
                        Text("/mo")
                            .font(ABY.Font.footnoteMedium)
                            .foregroundStyle(labelColor)
                    }
                }

                Text(option.billingNote)
                    .font(ABY.Font.caption)
                    .foregroundStyle(noteColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Color.white : ABY.Color.paywallPlanFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.clear : ABY.Color.paywallPlanBorder,
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .top) {
                if let badge = option.promoBadge, isSelected {
                    Text(badge.uppercased())
                        .font(ABY.Font.paywallPromoBadge)
                        .tracking(0.3)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(ABY.Color.paywallOrbPurple)
                        .clipShape(Capsule())
                        .offset(y: -11)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PaywallWeeklyOptionLink: View {
    let isWeeklySelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isWeeklySelected ? "Weekly plan selected" : "Prefer weekly billing?")
                .font(ABY.Font.captionMedium)
                .foregroundStyle(ABY.Color.paywallTextSecondary)
                .underline(isWeeklySelected)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Purchase footer

struct PaywallPurchaseFooter: View {
    let ctaTitle: String
    let pricingNote: String?
    let isPurchasing: Bool
    let isDisabled: Bool
    let isRestoring: Bool
    let purchase: () -> Void
    let restore: () -> Void
    let showTerms: () -> Void
    let showPrivacy: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Button(action: purchase) {
                Text(ctaTitle)
                    .font(ABY.Font.paywallCTA)
                    .foregroundStyle(ABY.Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.white.opacity(isPurchasing || isDisabled ? 0.55 : 1))
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isDisabled)

            if let pricingNote {
                Text(pricingNote)
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.paywallTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: restore) {
                Text(isRestoring ? "Restoring…" : "Restore Purchase")
                    .font(ABY.Font.footnoteMedium)
                    .foregroundStyle(ABY.Color.paywallTextSecondary)
            }
            .buttonStyle(.plain)
            .disabled(isRestoring)

            Text("Cancel anytime via the App Store")
                .font(ABY.Font.caption)
                .foregroundStyle(ABY.Color.paywallTextTertiary)

            HStack(spacing: 6) {
                Button("Terms", action: showTerms)
                Text("·").foregroundStyle(ABY.Color.paywallTextTertiary)
                Button("Privacy", action: showPrivacy)
            }
            .font(ABY.Font.captionMedium)
            .foregroundStyle(ABY.Color.paywallTextSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background {
            LinearGradient(
                colors: [
                    ABY.Color.nightGradientBottom.opacity(0),
                    ABY.Color.nightGradientBottom.opacity(0.92),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
