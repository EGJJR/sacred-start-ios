//
//  BibleBookCatalog.swift
//  DevotionLock
//

import Foundation

nonisolated enum BibleTestament: String, CaseIterable, Sendable {
    case old
    case new

    var label: String {
        switch self {
        case .old: "Old Testament"
        case .new: "New Testament"
        }
    }
}

nonisolated struct BibleBook: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let slug: String
    let testament: BibleTestament
    let chapterCount: Int
}

nonisolated enum BibleBookCatalog {
    static let defaultVersion = "en-kjv"

    static let all: [BibleBook] = [
        // Old Testament
        BibleBook(id: "genesis", name: "Genesis", slug: "genesis", testament: .old, chapterCount: 50),
        BibleBook(id: "exodus", name: "Exodus", slug: "exodus", testament: .old, chapterCount: 40),
        BibleBook(id: "leviticus", name: "Leviticus", slug: "leviticus", testament: .old, chapterCount: 27),
        BibleBook(id: "numbers", name: "Numbers", slug: "numbers", testament: .old, chapterCount: 36),
        BibleBook(id: "deuteronomy", name: "Deuteronomy", slug: "deuteronomy", testament: .old, chapterCount: 34),
        BibleBook(id: "joshua", name: "Joshua", slug: "joshua", testament: .old, chapterCount: 24),
        BibleBook(id: "judges", name: "Judges", slug: "judges", testament: .old, chapterCount: 21),
        BibleBook(id: "ruth", name: "Ruth", slug: "ruth", testament: .old, chapterCount: 4),
        BibleBook(id: "1samuel", name: "1 Samuel", slug: "1samuel", testament: .old, chapterCount: 31),
        BibleBook(id: "2samuel", name: "2 Samuel", slug: "2samuel", testament: .old, chapterCount: 24),
        BibleBook(id: "1kings", name: "1 Kings", slug: "1kings", testament: .old, chapterCount: 22),
        BibleBook(id: "2kings", name: "2 Kings", slug: "2kings", testament: .old, chapterCount: 25),
        BibleBook(id: "1chronicles", name: "1 Chronicles", slug: "1chronicles", testament: .old, chapterCount: 29),
        BibleBook(id: "2chronicles", name: "2 Chronicles", slug: "2chronicles", testament: .old, chapterCount: 36),
        BibleBook(id: "ezra", name: "Ezra", slug: "ezra", testament: .old, chapterCount: 10),
        BibleBook(id: "nehemiah", name: "Nehemiah", slug: "nehemiah", testament: .old, chapterCount: 13),
        BibleBook(id: "esther", name: "Esther", slug: "esther", testament: .old, chapterCount: 10),
        BibleBook(id: "job", name: "Job", slug: "job", testament: .old, chapterCount: 42),
        BibleBook(id: "psalms", name: "Psalms", slug: "psalms", testament: .old, chapterCount: 150),
        BibleBook(id: "proverbs", name: "Proverbs", slug: "proverbs", testament: .old, chapterCount: 31),
        BibleBook(id: "ecclesiastes", name: "Ecclesiastes", slug: "ecclesiastes", testament: .old, chapterCount: 12),
        BibleBook(id: "songofsolomon", name: "Song of Solomon", slug: "songofsolomon", testament: .old, chapterCount: 8),
        BibleBook(id: "isaiah", name: "Isaiah", slug: "isaiah", testament: .old, chapterCount: 66),
        BibleBook(id: "jeremiah", name: "Jeremiah", slug: "jeremiah", testament: .old, chapterCount: 52),
        BibleBook(id: "lamentations", name: "Lamentations", slug: "lamentations", testament: .old, chapterCount: 5),
        BibleBook(id: "ezekiel", name: "Ezekiel", slug: "ezekiel", testament: .old, chapterCount: 48),
        BibleBook(id: "daniel", name: "Daniel", slug: "daniel", testament: .old, chapterCount: 12),
        BibleBook(id: "hosea", name: "Hosea", slug: "hosea", testament: .old, chapterCount: 14),
        BibleBook(id: "joel", name: "Joel", slug: "joel", testament: .old, chapterCount: 3),
        BibleBook(id: "amos", name: "Amos", slug: "amos", testament: .old, chapterCount: 9),
        BibleBook(id: "obadiah", name: "Obadiah", slug: "obadiah", testament: .old, chapterCount: 1),
        BibleBook(id: "jonah", name: "Jonah", slug: "jonah", testament: .old, chapterCount: 4),
        BibleBook(id: "micah", name: "Micah", slug: "micah", testament: .old, chapterCount: 7),
        BibleBook(id: "nahum", name: "Nahum", slug: "nahum", testament: .old, chapterCount: 3),
        BibleBook(id: "habakkuk", name: "Habakkuk", slug: "habakkuk", testament: .old, chapterCount: 3),
        BibleBook(id: "zephaniah", name: "Zephaniah", slug: "zephaniah", testament: .old, chapterCount: 3),
        BibleBook(id: "haggai", name: "Haggai", slug: "haggai", testament: .old, chapterCount: 2),
        BibleBook(id: "zechariah", name: "Zechariah", slug: "zechariah", testament: .old, chapterCount: 14),
        BibleBook(id: "malachi", name: "Malachi", slug: "malachi", testament: .old, chapterCount: 4),
        // New Testament
        BibleBook(id: "matthew", name: "Matthew", slug: "matthew", testament: .new, chapterCount: 28),
        BibleBook(id: "mark", name: "Mark", slug: "mark", testament: .new, chapterCount: 16),
        BibleBook(id: "luke", name: "Luke", slug: "luke", testament: .new, chapterCount: 24),
        BibleBook(id: "john", name: "John", slug: "john", testament: .new, chapterCount: 21),
        BibleBook(id: "acts", name: "Acts", slug: "acts", testament: .new, chapterCount: 28),
        BibleBook(id: "romans", name: "Romans", slug: "romans", testament: .new, chapterCount: 16),
        BibleBook(id: "1corinthians", name: "1 Corinthians", slug: "1corinthians", testament: .new, chapterCount: 16),
        BibleBook(id: "2corinthians", name: "2 Corinthians", slug: "2corinthians", testament: .new, chapterCount: 13),
        BibleBook(id: "galatians", name: "Galatians", slug: "galatians", testament: .new, chapterCount: 6),
        BibleBook(id: "ephesians", name: "Ephesians", slug: "ephesians", testament: .new, chapterCount: 6),
        BibleBook(id: "philippians", name: "Philippians", slug: "philippians", testament: .new, chapterCount: 4),
        BibleBook(id: "colossians", name: "Colossians", slug: "colossians", testament: .new, chapterCount: 4),
        BibleBook(id: "1thessalonians", name: "1 Thessalonians", slug: "1thessalonians", testament: .new, chapterCount: 5),
        BibleBook(id: "2thessalonians", name: "2 Thessalonians", slug: "2thessalonians", testament: .new, chapterCount: 3),
        BibleBook(id: "1timothy", name: "1 Timothy", slug: "1timothy", testament: .new, chapterCount: 6),
        BibleBook(id: "2timothy", name: "2 Timothy", slug: "2timothy", testament: .new, chapterCount: 4),
        BibleBook(id: "titus", name: "Titus", slug: "titus", testament: .new, chapterCount: 3),
        BibleBook(id: "philemon", name: "Philemon", slug: "philemon", testament: .new, chapterCount: 1),
        BibleBook(id: "hebrews", name: "Hebrews", slug: "hebrews", testament: .new, chapterCount: 13),
        BibleBook(id: "james", name: "James", slug: "james", testament: .new, chapterCount: 5),
        BibleBook(id: "1peter", name: "1 Peter", slug: "1peter", testament: .new, chapterCount: 5),
        BibleBook(id: "2peter", name: "2 Peter", slug: "2peter", testament: .new, chapterCount: 3),
        BibleBook(id: "1john", name: "1 John", slug: "1john", testament: .new, chapterCount: 5),
        BibleBook(id: "2john", name: "2 John", slug: "2john", testament: .new, chapterCount: 1),
        BibleBook(id: "3john", name: "3 John", slug: "3john", testament: .new, chapterCount: 1),
        BibleBook(id: "jude", name: "Jude", slug: "jude", testament: .new, chapterCount: 1),
        BibleBook(id: "revelation", name: "Revelation", slug: "revelation", testament: .new, chapterCount: 22),
    ]

    static func books(for testament: BibleTestament) -> [BibleBook] {
        all.filter { $0.testament == testament }
    }

    static func book(slug: String) -> BibleBook? {
        all.first { $0.slug == slug }
    }

    /// Maps common abbreviations and alternate spellings to API slugs.
    static func resolveSlug(from rawName: String) -> String? {
        let key = rawName
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let direct = book(slug: key.replacingOccurrences(of: " ", with: "")) {
            return direct.slug
        }

        if let alias = aliases[key] {
            return alias
        }

        let compact = key.replacingOccurrences(of: " ", with: "")
        if let alias = aliases[compact] {
            return alias
        }

        // Prefix match on book names (e.g. "phil" → philippians)
        if let match = all.first(where: { book in
            book.name.lowercased().hasPrefix(key)
                || book.slug.hasPrefix(compact)
        }) {
            return match.slug
        }

        return nil
    }

    private static let aliases: [String: String] = [
        "gen": "genesis",
        "ex": "exodus",
        "exod": "exodus",
        "lev": "leviticus",
        "num": "numbers",
        "deut": "deuteronomy",
        "josh": "joshua",
        "judg": "judges",
        "1 sam": "1samuel",
        "1sam": "1samuel",
        "1 samuel": "1samuel",
        "2 sam": "2samuel",
        "2sam": "2samuel",
        "2 samuel": "2samuel",
        "1 kgs": "1kings",
        "1 kings": "1kings",
        "1kgs": "1kings",
        "1kin": "1kings",
        "2 kgs": "2kings",
        "2 kings": "2kings",
        "2kgs": "2kings",
        "2kin": "2kings",
        "1 chr": "1chronicles",
        "1 chronicles": "1chronicles",
        "1chr": "1chronicles",
        "2 chr": "2chronicles",
        "2 chronicles": "2chronicles",
        "2chr": "2chronicles",
        "neh": "nehemiah",
        "est": "esther",
        "ps": "psalms",
        "psa": "psalms",
        "psalm": "psalms",
        "psalms": "psalms",
        "prov": "proverbs",
        "eccl": "ecclesiastes",
        "ecc": "ecclesiastes",
        "song": "songofsolomon",
        "sos": "songofsolomon",
        "song of solomon": "songofsolomon",
        "isa": "isaiah",
        "jer": "jeremiah",
        "lam": "lamentations",
        "ezek": "ezekiel",
        "dan": "daniel",
        "hos": "hosea",
        "obad": "obadiah",
        "mic": "micah",
        "nah": "nahum",
        "hab": "habakkuk",
        "zeph": "zephaniah",
        "hag": "haggai",
        "zech": "zechariah",
        "mal": "malachi",
        "matt": "matthew",
        "mk": "mark",
        "lk": "luke",
        "jn": "john",
        "jhn": "john",
        "rom": "romans",
        "1 cor": "1corinthians",
        "1cor": "1corinthians",
        "1 corinthians": "1corinthians",
        "2 cor": "2corinthians",
        "2cor": "2corinthians",
        "2 corinthians": "2corinthians",
        "gal": "galatians",
        "eph": "ephesians",
        "phil": "philippians",
        "col": "colossians",
        "1 thess": "1thessalonians",
        "1 thessalonians": "1thessalonians",
        "1thess": "1thessalonians",
        "2 thess": "2thessalonians",
        "2 thessalonians": "2thessalonians",
        "2thess": "2thessalonians",
        "1 tim": "1timothy",
        "1 timothy": "1timothy",
        "1tim": "1timothy",
        "2 tim": "2timothy",
        "2 timothy": "2timothy",
        "2tim": "2timothy",
        "phlm": "philemon",
        "heb": "hebrews",
        "jas": "james",
        "1 pet": "1peter",
        "1 peter": "1peter",
        "1pet": "1peter",
        "2 pet": "2peter",
        "2 peter": "2peter",
        "2pet": "2peter",
        "1 jn": "1john",
        "1 john": "1john",
        "1jn": "1john",
        "2 jn": "2john",
        "2 john": "2john",
        "2jn": "2john",
        "3 jn": "3john",
        "3 john": "3john",
        "3jn": "3john",
        "rev": "revelation",
        "revelation": "revelation",
    ]
}
