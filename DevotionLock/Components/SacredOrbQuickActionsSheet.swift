//
//  SacredOrbQuickActionsSheet.swift
//  DevotionLock
//

import SwiftUI

enum SacredOrbQuickAction: String, Identifiable, CaseIterable {
    case morningDevotion
    case journalCapture
    case assistedWrite
    case voiceNote
    case eveningReflection
    case chaplain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morningDevotion: "Morning devotion"
        case .journalCapture: "Add to journal"
        case .assistedWrite: "Assisted write"
        case .voiceNote: "Voice note"
        case .eveningReflection: "Evening reflection"
        case .chaplain: "Talk with Chaplain"
        }
    }

    var subtitle: String {
        switch self {
        case .morningDevotion: "Guided scripture & gratitude"
        case .journalCapture: "Choose how to capture"
        case .assistedWrite: "Gentle writing prompts"
        case .voiceNote: "Speak, then transcribe"
        case .eveningReflection: "Close the day in stillness"
        case .chaplain: "Continue or begin anew"
        }
    }

    var icon: String {
        switch self {
        case .morningDevotion: "sun.horizon.fill"
        case .journalCapture: "square.and.pencil"
        case .assistedWrite: "text.quote"
        case .voiceNote: "waveform"
        case .eveningReflection: "moon.stars.fill"
        case .chaplain: "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .morningDevotion: ABY.Color.pillTeal
        case .journalCapture: ABY.Color.pillOrange
        case .assistedWrite: ABY.Color.pillPurple
        case .voiceNote: ABY.Color.pillPink
        case .eveningReflection: ABY.Color.pillPurple
        case .chaplain: ABY.Color.orbTeal
        }
    }
}

// MARK: - Overlay (springs from orb — no sheet swipe)

struct SacredOrbQuickActionsOverlay: View {
    @Environment(\.sanctuaryPalette) private var palette

    let actions: [SacredOrbQuickAction]
    var onSelect: (SacredOrbQuickAction) -> Void
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Invisible tap catcher — dismiss without dimming the whole screen.
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    DevotionHaptics.soft()
                    onDismiss()
                }

            SacredOrbQuickActionsCard(
                actions: actions,
                onSelect: onSelect
            )
            .padding(.trailing, ABY.Spacing.screen)
            .padding(.bottom, 92)
        }
        .accessibilityAddTraits(.isModal)
    }
}

// MARK: - Shared card

private struct SacredOrbQuickActionsCard: View {
    @Environment(\.sanctuaryPalette) private var palette

    let actions: [SacredOrbQuickAction]
    var onSelect: (SacredOrbQuickAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)

            cardDivider

            VStack(spacing: 0) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    SacredOrbQuickActionRow(action: action) {
                        DevotionHaptics.light()
                        onSelect(action)
                    }

                    if index < actions.count - 1 {
                        cardDivider
                            .padding(.leading, 68)
                    }
                }
            }
        }
        .frame(width: 318, alignment: .leading)
        .background { cardBackground }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ABY.Color.orbTeal)

                Text("Sacred shortcuts")
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
            }

            Text("Choose how to capture this moment")
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textSecondary)
        }
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(palette.divider.opacity(palette.isNight ? 0.9 : 0.65))
            .frame(height: 0.5)
    }

    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(palette.isNight ? palette.surfaceElevated : Color.white.opacity(0.94))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                palette.navBarStrokeTop,
                                palette.navBarStrokeBottom,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: .black.opacity(palette.isNight ? 0.42 : 0.14), radius: 32, y: 14)
            .shadow(color: .black.opacity(palette.isNight ? 0.2 : 0.05), radius: 8, y: 3)
    }
}

// MARK: - Sheet (design tour / previews)

struct SacredOrbQuickActionsSheet: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let actions: [SacredOrbQuickAction]
    var onSelect: (SacredOrbQuickAction) -> Void

    var body: some View {
        SacredOrbQuickActionsCard(actions: actions, onSelect: onSelect)
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .accessibilityAction(named: "Dismiss") { dismiss() }
    }
}

private struct SacredOrbQuickActionRow: View {
    @Environment(\.sanctuaryPalette) private var palette

    let action: SacredOrbQuickAction
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    action.tint.opacity(palette.isNight ? 0.28 : 0.20),
                                    action.tint.opacity(palette.isNight ? 0.10 : 0.06),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: action.icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(action.tint)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(action.title)
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textPrimary)

                    Text(action.subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredOrbQuickActionRowStyle())
    }
}

private struct SacredOrbQuickActionRowStyle: ButtonStyle {
    @Environment(\.sanctuaryPalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                if configuration.isPressed {
                    palette.surfaceMuted.opacity(palette.isNight ? 0.55 : 0.75)
                }
            }
    }
}

#if DEBUG
#Preview("Overlay light") {
    ZStack(alignment: .bottom) {
        ABYFlatTabWashBackground()
        SacredOrbQuickActionsOverlay(
            actions: SacredOrbQuickAction.allCases,
            onSelect: { _ in },
            onDismiss: {}
        )
    }
    .abyScreen()
}

#Preview("Overlay evening") {
    ZStack(alignment: .bottom) {
        ABYEveningReflectionBackground()
        SacredOrbQuickActionsOverlay(
            actions: SacredOrbQuickAction.allCases,
            onSelect: { _ in },
            onDismiss: {}
        )
    }
    .environment(\.sanctuaryPalette, .night)
    .preferredColorScheme(.dark)
}

#Preview("Sheet") {
    SacredOrbQuickActionsSheet(
        actions: SacredOrbQuickAction.allCases,
        onSelect: { _ in }
    )
}
#endif
