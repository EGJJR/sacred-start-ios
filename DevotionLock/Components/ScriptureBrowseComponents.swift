//
//  ScriptureBrowseComponents.swift
//  DevotionLock
//
//  Mobbin-informed scripture UI: TIDE glass on tab wash, Deepstash chips, stoic passage cards.
//

import SwiftUI

// MARK: - Glass chrome (TIDE / ABY tab bar)

private struct ScriptureGlassSurface: View {
    var cornerRadius: CGFloat = ABY.Radius.cardLarge

    var body: some View {
        ABYGlassBarBackground(cornerRadius: cornerRadius)
    }
}

// MARK: - Bottom navigation (TIDE floating glass bar)

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
                                .font(AppFont.font(size: 17, weight: selection == tab ? AppFont.Weight.semibold : AppFont.Weight.regular))
                            if tab == .library, libraryCount > 0 {
                                Text("\(min(libraryCount, 99))")
                                    .font(ABY.Font.microBold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(ABY.Color.pillTeal)
                                    .clipShape(Capsule())
                                    .offset(x: 8, y: -6)
                            }
                        }
                        Text(tab.rawValue)
                            .font(AppFont.font(size: 10, weight: selection == tab ? AppFont.Weight.semibold : AppFont.Weight.medium))
                    }
                    .foregroundStyle(selection == tab ? palette.textPrimary : palette.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selection == tab {
                            Capsule()
                                .fill(palette.surface.opacity(0.94))
                                .overlay {
                                    Capsule()
                                        .strokeBorder(palette.divider.opacity(0.4), lineWidth: 0.5)
                                }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background {
            ScriptureGlassSurface(cornerRadius: 999)
        }
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
                .font(ABY.Font.bodyMedium)
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
        .background {
            ScriptureGlassSurface(cornerRadius: 14)
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
                    .font(ABY.Font.headline)
                    .foregroundStyle(ABY.Color.pillTeal)
                    .frame(width: 36, height: 36)
                    .background(ABY.Color.pillTeal.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Open reference")
                        .font(ABY.Font.caption)
                        .foregroundStyle(ABY.Color.textSecondary)
                    Text(reference)
                        .font(ABY.Font.bodySemibold)
                        .foregroundStyle(ABY.Color.textPrimary)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(ABY.Font.footnoteSemibold)
                    .foregroundStyle(paletteMuted)
            }
            .padding(14)
            .background {
                ScriptureGlassSurface(cornerRadius: ABY.Radius.cardLarge)
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
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(isSelected ? .white : tint)
                Text(label)
                    .font(ABY.Font.calloutMedium)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? .white : palette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint)
                } else {
                    ScriptureGlassSurface(cornerRadius: 14)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Testament tiles (Goodreads genre cards)

struct ScriptureTestamentTile: View {
    @Environment(\.sanctuaryPalette) private var palette

    let testament: BibleTestament
    let bookCount: Int
    let action: () -> Void

    private var accentTint: Color {
        testament == .old ? ABY.Color.pillPurple : ABY.Color.pillTeal
    }

    private var badge: String {
        testament == .old ? "OT" : "NT"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(badge)
                    .font(ABY.Font.editorialFootnote)
                    .foregroundStyle(accentTint)
                    .frame(width: 40, height: 40)
                    .background(accentTint.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(testament.label)
                        .font(ABY.Font.bodySemibold)
                        .foregroundStyle(palette.textPrimary)
                    Text("\(bookCount) books")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(ABY.Font.captionSemibold)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ScriptureGlassSurface(cornerRadius: ABY.Radius.cardLarge)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - List row (Fable / Blinkist)

struct ScriptureNavigationRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(AppTheme.springSnappy, value: configuration.isPressed)
    }
}

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
                .font(ABY.Font.editorialFootnote)
                .foregroundStyle(badgeTint)
                .frame(width: 40, height: 40)
                .background(badgeTint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(ABY.Font.bodySemibold)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: trailingIcon)
                .font(ABY.Font.captionSemibold)
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
                    .background {
                        Capsule()
                            .fill(palette.navBarFill.opacity(0.7))
                            .background { Capsule().fill(.ultraThinMaterial).opacity(0.5) }
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(palette.navBarStrokeTop.opacity(0.5), lineWidth: 0.5)
                    }
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
                            .font(ABY.Font.bodyMedium)
                            .foregroundStyle(isSaved ? ABY.Color.pillTeal : palette.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 12)

            Text(passage.text)
                .font(ABY.Font.editorialSubhead)
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
                        .font(ABY.Font.captionSemibold)
                        .foregroundStyle(palette.textPrimary)
                }
            }
            .padding(.top, 14)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ScriptureGlassSurface(cornerRadius: ABY.Radius.cardLarge)
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
        .background {
            ScriptureGlassSurface(cornerRadius: ABY.Radius.cardLarge)
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
