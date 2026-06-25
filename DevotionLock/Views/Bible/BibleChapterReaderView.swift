//
//  BibleChapterReaderView.swift
//  DevotionLock
//

import SwiftUI

struct BibleReaderPresentation: Identifiable, Hashable {
    let id = UUID()
    let content: BibleChapterContent
    let highlightReference: String?

    static func == (lhs: BibleReaderPresentation, rhs: BibleReaderPresentation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(content: BibleChapterContent, highlightReference: String?) {
        self.content = content
        self.highlightReference = highlightReference
    }
}

struct BibleChapterReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    let content: BibleChapterContent
    let highlightReference: String?
    var embedInNavigationStack: Bool = true

    @State private var versesRevealed = false
    @State private var selectionAnchor: Int?
    @State private var selectedVerseNumbers = Set<Int>()

    private var highlightStore: VerseHighlightStore { VerseHighlightStore.shared }

    private var headerLabel: String {
        let version = content.version == "en-kjv" ? "KJV" : content.version.uppercased()
        if let highlightReference {
            return "\(highlightReference.uppercased()) · \(version)"
        }
        return "CHAPTER \(content.chapter) · \(content.bookName.uppercased()) · \(version)"
    }

    private var selectionRange: ClosedRange<Int>? {
        guard let lo = selectedVerseNumbers.min(),
              let hi = selectedVerseNumbers.max()
        else { return nil }
        return lo...hi
    }

    private var activeVerses: [BibleVerse] {
        let selected = content.verses.filter { selectedVerseNumbers.contains($0.verseNumber) }
        return selected.isEmpty ? content.verses : selected.sorted { $0.verseNumber < $1.verseNumber }
    }

    private var saveReference: String {
        referenceLabel(for: activeVerses)
    }

    private var isCurrentSelectionSaved: Bool {
        ScriptureLibraryStore.shared.isSaved(reference: saveReference)
    }

    private var selectionLabel: String {
        guard let range = selectionRange else { return "" }
        if range.lowerBound == range.upperBound {
            return "Verse \(range.lowerBound)"
        }
        return "Verses \(range.lowerBound)–\(range.upperBound)"
    }

    var body: some View {
        Group {
            if embedInNavigationStack {
                NavigationStack { readerScaffold }
            } else {
                readerScaffold
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                versesRevealed = true
            }
        }
    }

    private var readerScaffold: some View {
        ZStack {
            readerBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(headerLabel)
                        .font(ABY.Font.section)
                        .tracking(1.2)
                        .foregroundStyle(palette.textSecondary)
                        .blurRevealOnAppear(index: 0, stagger: 0.04)

                    if highlightReference == nil {
                        Text("Chapter \(content.chapter)")
                            .font(ABY.Font.editorialTitle)
                            .foregroundStyle(palette.textPrimary)
                            .blurRevealOnAppear(index: 1, stagger: 0.04)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(content.verses.enumerated()), id: \.element.id) { index, verse in
                            verseRow(verse, index: index)
                        }
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 12)
                .padding(.bottom, selectedVerseNumbers.isEmpty ? 120 : 220)
            }

            VStack(spacing: 12) {
                Spacer()

                if !selectedVerseNumbers.isEmpty, let range = selectionRange {
                    VerseSelectionToolbar(
                        selectionLabel: selectionLabel,
                        onHighlight: { color in
                            applyHighlight(color, range: range)
                        },
                        onSave: { toggleSave() },
                        onShare: { shareText() },
                        onClear: { clearSelectionAndHighlights(range: range) }
                    )
                    .padding(.horizontal, ABY.Spacing.screen)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    GlassActionBar(items: actionItems)
                        .padding(.horizontal, ABY.Spacing.screen)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 24)
            .animation(AppTheme.springSnappy, value: selectedVerseNumbers.isEmpty)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if embedInNavigationStack {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func verseRow(_ verse: BibleVerse, index: Int) -> some View {
        let number = verse.verseNumber
        let isSelected = selectedVerseNumbers.contains(number)
        let range = selectionRange
        let isRangeStart = range.map { number == $0.lowerBound && selectedVerseNumbers.count > 1 } ?? false
        let isRangeEnd = range.map { number == $0.upperBound && selectedVerseNumbers.count > 1 } ?? false
        let savedColor = highlightStore.color(
            for: number,
            bookSlug: content.bookSlug,
            chapter: content.chapter
        )

        return HighlightedVerseRow(
            verse: verse,
            highlightColor: isSelected ? nil : savedColor,
            isSelected: isSelected,
            isRangeStart: isRangeStart,
            isRangeEnd: isRangeEnd,
            onTap: { handleVerseTap(number) }
        )
        .blurReveal(versesRevealed, blurRadius: 14, scale: 1.02)
        .animation(
            .easeOut(duration: 0.5).delay(Double(index) * 0.05),
            value: versesRevealed
        )
    }

    private func handleVerseTap(_ number: Int) {
        DevotionHaptics.light()
        withAnimation(AppTheme.springSnappy) {
            if selectedVerseNumbers.count == 1, selectedVerseNumbers.contains(number) {
                clearSelection()
                return
            }

            if selectedVerseNumbers.count > 1, !selectedVerseNumbers.contains(number) {
                selectionAnchor = number
                selectedVerseNumbers = [number]
                return
            }

            if let anchor = selectionAnchor {
                let lo = min(anchor, number)
                let hi = max(anchor, number)
                selectedVerseNumbers = Set(lo...hi)
            } else {
                selectionAnchor = number
                selectedVerseNumbers = [number]
            }
        }
    }

    private func clearSelection() {
        selectionAnchor = nil
        selectedVerseNumbers = []
    }

    private func applyHighlight(_ color: ScriptureHighlightColor, range: ClosedRange<Int>) {
        DevotionHaptics.light()
        highlightStore.apply(
            color: color,
            range: range,
            bookSlug: content.bookSlug,
            chapter: content.chapter
        )
        clearSelection()
    }

    private func clearSelectionAndHighlights(range: ClosedRange<Int>) {
        DevotionHaptics.light()
        highlightStore.clear(range: range, bookSlug: content.bookSlug, chapter: content.chapter)
        clearSelection()
    }

    private var readerBackground: some View {
        ABYBackground(style: .tabShell)
    }

    private var actionItems: [GlassActionBarItem] {
        [
            GlassActionBarItem(
                id: "save",
                title: isCurrentSelectionSaved ? "Saved" : "Save",
                icon: isCurrentSelectionSaved ? "bookmark.fill" : "bookmark"
            ) {
                toggleSave()
            },
            GlassActionBarItem(id: "share", title: "Share", icon: "square.and.arrow.up") {
                shareText()
            },
            GlassActionBarItem(id: "copy", title: "Copy", icon: "doc.on.doc") {
                copyText()
            },
        ]
    }

    private var shareBody: String {
        let text = activeVerses.map(\.text).joined(separator: " ")
        return "\(text)\n\n— \(saveReference) (KJV)"
    }

    private func referenceLabel(for verses: [BibleVerse]) -> String {
        if let highlightReference, verses.count == content.verses.count {
            return highlightReference
        }

        let sorted = verses.sorted { $0.verseNumber < $1.verseNumber }
        guard let first = sorted.first else {
            return "\(content.bookName) \(content.chapter)"
        }

        if sorted.count == content.verses.count, highlightReference == nil {
            return "\(content.bookName) \(content.chapter)"
        }

        if sorted.count == 1 {
            return "\(content.bookName) \(content.chapter):\(first.verse)"
        }

        if let last = sorted.last, first.verseNumber != last.verseNumber {
            return "\(content.bookName) \(content.chapter):\(first.verse)-\(last.verse)"
        }

        return "\(content.bookName) \(content.chapter):\(first.verse)"
    }

    private func toggleSave() {
        DevotionHaptics.light()
        _ = ScriptureLibraryStore.shared.toggleBible(
            verses: activeVerses,
            content: content,
            reference: saveReference
        )
        clearSelection()
    }

    private func shareText() {
        DevotionHaptics.light()
        let controller = UIActivityViewController(activityItems: [shareBody], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(controller, animated: true)
        }
    }

    private func copyText() {
        DevotionHaptics.light()
        UIPasteboard.general.string = shareBody
    }
}
