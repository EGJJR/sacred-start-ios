//
//  SavedScripture.swift
//  DevotionLock
//

import Foundation

struct SavedScripture: Identifiable, Codable, Equatable {
    enum Source: String, Codable {
        case bible
        case curated

        var label: String {
            switch self {
            case .bible: "Scripture"
            case .curated: "Saved passage"
            }
        }
    }

    let id: UUID
    let savedAt: Date
    let source: Source
    let text: String
    let reference: String

    /// bible-api slug for reopening in reader
    let bookSlug: String?
    let chapter: Int?
    let startVerse: Int?
    let endVerse: Int?
    let version: String?

    /// Curated catalog id when saved from SpiritualPassageCatalog
    let catalogPassageID: String?

    var dedupKey: String {
        if let catalogPassageID { return "curated:\(catalogPassageID)" }
        return "bible:\(reference.lowercased())"
    }

    static func fromBible(
        verses: [BibleVerse],
        content: BibleChapterContent,
        reference: String
    ) -> SavedScripture {
        let sorted = verses.sorted { $0.verseNumber < $1.verseNumber }
        let text = sorted.map(\.text).joined(separator: " ")
        let start = sorted.first?.verseNumber
        let end = sorted.last?.verseNumber

        return SavedScripture(
            id: UUID(),
            savedAt: Date(),
            source: .bible,
            text: text,
            reference: reference,
            bookSlug: content.bookSlug,
            chapter: content.chapter,
            startVerse: start,
            endVerse: end,
            version: content.version,
            catalogPassageID: nil
        )
    }

    static func fromCurated(_ passage: SpiritualPassage) -> SavedScripture {
        SavedScripture(
            id: UUID(),
            savedAt: Date(),
            source: passage.source == .scripture ? .bible : .curated,
            text: passage.text,
            reference: passage.attribution,
            bookSlug: nil,
            chapter: nil,
            startVerse: nil,
            endVerse: nil,
            version: nil,
            catalogPassageID: passage.id
        )
    }
}
