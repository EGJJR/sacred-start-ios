//
//  BibleAPIService.swift
//  DevotionLock
//
//  Scripture fetch via wldeh/bible-api CDN (KJV, public domain).
//  https://github.com/wldeh/bible-api
//

import Foundation

struct BibleVerse: Identifiable, Codable, Equatable {
    let book: String
    let chapter: String
    let verse: String
    let text: String

    var id: String { "\(book)-\(chapter)-\(verse)" }

    var verseNumber: Int { Int(verse) ?? 0 }
}

struct BibleChapterContent: Equatable {
    let bookName: String
    let bookSlug: String
    let chapter: Int
    let version: String
    let verses: [BibleVerse]

    func verses(in range: ClosedRange<Int>?) -> [BibleVerse] {
        guard let range else { return verses }
        return verses.filter { range.contains($0.verseNumber) }
    }

    func singleVerse(_ number: Int) -> BibleVerse? {
        verses.first { $0.verseNumber == number }
    }
}

enum BibleAPIError: LocalizedError {
    case invalidReference
    case network(Error)
    case decodeFailed
    case chapterNotFound

    var errorDescription: String? {
        switch self {
        case .invalidReference: "That reference could not be understood."
        case .network(let error): error.localizedDescription
        case .decodeFailed: "Could not read this chapter."
        case .chapterNotFound: "Chapter not found."
        }
    }
}

actor BibleAPIService {
    static let shared = BibleAPIService()

    private let baseURL = "https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles"
    private let cacheTTL: TimeInterval = 7 * 24 * 60 * 60
    private var memoryCache: [String: CachedChapterPayload] = [:]

    private struct CachedChapterPayload: Codable {
        let fetchedAt: Date
        let verses: [BibleVerse]
    }

    private struct ChapterResponse: Decodable {
        let data: [BibleVerse]
    }

    func fetchChapter(
        bookSlug: String,
        chapter: Int,
        version: String = BibleBookCatalog.defaultVersion
    ) async throws -> BibleChapterContent {
        let key = cacheKey(version: version, book: bookSlug, chapter: chapter)

        if let cached = memoryCache[key], !isExpired(cached.fetchedAt) {
            return makeContent(bookSlug: bookSlug, chapter: chapter, version: version, verses: cached.verses)
        }

        if let disk = loadFromDisk(key: key), !isExpired(disk.fetchedAt) {
            memoryCache[key] = disk
            return makeContent(bookSlug: bookSlug, chapter: chapter, version: version, verses: disk.verses)
        }

        let url = URL(string: "\(baseURL)/\(version)/books/\(bookSlug)/chapters/\(chapter).json")!
        let data: Data
        do {
            let (payload, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw BibleAPIError.chapterNotFound
            }
            data = payload
        } catch let error as BibleAPIError {
            throw error
        } catch {
            throw BibleAPIError.network(error)
        }

        guard let decoded = try? JSONDecoder().decode(ChapterResponse.self, from: data) else {
            throw BibleAPIError.decodeFailed
        }

        let verses = deduplicated(decoded.data)
        let payload = CachedChapterPayload(fetchedAt: Date(), verses: verses)
        memoryCache[key] = payload
        saveToDisk(key: key, payload: payload)

        return makeContent(bookSlug: bookSlug, chapter: chapter, version: version, verses: verses)
    }

    func fetchReference(
        _ reference: ParsedBibleReference,
        version: String = BibleBookCatalog.defaultVersion
    ) async throws -> BibleChapterContent {
        let chapter = try await fetchChapter(bookSlug: reference.bookSlug, chapter: reference.chapter, version: version)
        if let verse = reference.verse {
            let end = reference.endVerse ?? verse
            let filtered = chapter.verses(in: verse...end)
            return BibleChapterContent(
                bookName: chapter.bookName,
                bookSlug: chapter.bookSlug,
                chapter: chapter.chapter,
                version: chapter.version,
                verses: filtered.isEmpty ? chapter.verses : filtered
            )
        }
        return chapter
    }

    private func makeContent(
        bookSlug: String,
        chapter: Int,
        version: String,
        verses: [BibleVerse]
    ) -> BibleChapterContent {
        let bookName = BibleBookCatalog.book(slug: bookSlug)?.name ?? verses.first?.book ?? bookSlug
        return BibleChapterContent(
            bookName: bookName,
            bookSlug: bookSlug,
            chapter: chapter,
            version: version,
            verses: verses.sorted { $0.verseNumber < $1.verseNumber }
        )
    }

    private func deduplicated(_ verses: [BibleVerse]) -> [BibleVerse] {
        var seen = Set<String>()
        return verses.filter { verse in
            let key = verse.verse
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private func cacheKey(version: String, book: String, chapter: Int) -> String {
        "\(version)_\(book)_\(chapter)"
    }

    private func isExpired(_ date: Date) -> Bool {
        Date().timeIntervalSince(date) > cacheTTL
    }

    private var cacheDirectory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("BibleAPI", isDirectory: true)
    }

    private func loadFromDisk(key: String) -> CachedChapterPayload? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CachedChapterPayload.self, from: data)
    }

    private func saveToDisk(key: String, payload: CachedChapterPayload) {
        let dir = cacheDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(key).json")
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
