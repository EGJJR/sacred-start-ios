//
//  GuidedPrayerViews.swift
//  DevotionLock
//

import SwiftUI

struct GuidedPrayersSection: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onSelect: (GuidedPrayer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ABYSectionHeader(title: "Guided prayers")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(GuidedPrayerCatalog.all) { prayer in
                        GuidedPrayerCard(prayer: prayer) {
                            onSelect(prayer)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

private struct GuidedPrayerCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let prayer: GuidedPrayer
    let action: () -> Void

    private var tint: Color {
        Color(
            red: Double((prayer.tintHex >> 16) & 0xFF) / 255,
            green: Double((prayer.tintHex >> 8) & 0xFF) / 255,
            blue: Double(prayer.tintHex & 0xFF) / 255
        )
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: prayer.icon)
                    .font(ABY.Font.headline)
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12))
                    .clipShape(Circle())

                Text(prayer.title)
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.leading)

                Text(prayer.subtitle)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(width: 168, alignment: .leading)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PassageBrowseCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(ABY.Font.bodySemibold)
                    .foregroundStyle(ABY.Color.pillPurple)
                    .frame(width: 40, height: 40)
                    .background(ABY.Color.pillPurple.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Passages & promises")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("Search Scripture and wisdom by theme")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(ABY.Font.footnoteSemibold)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct GuidedPrayerFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    let prayer: GuidedPrayer
    var onComplete: () -> Void

    @State private var stepIndex = 0
    @State private var appeared = false

    private var tint: Color {
        Color(
            red: Double((prayer.tintHex >> 16) & 0xFF) / 255,
            green: Double((prayer.tintHex >> 8) & 0xFF) / 255,
            blue: Double(prayer.tintHex & 0xFF) / 255
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ABYCleanGradientBackground().ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer(minLength: 12)

                    VStack(spacing: 12) {
                        Image(systemName: prayer.icon)
                            .font(ABY.Font.title)
                            .foregroundStyle(tint)
                            .frame(width: 64, height: 64)
                            .background(tint.opacity(0.12))
                            .clipShape(Circle())

                        Text(prayer.title)
                            .font(ABY.Font.title2)
                            .foregroundStyle(palette.textPrimary)

                        Text("Step \(stepIndex + 1) of \(prayer.steps.count)")
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(palette.textTertiary)
                    }

                    Text(prayer.steps[stepIndex])
                        .font(ABY.Font.editorialHeadline)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 28)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(AppTheme.springGentle, value: stepIndex)

                    Spacer()

                    HStack(spacing: 6) {
                        ForEach(0..<prayer.steps.count, id: \.self) { index in
                            Capsule()
                                .fill(index <= stepIndex ? tint : palette.divider)
                                .frame(width: index == stepIndex ? 20 : 6, height: 6)
                                .animation(AppTheme.springSnappy, value: stepIndex)
                        }
                    }

                    Button(action: advance) {
                        Text(stepIndex == prayer.steps.count - 1 ? "Amen" : "Continue")
                            .font(ABY.Font.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(tint)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }

    private func advance() {
        if stepIndex < prayer.steps.count - 1 {
            withAnimation(AppTheme.springSnappy) { stepIndex += 1 }
            DevotionHaptics.light()
        } else {
            onComplete()
            DevotionHaptics.success()
            dismiss()
        }
    }
}
