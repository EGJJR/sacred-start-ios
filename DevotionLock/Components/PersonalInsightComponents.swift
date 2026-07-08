//
//  PersonalInsightComponents.swift
//  DevotionLock
//
//  Mobbin refs:
//  Tolan editorial insight — https://mobbin.com/screens/33ce497d-b5ca-4f10-bae7-26cc43ef2f44
//  Gentler Streak pale cards — https://mobbin.com/screens/f1f313b1-01a0-4d8e-828b-dfc014130b13
//  Moonly "For You" cards — https://mobbin.com/screens/8bd68924-87c1-460f-8ef7-7a9118d9286a
//

import SwiftUI

struct PersonalInsightCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let insight: PersonalInsight
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(insight.accent.opacity(palette.isNight ? 0.22 : 0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: insight.icon)
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(insight.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("On this device. Private.")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }

                Spacer(minLength: 8)

                if let onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(palette.textTertiary)
                            .frame(width: 28, height: 28)
                            .background(palette.surfaceMuted.opacity(palette.isNight ? 0.45 : 0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss for today")
                }
            }

            Text(insight.body)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(palette.divider.opacity(palette.isNight ? 0.45 : 0.8), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(palette.isNight ? 0.22 : 0.05), radius: 12, y: 4)
    }
}

struct PersonalInsightsSection: View {
    let insights: [PersonalInsight]

    var body: some View {
        if !insights.isEmpty {
            ABYSectionHeader(title: "Your patterns")
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 10)
        }
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

// MARK: - Companion memory (Chaplain empty state)

struct ChaplainCompanionMemoryCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let memory: AmbientEmpathy.CompanionMemory
    var onKeepGoing: () -> Void
    var onSomethingNew: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Chaplain remembers")
                .font(ABY.Font.captionSemibold)
                .foregroundStyle(palette.textTertiary)
                .tracking(0.3)

            Text(memory.body)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(action: onKeepGoing) {
                    Text("Keep going")
                        .font(ABY.Font.captionSemibold)
                        .foregroundStyle(palette.isNight ? .white : ABY.Color.pillTeal)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(ABY.Color.pillTeal.opacity(palette.isNight ? 0.28 : 0.14))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onSomethingNew) {
                    Text("Something new")
                        .font(ABY.Font.captionSemibold)
                        .foregroundStyle(palette.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(palette.surfaceMuted.opacity(palette.isNight ? 0.45 : 0.8))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(palette.divider.opacity(palette.isNight ? 0.45 : 0.8), lineWidth: 0.5)
        }
    }
}

// MARK: - Verse-anchored callback

struct AmbientVerseCallbackCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let callback: AmbientEmpathy.VerseCallback
    var onOpen: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ABY.Color.pillPurple.opacity(palette.isNight ? 0.22 : 0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: "book.closed.fill")
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(ABY.Color.pillPurple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(callback.reference)
                        .font(ABY.Font.captionSemibold)
                        .foregroundStyle(ABY.Color.pillPurple)
                    Text(callback.body)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textPrimary)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(palette.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(palette.surfaceMuted.opacity(palette.isNight ? 0.45 : 0.7))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
            .padding(ABY.Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(palette.divider.opacity(palette.isNight ? 0.45 : 0.8), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(callback.reference)")
    }
}
