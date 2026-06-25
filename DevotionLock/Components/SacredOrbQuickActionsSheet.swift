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

struct SacredOrbQuickActionsSheet: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let actions: [SacredOrbQuickAction]
    var onSelect: (SacredOrbQuickAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(palette.divider.opacity(0.55))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 18)

            Text("Sacred shortcuts")
                .font(ABY.Font.editorialTitle)
                .foregroundStyle(palette.textPrimary)
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 6)

            Text("Hold the orb for quick capture — tap it for today's next step.")
                .font(ABY.Font.footnote)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(3)
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 20)

            VStack(spacing: 10) {
                ForEach(actions) { action in
                    Button {
                        DevotionHaptics.light()
                        onSelect(action)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: action.icon)
                                .font(ABY.Font.headline)
                                .foregroundStyle(action.tint)
                                .frame(width: 40, height: 40)
                                .background(action.tint.opacity(0.14))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(action.title)
                                    .font(ABY.Font.calloutSemibold)
                                    .foregroundStyle(palette.textPrimary)
                                Text(action.subtitle)
                                    .font(ABY.Font.caption)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(ABY.Font.captionSemibold)
                                .foregroundStyle(palette.textTertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(palette.surface.opacity(0.94))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(palette.divider.opacity(0.45), lineWidth: 1)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .accessibilityAction(named: "Dismiss") { dismiss() }
    }
}

#if DEBUG
#Preview {
    SacredOrbQuickActionsSheet(
        actions: SacredOrbQuickAction.allCases,
        onSelect: { _ in }
    )
}
#endif
