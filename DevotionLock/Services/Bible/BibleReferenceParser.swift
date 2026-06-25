//
//  BibleReferenceParser.swift
//  DevotionLock
//

import Foundation

struct ParsedBibleReference: Equatable {
    let bookSlug: String
    let bookName: String
    let chapter: Int
    let verse: Int?
    let endVerse: Int?

    var displayReference: String {
        let base = "\(bookName) \(chapter)"
        guard let verse else { return base }
        if let endVerse, endVerse != verse {
            return "\(base):\(verse)-\(endVerse)"
        }
        return "\(base):\(verse)"
    }
}

enum BibleReferenceParser {
    /// Returns a parsed reference when the query looks like "John 3:16", "Psalm 23", "1 Cor 13:4-7", etc.
    static func parse(_ input: String) -> ParsedBibleReference? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.contains(where: \.isNumber) else { return nil }

        let pattern = #"^(?:(\d)\s+)?([A-Za-z][A-Za-z.\s]*?)\s+(\d{1,3})(?::(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed))
        else { return nil }

        func group(_ index: Int) -> String? {
            let range = match.range(at: index)
            guard range.location != NSNotFound, let swiftRange = Range(range, in: trimmed) else { return nil }
            return String(trimmed[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let leadingNumber = group(1)
        var bookPart = group(2) ?? ""
        if let leadingNumber, !bookPart.isEmpty {
            bookPart = "\(leadingNumber) \(bookPart)"
        } else if let leadingNumber {
            bookPart = leadingNumber
        }

        guard let chapterStr = group(3), let chapter = Int(chapterStr),
              let slug = BibleBookCatalog.resolveSlug(from: bookPart),
              let book = BibleBookCatalog.book(slug: slug)
        else { return nil }

        let verse = group(4).flatMap(Int.init)
        let endVerse = group(5).flatMap(Int.init)

        guard chapter >= 1, chapter <= book.chapterCount else { return nil }
        if let verse, verse < 1 { return nil }
        if let endVerse, endVerse < (verse ?? 1) { return nil }

        return ParsedBibleReference(
            bookSlug: slug,
            bookName: book.name,
            chapter: chapter,
            verse: verse,
            endVerse: endVerse
        )
    }

    /// True when the trimmed query is unambiguously a Bible reference (not a keyword like "peace").
    static func looksLikeReference(_ input: String) -> Bool {
        parse(input) != nil
    }

    /// Finds an embedded reference like "John 3:16" inside natural language.
    static func extractReference(from input: String) -> ParsedBibleReference? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.contains(where: \.isNumber) else { return nil }

        let pattern = #"(?:(\d)\s+)?([A-Za-z][A-Za-z.\s]*?)\s+(\d{1,3})(?::(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        let matches = regex.matches(in: trimmed, range: range)
        for match in matches {
            func group(_ index: Int) -> String? {
                let matchRange = match.range(at: index)
                guard matchRange.location != NSNotFound, let swiftRange = Range(matchRange, in: trimmed) else { return nil }
                return String(trimmed[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let leadingNumber = group(1)
            var bookPart = group(2) ?? ""
            if let leadingNumber, !bookPart.isEmpty {
                bookPart = "\(leadingNumber) \(bookPart)"
            } else if let leadingNumber {
                bookPart = leadingNumber
            }

            guard let chapterStr = group(3), let chapter = Int(chapterStr),
                  let slug = BibleBookCatalog.resolveSlug(from: bookPart),
                  let book = BibleBookCatalog.book(slug: slug)
            else { continue }

            let verse = group(4).flatMap(Int.init)
            let endVerse = group(5).flatMap(Int.init)

            guard chapter >= 1, chapter <= book.chapterCount else { continue }
            if let verse, verse < 1 { continue }
            if let endVerse, endVerse < (verse ?? 1) { continue }

            return ParsedBibleReference(
                bookSlug: slug,
                bookName: book.name,
                chapter: chapter,
                verse: verse,
                endVerse: endVerse
            )
        }

        return nil
    }
}
