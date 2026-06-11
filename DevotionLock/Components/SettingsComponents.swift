//
//  SettingsComponents.swift
//  test1
//

import SwiftUI

struct ABYProfileHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let name: String
    let streakDays: Int
    var avatarURL: URL? = nil
    var subtitle: String? = nil

    private var identity: StreakIdentity {
        StreakIdentity.identity(for: streakDays)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                ProfileAvatarView(name: name, avatarURL: avatarURL, size: 56)
                if streakDays > 0 {
                    SanctuaryGrowthArtifact(stage: identity.stage, size: 28)
                        .offset(x: 6, y: 6)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Text(subtitle ?? identity.statusName)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            if streakDays > 0 {
                VStack(spacing: 2) {
                    Text("\(streakDays)")
                        .font(ABY.Font.title2)
                        .foregroundStyle(palette.textPrimary)
                    Text("days")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(palette.background)
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
            }
        }
        .abyCard()
    }
}

struct ABYSettingsGroup<Content: View>: View {
    @Environment(\.sanctuaryPalette) private var palette
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct ABYSettingsRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let icon: String
    let title: String
    var detail: String? = nil
    var value: String? = nil
    var showChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ABY.Font.body)
                        .foregroundStyle(palette.textPrimary)
                    if let detail {
                        Text(detail)
                            .font(ABY.Font.footnote)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
                Spacer()
                if let value {
                    Text(value)
                        .font(ABY.Font.footnote)
                        .foregroundStyle(palette.textTertiary)
                }
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textTertiary)
                }
            }
            .padding(.horizontal, ABY.Spacing.card)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ABYSettingsToggleRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let icon: String
    let title: String
    var detail: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(ABY.Font.iconMedium)
                .foregroundStyle(palette.textSecondary)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textPrimary)
                if let detail {
                    Text(detail)
                        .font(ABY.Font.footnote)
                        .foregroundStyle(palette.textSecondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(palette.textPrimary)
        }
        .padding(.horizontal, ABY.Spacing.card)
        .padding(.vertical, 12)
    }
}

struct ABYSettingsDivider: View {
    @Environment(\.sanctuaryPalette) private var palette
    var body: some View {
        Rectangle()
            .fill(palette.divider)
            .frame(height: 1)
            .padding(.leading, 52)
    }
}

struct ABYScreenContainer<Content: View>: View {
    @Environment(\.sanctuaryPalette) private var palette
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
                .padding(.bottom, 120)
        }
        .abyTransparentScroll()
    }
}

struct ABYDetailHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(ABY.Font.title2)
                .foregroundStyle(palette.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ABYTimePill: View {
    @Environment(\.sanctuaryPalette) private var palette
    let time: String

    var body: some View {
        Text(time)
            .font(ABY.Font.captionMedium)
            .foregroundStyle(palette.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(palette.background)
            .clipShape(Capsule())
    }
}

struct ABYBackToolbar: ToolbarContent {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(palette.textPrimary)
            }
        }
    }
}

extension View {
    func staggeredAppear(_ appeared: Bool, delay: Double) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(AppTheme.springGentle.delay(delay), value: appeared)
    }
}
