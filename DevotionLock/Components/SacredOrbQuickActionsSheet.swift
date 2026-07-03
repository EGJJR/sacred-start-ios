//
//  SacredOrbQuickActionsSheet.swift
//  DevotionLock
//
//  Mobbin refs:
//  ChatGPT attach sheet — https://mobbin.com/screens/cf94f6ed-ad32-48c1-ad40-e8ee75e9615a
//  Beside AI actions — https://mobbin.com/screens/3acbf481-e352-4a40-954c-b03348de8d4b
//  Fabric grouped menu — https://mobbin.com/screens/f2902335-d4e8-4f10-a540-8764198d023f
//  Obsidian action groups — https://mobbin.com/screens/09dec6de-5d1b-4020-922b-ad238e77263c
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
        case .morningDevotion: "Guided scripture and gratitude"
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

// MARK: - Bottom sheet (ChatGPT / Beside / Fabric)

struct SacredOrbQuickActionsSheet: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let actions: [SacredOrbQuickAction]
    var onSelect: (SacredOrbQuickAction) -> Void

    @State private var revealed = false

    private var sheetHeight: CGFloat {
        // Header + grouped list + bottom safe padding.
        let header: CGFloat = 92
        let row: CGFloat = 74
        let chrome: CGFloat = 36
        return header + CGFloat(actions.count) * row + chrome
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 18)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 10)

            actionGroup
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 20)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(palette.background.ignoresSafeArea())
        .presentationDetents([.height(min(sheetHeight, 520))])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(palette.background)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(named: "Dismiss") { dismiss() }
        .onAppear(perform: reveal)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    ABY.Color.meshSky.opacity(palette.isNight ? 0.28 : 0.35),
                                    ABY.Color.orbTeal.opacity(palette.isNight ? 0.22 : 0.28),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ABY.Color.meshSky, ABY.Color.meshPeriwinkle, ABY.Color.orbTeal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Begin here")
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)
            }

            Text("A quiet path for this moment.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .padding(.leading, 46)
        }
    }

    private var actionGroup: some View {
        VStack(spacing: 0) {
            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                SacredOrbSheetActionRow(action: action) {
                    select(action)
                }
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 8)
                .animation(
                    reduceMotion
                        ? nil
                        : AppTheme.springGentle.delay(0.04 + Double(index) * 0.035),
                    value: revealed
                )

                if index < actions.count - 1 {
                    Rectangle()
                        .fill(palette.divider.opacity(palette.isNight ? 0.55 : 0.9))
                        .frame(height: 0.5)
                        .padding(.leading, 68)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.cardFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    palette.navBarStrokeTop.opacity(palette.isNight ? 0.45 : 0.85),
                                    palette.navBarStrokeBottom.opacity(palette.isNight ? 0.2 : 0.3),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: .black.opacity(palette.isNight ? 0.28 : 0.06), radius: 16, y: 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func reveal() {
        guard !reduceMotion else {
            revealed = true
            return
        }
        withAnimation(AppTheme.springGentle.delay(0.04)) {
            revealed = true
        }
    }

    private func select(_ action: SacredOrbQuickAction) {
        DevotionHaptics.light()
        dismiss()
        // Let the sheet finish dismissing before presenting the next surface.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            onSelect(action)
        }
    }
}

// MARK: - Row

private struct SacredOrbSheetActionRow: View {
    @Environment(\.sanctuaryPalette) private var palette

    let action: SacredOrbQuickAction
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(action.tint.opacity(palette.isNight ? 0.22 : 0.14))

                    Image(systemName: action.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(action.tint)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textPrimary)

                    Text(action.subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.textTertiary.opacity(0.85))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(SacredOrbSheetRowStyle())
        .accessibilityLabel(action.title)
        .accessibilityHint(action.subtitle)
    }
}

private struct SacredOrbSheetRowStyle: ButtonStyle {
    @Environment(\.sanctuaryPalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                if configuration.isPressed {
                    palette.surfaceMuted.opacity(palette.isNight ? 0.35 : 0.55)
                }
            }
            .animation(AppTheme.springSnappy, value: configuration.isPressed)
    }
}

#if DEBUG
#Preview("Sheet light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SacredOrbQuickActionsSheet(
                actions: SacredOrbQuickAction.allCases,
                onSelect: { _ in }
            )
        }
        .abyScreen()
}

#Preview("Sheet evening") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SacredOrbQuickActionsSheet(
                actions: SacredOrbQuickAction.allCases,
                onSelect: { _ in }
            )
            .environment(\.sanctuaryPalette, .night)
            .preferredColorScheme(.dark)
        }
}
#endif
