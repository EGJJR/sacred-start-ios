//
//  VerseHighlightStore.swift
//  DevotionLock
//

import Foundation
import Observation

@Observable
@MainActor
final class VerseHighlightStore {
    static let shared = VerseHighlightStore()

    private enum Keys {
        static let highlights = "verseHighlights"
    }

    private(set) var highlights: [VerseHighlight] = []

    init() {
        load()
    }

    func highlights(bookSlug: String, chapter: Int) -> [VerseHighlight] {
        highlights.filter { $0.bookSlug == bookSlug && $0.chapter == chapter }
    }

    func color(for verse: Int, bookSlug: String, chapter: Int) -> ScriptureHighlightColor? {
        highlights(bookSlug: bookSlug, chapter: chapter)
            .first { $0.contains(verse) }?
            .color
    }

    func apply(
        color: ScriptureHighlightColor,
        range: ClosedRange<Int>,
        bookSlug: String,
        chapter: Int
    ) {
        highlights.removeAll { highlight in
            highlight.bookSlug == bookSlug
                && highlight.chapter == chapter
                && rangesOverlap(highlight.startVerse...highlight.endVerse, range)
        }

        highlights.append(VerseHighlight(
            id: UUID(),
            bookSlug: bookSlug,
            chapter: chapter,
            startVerse: range.lowerBound,
            endVerse: range.upperBound,
            colorID: color.rawValue,
            createdAt: Date()
        ))
        persist()
    }

    func clear(range: ClosedRange<Int>, bookSlug: String, chapter: Int) {
        let overlapping = highlights(bookSlug: bookSlug, chapter: chapter)
            .filter { rangesOverlap($0.startVerse...$0.endVerse, range) }

        for existing in overlapping {
            highlights.removeAll { $0.id == existing.id }
            let highlightRange = existing.startVerse...existing.endVerse
            let color = existing.color

            if highlightRange.lowerBound < range.lowerBound {
                let end = min(highlightRange.upperBound, range.lowerBound - 1)
                appendHighlight(
                    color: color,
                    range: highlightRange.lowerBound...end,
                    bookSlug: bookSlug,
                    chapter: chapter
                )
            }

            if highlightRange.upperBound > range.upperBound {
                let start = max(highlightRange.lowerBound, range.upperBound + 1)
                appendHighlight(
                    color: color,
                    range: start...highlightRange.upperBound,
                    bookSlug: bookSlug,
                    chapter: chapter
                )
            }
        }
        persist()
    }

    private func appendHighlight(
        color: ScriptureHighlightColor,
        range: ClosedRange<Int>,
        bookSlug: String,
        chapter: Int
    ) {
        guard range.lowerBound <= range.upperBound else { return }
        highlights.append(VerseHighlight(
            id: UUID(),
            bookSlug: bookSlug,
            chapter: chapter,
            startVerse: range.lowerBound,
            endVerse: range.upperBound,
            colorID: color.rawValue,
            createdAt: Date()
        ))
    }

    private func rangesOverlap(_ a: ClosedRange<Int>, _ b: ClosedRange<Int>) -> Bool {
        a.lowerBound <= b.upperBound && b.lowerBound <= a.upperBound
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Keys.highlights),
              let decoded = try? JSONDecoder().decode([VerseHighlight].self, from: data)
        else { return }
        highlights = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(highlights) else { return }
        UserDefaults.standard.set(data, forKey: Keys.highlights)
    }
}
