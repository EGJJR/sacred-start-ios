//
//  ScriptureBrowseComponents.swift
//  DevotionLock
//
//  Mobbin-informed scripture UI: Headway nav, Goodreads tiles, Fable rows, Medium topics.
//

import SwiftUI

// MARK: - Bottom navigation (Headway / Blinkist)

enum ScriptureTab: String, CaseIterable, Identifiable {
    case discover = "Discover"
    case books = "Books"
    case library = "Library"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .discover: "sparkle.magnifyingglass"
        case .books: "book.closed"
        case .library: "bookmark"
        }
    }
}

struct ScriptureTabBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var selection: ScriptureTab
    var libraryCount: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ScriptureTab.allCases) { tab in
                Button {
                    withAnimation(AppTheme.springSnappy) { selection = tab }
                    DevotionHaptics.light()
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 17, weight: selection == tab ? .semibold : .regular))
                            if tab == .library, libraryCount > 0 {
                                Text("\(min(libraryCount, 99))")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(ABY.Color.pillTeal)
                                    .clipShape(Capsule())
                                    .offset(x: 8, y: -6)
                            }
                        }
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: selection == tab ? .semibold : .medium))
                    }
                    .foregroundStyle(selection == tab ? palette.textPrimary : palette.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selection == tab
                            ? palette.surface.opacity(0.9)
                            : Color.clear,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

// MARK: - Search field (Blinkist / Audible)

struct ScriptureSearchField: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var text: String
    var placeholder = "John 3:16, peace, or gratitude"
    var focus: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(palette.textSecondary)
            TextField(placeholder, text: $text)
                .focused(focus)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(palette.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
    }
}

// MARK: - Reference banner (Apple Books in-book search)

struct ScriptureReferenceBanner: View {
    let reference: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ABY.Color.pillTeal)
                    .frame(width: 36, height: 36)
                    .background(ABY.Color.pillTeal.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Open reference")
                        .font(ABY.Font.caption)
                        .foregroundStyle(ABY.Color.textSecondary)
                    Text(reference)
                        .font(ABY.Font.body.weight(.semibold))
                        .foregroundStyle(ABY.Color.textPrimary)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(paletteMuted)
            }
            .padding(14)
            .background(ABY.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(ABY.Color.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var paletteMuted: Color { ABY.Color.textTertiary }
}

// MARK: - Topic grid (Goodreads genres / Headway collections)

struct ScriptureTopicGrid: View {
    @Environment(\.sanctuaryPalette) private var palette
    let topics: [PassageTopic]
    var selected: PassageTopic?
    var onSelect: (PassageTopic?) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ScriptureTopicTile(
                label: "All topics",
                icon: "square.grid.2x2",
                tint: palette.textSecondary,
                isSelected: selected == nil
            ) { onSelect(nil) }

            ForEach(topics) { topic in
                ScriptureTopicTile(
                    label: topic.label,
                    icon: topic.icon,
                    tint: topic.tint,
                    isSelected: selected == topic
                ) { onSelect(selected == topic ? nil : topic) }
            }
        }
    }
}

private struct ScriptureTopicTile: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String
    let icon: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(ABY.Font.callout.weight(.medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? .white : palette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    tint
                } else {
                    ZStack {
                        tint.opacity(0.18)
                        palette.surface.opacity(0.55)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.clear : palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Testament tiles (Goodreads genre cards)

struct ScriptureTestamentTile: View {
    let testament: BibleTestament
    let bookCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 108)

                VStack(alignment: .leading, spacing: 4) {
                    Text(testament.label)
                        .font(ABY.Font.headline)
                        .foregroundStyle(.white)
                    Text("\(bookCount) books")
                        .font(ABY.Font.caption)
                        .foregroundStyle(.white.opacity(0.82))
                }
                .padding(16)
            }
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var gradientColors: [Color] {
        switch testament {
        case .old:
            [ABY.Color.pillPurple.opacity(0.85), ABY.Color.meshLavender.opacity(0.7)]
        case .new:
            [ABY.Color.pillTeal.opacity(0.85), ABY.Color.meshSage.opacity(0.65)]
        }
    }
}

// MARK: - List row (Fable / Blinkist)

struct ScriptureListRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let badge: String
    let title: String
    let subtitle: String
    var badgeTint: Color = ABY.Color.pillTeal
    var trailingIcon: String = "chevron.right"
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { rowContent }
                    .buttonStyle(ScaleButtonStyle())
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            Text(badge)
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(badgeTint)
                .frame(width: 40, height: 40)
                .background(badgeTint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(ABY.Font.body.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: trailingIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.textTertiary)
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

// MARK: - Section header (Blinkist "Top matches")

struct ScriptureSectionHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    var count: Int? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(ABY.Font.section)
                .tracking(0.6)
                .foregroundStyle(palette.textSecondary)
            if let count {
                Text("\(count)")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textTertiary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(palette.surface)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }
}

// MARK: - Passage card (stoic / Medium — serif-first)

struct ScripturePassageCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let passage: SpiritualPassage
    let isPickable: Bool
    var isSaved = false
    var onSave: (() -> Void)? = nil
    let action: () -> Void

    var body: some View {
        Group {
            if isPickable {
                Button(action: action) { cardBody }
                    .buttonStyle(ScaleButtonStyle())
            } else {
                cardBody
            }
        }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                if let topic = passage.topics.first {
                    Label(topic.label, systemImage: topic.icon)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(topic.tint)
                }
                Spacer()
                if let onSave {
                    Button(action: onSave) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isSaved ? ABY.Color.pillTeal : palette.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 12)

            Text(passage.text)
                .font(.system(size: 19, weight: .regular, design: .serif))
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text(passage.attribution)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
                Spacer()
                if isPickable {
                    Text("Use this →")
                        .font(ABY.Font.caption.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)
                }
            }
            .padding(.top, 14)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
    }
}

// MARK: - Grouped list card container

struct ScriptureGroupedList<Content: View>: View {
    @Environment(\.sanctuaryPalette) private var palette
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
    }
}

// MARK: - Book helpers

extension BibleBook {
    var abbreviation: String {
        let words = name.split(separator: " ")
        if words.count >= 2, let first = words.first, first.allSatisfy(\.isNumber) {
            return "\(first)\(words[1].prefix(1))"
        }
        return String(name.prefix(2))
    }
}

enum ScriptureQuickBook {
    static let shortcuts: [(slug: String, label: String)] = [
        ("psalms", "Psalms"),
        ("john", "John"),
        ("romans", "Romans"),
        ("proverbs", "Proverbs"),
    ]

    static func book(for slug: String) -> BibleBook? {
        BibleBookCatalog.book(slug: slug)
    }
}
