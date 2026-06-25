//
//  ChaplainScriptureComponents.swift
//  DevotionLock
//

import SwiftUI

struct ChaplainScriptureSearchIndicator: View {
    let label: String

    var body: some View {
        ChaplainPresenceIndicator(mode: .searchingScripture(label))
    }
}

struct ChaplainScriptureCitationCard: View {
    let citation: ChaplainScriptureCitation
    var onReadChapter: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil

    private var versionLabel: String {
        citation.version ?? (citation.source == .bibleAPI ? "KJV" : "Curated")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(citation.reference) · \(versionLabel)")
                    .font(ABY.Font.caption.weight(.medium))
                    .foregroundStyle(ABY.Color.textSecondary)
                Spacer(minLength: 0)
                Image(systemName: "book.closed.fill")
                    .font(ABY.Font.iconSmall)
                    .foregroundStyle(DevotionTheme.sage)
            }

            Text("\"\(citation.displayText)\"")
                .font(ABY.Font.editorialBody)
                .foregroundStyle(ABY.Color.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if onReadChapter != nil {
                    Button(action: { onReadChapter?() }) {
                        Label("Read chapter", systemImage: "text.book.closed")
                            .font(ABY.Font.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ABY.Color.linkBlue)
                }

                if onSave != nil {
                    Button(action: { onSave?() }) {
                        Label("Save", systemImage: "bookmark")
                            .font(ABY.Font.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ABY.Color.textSecondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

struct ChaplainScriptureCitationStack: View {
    let citations: [ChaplainScriptureCitation]
    var onReadChapter: ((ChaplainScriptureCitation) -> Void)? = nil
    var onSave: ((ChaplainScriptureCitation) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(citations) { citation in
                ChaplainScriptureCitationCard(
                    citation: citation,
                    onReadChapter: citation.bookSlug != nil ? { onReadChapter?(citation) } : nil,
                    onSave: { onSave?(citation) }
                )
            }
        }
    }
}
