//
//  SanctuaryAppearanceSettingsView.swift
//  DevotionLock
//

import SwiftUI

struct SanctuaryAppearanceSettingsView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue

    private var selectedMode: SanctuaryGradientMode {
        SanctuaryGradientMode(rawValue: modeRaw) ?? .light
    }

    var body: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                ABYDetailHeader(
                    title: "Appearance",
                    subtitle: "Evening sanctuary uses the same twilight palette as Close the day — plum, indigo, and soft glass."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 24)

                ABYSectionHeader(title: "Sanctuary mood")
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 12)

                VStack(spacing: 12) {
                    ForEach(SanctuaryGradientMode.allCases) { mode in
                        gradientOption(mode)
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
            }
        }
        .abySettingsBackNavigation()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func gradientOption(_ mode: SanctuaryGradientMode) -> some View {
        Button {
            withAnimation(AppTheme.springSnappy) {
                modeRaw = mode.rawValue
            }
            DevotionHaptics.light()
        } label: {
            HStack(spacing: 14) {
                SanctuaryGradientSwatch(mode: mode)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(palette.divider, lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(ABY.Font.captionSemibold)
                        Text(mode.label)
                            .font(ABY.Font.headline)
                    }
                    .foregroundStyle(palette.textPrimary)

                    Text(mode.subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                if selectedMode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .font(ABY.Font.title2)
                        .foregroundStyle(ABY.Color.orbSage)
                }
            }
            .padding(14)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .strokeBorder(
                        selectedMode == mode ? ABY.Color.orbSage.opacity(0.45) : palette.divider,
                        lineWidth: selectedMode == mode ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SanctuaryGradientSwatch: View {
    @Environment(\.sanctuaryPalette) private var palette
    let mode: SanctuaryGradientMode

    var body: some View {
        Group {
            if mode == .night {
                ZStack {
                    LinearGradient(
                        colors: [mode.gradientTop, mode.gradientMid, mode.gradientBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Circle()
                        .fill(ABY.Color.nightMeshPlum.opacity(0.45))
                        .blur(radius: 14)
                        .offset(x: 8, y: 6)
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 1.5, height: 1.5)
                        .offset(x: -12, y: -14)
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 1, height: 1)
                        .offset(x: 10, y: -8)
                }
            } else {
                LinearGradient(
                    colors: [mode.gradientTop, mode.gradientMid, mode.gradientBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        SanctuaryAppearanceSettingsView()
    }
}
