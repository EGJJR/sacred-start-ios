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
            ProfileAvatarView(name: name, avatarURL: avatarURL, size: 56)

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
        .background(palette.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 12, y: 4)
    }
}

// MARK: - Profile hero

struct ABYSettingsProfileCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let name: String
    var email: String?
    var avatarURL: URL?
    var localImageData: Data?
    var streakDays: Int = 0
    var onEdit: () -> Void

    private var identity: StreakIdentity {
        StreakIdentity.identity(for: streakDays)
    }

    var body: some View {
        VStack(spacing: 16) {
            ProfileAvatarView(name: name, avatarURL: avatarURL, localImageData: localImageData, size: 80)

            VStack(spacing: 4) {
                Text(name)
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)
                if let email {
                    Text(email)
                        .font(ABY.Font.footnote)
                        .foregroundStyle(palette.textSecondary)
                }
                Text(identity.statusName)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
                    .padding(.top, 2)
            }

            Button(action: onEdit) {
                Text("Edit profile")
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(palette.isNight ? palette.buttonForeground : palette.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(palette.isNight ? palette.buttonFill : palette.background.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(palette.divider, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, ABY.Spacing.card)
        .frame(maxWidth: .infinity)
        .background(palette.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 14, y: 5)
    }
}

struct ABYSettingsPremiumBanner: View {
    @Environment(\.sanctuaryPalette) private var palette
    let isActive: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ABY.Color.pillPurple.opacity(0.2), ABY.Color.pillPink.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(ABY.Font.headline)
                        .foregroundStyle(ABY.Color.pillPurple)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(isActive ? "Sacred Start Premium" : "Upgrade to Premium")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text(isActive ? "Your subscription is active" : "Unlock AI Chaplain, guided devotion & more")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineSpacing(3)
                }

                Spacer(minLength: 0)

                if isActive {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(ABY.Font.paywallPromoBadge)
                            .foregroundStyle(Color(red: 0.72, green: 0.88, blue: 0.34))
                        Text("Active")
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(palette.textSecondary)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textTertiary)
                }
            }
            .padding(16)
            .background(palette.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Danger zone (ABY Journal)

private let abyDangerAccent = Color(red: 0.92, green: 0.55, blue: 0.52)

struct ABYSettingsDangerHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(ABY.Font.section)
            .foregroundStyle(abyDangerAccent)
            .tracking(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ABYSettingsDangerRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    let subtitle: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(ABY.Font.bodySemibold)
                        .foregroundStyle(palette.textPrimary)
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.85)
                    }
                }
                Text(subtitle)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, ABY.Spacing.card)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Form fields & buttons

struct ABYSettingsTextFieldGroup: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var helperText: String? = nil
    var helperColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(ABY.Font.footnoteMedium)
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ABY.Spacing.card)
                .padding(.top, 14)

            TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, ABY.Spacing.card)

            if let helperText {
                Text(helperText)
                    .font(ABY.Font.caption)
                    .foregroundStyle(helperColor ?? palette.textTertiary)
                    .padding(.horizontal, ABY.Spacing.card)
                    .padding(.bottom, 14)
            } else {
                Color.clear.frame(height: 14)
            }
        }
    }
}

struct ABYSettingsReadOnlyRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let icon: String
    let title: String
    let value: String

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
                Text(value)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, ABY.Spacing.card)
        .padding(.vertical, 14)
    }
}

struct ABYSettingsPrimaryButton: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Spacer()
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(ABY.Font.button)
                }
                Spacer()
            }
            .foregroundStyle(palette.buttonForeground)
            .padding(.vertical, 16)
            .background(isEnabled ? palette.buttonFill : palette.buttonFill.opacity(0.35))
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled || isLoading)
    }
}

struct ABYSettingsFooter: View {
    @Environment(\.sanctuaryPalette) private var palette
    var appName: String = "Sacred Start"
    var version: String = "1.0"

    var body: some View {
        VStack(spacing: 6) {
            Text(appName)
                .font(ABY.Font.editorialAccent)
                .foregroundStyle(palette.textTertiary)
            Text("Version \(version)")
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textTertiary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

// MARK: - Confirmation sheet

struct ABYConfirmationSheet: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    let message: String
    let confirmTitle: String
    var isDestructive: Bool = false
    var isLoading: Bool = false
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(palette.divider)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 20)

            Text(title)
                .font(ABY.Font.title2)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(message)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 28)

            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(isDestructive ? .white : palette.buttonForeground)
                        } else {
                            Text(confirmTitle)
                                .font(ABY.Font.button)
                        }
                        Spacer()
                    }
                    .foregroundStyle(isDestructive ? .white : palette.buttonForeground)
                    .padding(.vertical, 16)
                    .background(isDestructive ? Color.red.opacity(0.88) : palette.buttonFill)
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isLoading)

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(ABY.Font.calloutMedium)
                        .foregroundStyle(palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 12)
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(palette.cardFill)
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
                .tint(palette.isNight ? ABY.Color.pillTeal : palette.textPrimary)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ABY.Font.editorialTitle)
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
    /// Custom back chevron while preserving the system edge-swipe pop gesture.
    func abySettingsBackNavigation() -> some View {
        navigationBarBackButtonHidden(true)
            .toolbar { ABYBackToolbar() }
            .abyInteractivePopEnabled()
    }
}

extension View {
    func staggeredAppear(_ appeared: Bool, delay: Double) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(AppTheme.springGentle.delay(delay), value: appeared)
    }
}
