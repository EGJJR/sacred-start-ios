//
//  PersonalInsightComponents.swift
//  DevotionLock
//

import SwiftUI

struct PersonalInsightCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let insight: PersonalInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(insight.accent.opacity(palette.isNight ? 0.2 : 0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: insight.icon)
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(insight.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text(localBadge)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }

                Spacer(minLength: 0)
            }

            Text(insight.body)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var localBadge: String {
        "On-device · Private"
    }
}

struct PersonalInsightsSection: View {
    let insights: [PersonalInsight]
    var limit: Int = 2

    var body: some View {
        if !displayed.isEmpty {
            ABYSectionHeader(title: "Your patterns")
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 10)

            VStack(spacing: 12) {
                ForEach(displayed) { insight in
                    PersonalInsightCard(insight: insight)
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 20)
        }
    }

    private var displayed: [PersonalInsight] {
        Array(insights.prefix(limit))
    }
}

struct PersonalInsightThemeRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let themes: [ThemeSignal]

    var body: some View {
        if !themes.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(themes.prefix(4), id: \.id) { theme in
                        HStack(spacing: 5) {
                            Text(theme.label)
                                .font(ABY.Font.captionMedium)
                            Text("×\(theme.count)")
                                .font(ABY.Font.caption)
                                .foregroundStyle(palette.textTertiary)
                        }
                        .foregroundStyle(palette.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(palette.surface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
            }
            .padding(.bottom, 12)
        }
    }
}
