//
//  VerseHighlightComponents.swift
//  DevotionLock
//
//  Mobbin: Fable text selection toolbar + color picker, Medium soft highlights, Headway save flow.
//

import SwiftUI

// MARK: - Floating selection toolbar (Fable / Headway)

struct VerseSelectionToolbar: View {
    @Environment(\.sanctuaryPalette) private var palette

    let selectionLabel: String
    var onHighlight: (ScriptureHighlightColor) -> Void
    var onSave: () -> Void
    var onShare: () -> Void
    var onClear: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ForEach(ScriptureHighlightColor.allCases) { color in
                    Button {
                        DevotionHaptics.light()
                        onHighlight(color)
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(color.swatch)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Circle().stroke(.white.opacity(0.35), lineWidth: 1)
                                }
                            Text(color.label)
                                .font(ABY.Font.micro)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                toolbarButton("Save", icon: "bookmark") { onSave() }
                divider
                toolbarButton("Share", icon: "square.and.arrow.up") { onShare() }
                divider
                toolbarButton("Clear", icon: "xmark") { onClear() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
        .overlay(alignment: .top) {
            Text(selectionLabel)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .offset(y: -28)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.divider)
            .frame(width: 1, height: 28)
    }

    private func toolbarButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(ABY.Font.calloutMedium)
                Text(title)
                    .font(ABY.Font.captionMedium)
            }
            .foregroundStyle(palette.textPrimary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Verse row with highlight + selection handles (Fable / Medium)

struct HighlightedVerseRow: View {
    @Environment(\.sanctuaryPalette) private var palette

    let verse: BibleVerse
    let highlightColor: ScriptureHighlightColor?
    let isSelected: Bool
    let isRangeStart: Bool
    let isRangeEnd: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                ZStack(alignment: .top) {
                    if isRangeStart || isRangeEnd {
                        Circle()
                            .fill(ABY.Color.pillTeal)
                            .frame(width: 8, height: 8)
                            .offset(y: 6)
                    }
                    Text(verse.verse)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(verseNumberColor)
                        .frame(width: 24, alignment: .trailing)
                        .padding(.top, 4)
                }

                Text(verse.text)
                    .font(ABY.Font.editorialHeadline)
                    .foregroundStyle(palette.textPrimary)
                    .lineSpacing(7)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ABY.Color.pillTeal.opacity(0.55), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var verseNumberColor: Color {
        if isSelected { return ABY.Color.pillTeal }
        if highlightColor != nil { return ABY.Color.pillTeal.opacity(0.8) }
        return palette.textTertiary
    }

    private var backgroundColor: Color {
        if isSelected {
            return ABY.Color.pillTeal.opacity(0.14)
        }
        if let highlightColor {
            return highlightColor.background
        }
        return Color.clear
    }
}
