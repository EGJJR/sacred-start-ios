//
//  DevotionPaywallComponents.swift
//  DevotionLock
//
//  Mobbin refs: Tide trial timeline, Open plan cards, Calm trial badge, Ten Percent Happier sheet.
//

import StoreKit
import SwiftUI

// MARK: - Trial timeline (Tide-inspired)

struct PaywallTrialTimeline: View {
    let trialDays: Int

    private var chargeDate: Date {
        Calendar.current.date(byAdding: .day, value: trialDays, to: Date()) ?? Date()
    }

    private var chargeDateText: String {
        chargeDate.formatted(.dateTime.month(.abbreviated).day())
    }

    private var reminderDay: Int {
        max(1, trialDays - 2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            timelineRow(
                icon: "lock.open.fill",
                iconColor: ABY.Color.pillTeal,
                title: "Today",
                detail: "Unlock AI Chaplain, morning devotion, app shield, and your full journal."
            )
            timelineConnector
            timelineRow(
                icon: "bell.fill",
                iconColor: ABY.Color.pillOrange,
                title: "In \(reminderDay) days",
                detail: "We'll send a reminder before your trial ends."
            )
            timelineConnector
            timelineRow(
                icon: "checkmark.seal.fill",
                iconColor: ABY.Color.pillPurple,
                title: "In \(trialDays) days",
                detail: "You'll be charged on \(chargeDateText). Cancel anytime before."
            )
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .fill(ABY.Color.surface)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
    }

    private var timelineConnector: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(ABY.Color.divider)
                .frame(width: 2, height: 20)
                .padding(.leading, 19)
            Spacer()
        }
    }

    private func timelineRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(ABY.Font.iconMedium)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(iconColor.gradient)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(ABY.Font.headline)
                    .foregroundStyle(ABY.Color.textPrimary)
                Text(detail)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(ABY.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Feature checklist (Ten Percent Happier–inspired)

struct PaywallFeatureChecklist: View {
    private let items = [
        "AI Chaplain voice & text companion",
        "Guided morning devotion & journaling",
        "App shield & prayer circles",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(ABY.Color.accentDot)
                    Text(item)
                        .font(ABY.Font.callout)
                        .foregroundStyle(ABY.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Plan card (Open / Calm–inspired)

struct SacredPaywallPlanCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let badgeColor: Color?
    let promoText: String?
    let onSelect: () -> Void

    private var planLabel: String {
        guard let subscription = product.subscription else { return product.displayName }
        switch subscription.subscriptionPeriod.unit {
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Annual"
        default: return product.displayName
        }
    }

    private var periodSuffix: String {
        guard let subscription = product.subscription else { return "" }
        switch subscription.subscriptionPeriod.unit {
        case .week: return "/wk"
        case .month: return "/mo"
        case .year: return "/yr"
        default: return ""
        }
    }

    private var monthlyEquivalent: String? {
        guard let subscription = product.subscription,
              subscription.subscriptionPeriod.unit == .year else { return nil }
        let monthly = product.price / 12
        let formatted = monthly.formatted(product.priceFormatStyle)
        return "\(formatted)/mo"
    }

    private var hasFreeTrial: Bool {
        product.subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 12) {
                selectionRing

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(planLabel)
                            .font(ABY.Font.headline)
                            .foregroundStyle(isSelected ? ABY.Color.textPrimary : ABY.Color.textSecondary)
                        if hasFreeTrial {
                            trialBadge
                        }
                    }

                    if let promoText, !promoText.isEmpty {
                        Text(promoText)
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(ABY.Color.pillTeal)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice + periodSuffix)
                        .font(ABY.Font.title2)
                        .foregroundStyle(ABY.Color.textPrimary)
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
                    if let monthlyEquivalent {
                        Text(monthlyEquivalent)
                            .font(ABY.Font.caption)
                            .foregroundStyle(ABY.Color.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .fill(isSelected ? ABY.Color.textPrimary.opacity(0.04) : ABY.Color.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .strokeBorder(
                        isSelected ? ABY.Color.textPrimary : ABY.Color.divider,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(badgeColor ?? ABY.Color.textPrimary))
                        .offset(y: -10)
                        .padding(.trailing, 12)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var selectionRing: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? ABY.Color.textPrimary : ABY.Color.textTertiary, lineWidth: 2)
                .frame(width: 22, height: 22)
            if isSelected {
                Circle()
                    .fill(ABY.Color.textPrimary)
                    .frame(width: 12, height: 12)
            }
        }
    }

    private var trialBadge: some View {
        Text("5-day trial")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(ABY.Color.pillTeal)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(ABY.Color.pillTeal.opacity(0.12))
            .clipShape(Capsule())
    }
}
