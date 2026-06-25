//
//  ScriptureCorpus.swift
//  DevotionLock
//
//  Deep module: verified Scripture lookup for Chaplain prefetch + UI cards.
//

import Foundation

struct ChaplainScriptureCitation: Identifiable, Equatable, Hashable, Codable {
    enum Source: String, Codable {
        case bibleAPI = "bible_api"
        case curatedCatalog = "curated_catalog"
    }

    let id: UUID
    let reference: String
    let text: String
    let source: Source
    let bookSlug: String?
    let chapter: Int?
    let startVerse: Int?
    let endVerse: Int?
    let catalogPassageID: String?
    let version: String?

    init(
        id: UUID = UUID(),
        reference: String,
        text: String,
        source: Source,
        bookSlug: String? = nil,
        chapter: Int? = nil,
        startVerse: Int? = nil,
        endVerse: Int? = nil,
        catalogPassageID: String? = nil,
        version: String? = nil
    ) {
        self.id = id
        self.reference = reference
        self.text = text
        self.source = source
        self.bookSlug = bookSlug
        self.chapter = chapter
        self.startVerse = startVerse
        self.endVerse = endVerse
        self.catalogPassageID = catalogPassageID
        self.version = version
    }

    static func fromJSON(_ object: [String: Any]) -> ChaplainScriptureCitation? {
        guard let reference = object["reference"] as? String,
              let text = object["text"] as? String,
              let sourceRaw = object["source"] as? String,
              let source = Source(rawValue: sourceRaw)
        else { return nil }

        return ChaplainScriptureCitation(
            reference: reference,
            text: ScriptureTextNormalizer.dedupeVerseText(text),
            source: source,
            bookSlug: object["book_slug"] as? String,
            chapter: object["chapter"] as? Int,
            startVerse: object["start_verse"] as? Int,
            endVerse: object["end_verse"] as? Int,
            catalogPassageID: object["catalog_passage_id"] as? String,
            version: object["version"] as? String
        )
    }

    var displayText: String {
        ScriptureTextNormalizer.dedupeVerseText(text)
    }
}

enum ScriptureTextNormalizer {
    /// Collapse duplicate pilcrow segments and repeated sentences within verse text.
    static func dedupeVerseText(_ text: String) -> String {
        var normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized = normalized.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        let pilcrowParts = normalized.components(separatedBy: "¶")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if pilcrowParts.count > 1 {
            var unique: [String] = []
            for part in pilcrowParts where !unique.contains(part) {
                unique.append(part)
            }
            normalized = unique.joined(separator: " ")
        }

        normalized = normalized.replacingOccurrences(of: #"^¶\s*"#, with: "", options: .regularExpression)

        let sentencePattern = #"[^.!?]+[.!?]+|[^.!?]+$"#
        if let regex = try? NSRegularExpression(pattern: sentencePattern) {
            let range = NSRange(normalized.startIndex..., in: normalized)
            let matches = regex.matches(in: normalized, range: range)
            if matches.count > 1 {
                var uniqueSentences: [String] = []
                for match in matches {
                    guard let swiftRange = Range(match.range, in: normalized) else { continue }
                    let sentence = String(normalized[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !sentence.isEmpty, !uniqueSentences.contains(sentence) else { continue }
                    uniqueSentences.append(sentence)
                }
                if !uniqueSentences.isEmpty {
                    normalized = uniqueSentences.joined(separator: " ")
                }
            }
        }

        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func joinVerseTexts(_ texts: [String]) -> String {
        dedupeVerseText(texts.joined(separator: " "))
    }
}

enum ScriptureReplyFormatter {
    static func displayText(for message: ChaplainMessage) -> String {
        let base: String
        if message.role == .chaplain, !message.scriptures.isEmpty {
            base = stripCitationText(from: message.text, citations: message.scriptures)
        } else {
            base = message.text
        }
        guard message.role == .chaplain else { return base }
        return ChaplainMessageFormatter.plainText(base)
    }

    private static func stripCitationText(from text: String, citations: [ChaplainScriptureCitation]) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { return result }

        let leadInPattern = #"(?i)^(?:here (?:it|that verse|is that verse|is the verse) is:?|here(?:'s| is) (?:that )?(?:verse|passage|scripture):?)\s*"#
        result = result.replacingOccurrences(of: leadInPattern, with: "", options: .regularExpression)

        for citation in citations {
            let normalized = citation.displayText
            result = stripOccurrence(of: normalized, from: result)

            let unquoted = normalized.trimmingCharacters(in: CharacterSet(charactersIn: "\"'\u{201C}\u{201D}\u{2018}\u{2019}"))
            if unquoted != normalized {
                result = stripOccurrence(of: unquoted, from: result)
            }
        }

        result = result.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripOccurrence(of passage: String, from text: String) -> String {
        guard !passage.isEmpty else { return text }
        var result = text

        let quotedPatterns = [
            #""\#(NSRegularExpression.escapedPattern(for: passage))""#,
            #"'\#(NSRegularExpression.escapedPattern(for: passage))'"#,
            NSRegularExpression.escapedPattern(for: passage),
        ]

        for pattern in quotedPatterns {
            result = result.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }

        return result
    }
}

enum ScriptureCorpus {
    private static let discoverLimit = 3

    /// Reference string → exact KJV text (uses on-device Bible API cache when available).
    static func lookup(reference input: String) async -> ChaplainScriptureCitation? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = BibleReferenceParser.parse(trimmed) else { return nil }

        do {
            let content = try await BibleAPIService.shared.fetchReference(parsed)
            let text = ScriptureTextNormalizer.joinVerseTexts(content.verses.map(\.text))
            guard !text.isEmpty else { return nil }
            let start = content.verses.first?.verseNumber
            let end = content.verses.last?.verseNumber

            return ChaplainScriptureCitation(
                reference: parsed.displayReference,
                text: text,
                source: .bibleAPI,
                bookSlug: content.bookSlug,
                chapter: content.chapter,
                startVerse: start,
                endVerse: end,
                version: content.version == BibleBookCatalog.defaultVersion ? "KJV" : content.version.uppercased()
            )
        } catch {
            return nil
        }
    }

    /// Topic / keyword → curated passages (scripture-first).
    static func discover(query: String, topics: [PassageTopic] = [], limit: Int = discoverLimit) -> [ChaplainScriptureCitation] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var results = trimmed.isEmpty ? SpiritualPassageCatalog.all : SpiritualPassageCatalog.search(trimmed)

        if !topics.isEmpty {
            results = results.filter { passage in
                topics.contains(where: { passage.topics.contains($0) })
            }
        }

        return results
            .filter { $0.source == .scripture }
            .prefix(limit)
            .map { passage in
                ChaplainScriptureCitation(
                    reference: passage.reference,
                    text: passage.text,
                    source: .curatedCatalog,
                    catalogPassageID: passage.id
                )
            }
    }

    /// Prefetch for obvious references or discovery-shaped questions before sending to Chaplain.
    static func prefetch(for userMessage: String, mood: String) async -> [ChaplainScriptureCitation] {
        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if let parsed = BibleReferenceParser.extractReference(from: trimmed),
           let lookedUp = await lookup(reference: parsed.displayReference) {
            return [lookedUp]
        }

        if let parsed = BibleReferenceParser.parse(trimmed), let lookedUp = await lookup(reference: parsed.displayReference) {
            return [lookedUp]
        }

        if BibleReferenceParser.looksLikeReference(trimmed), let lookedUp = await lookup(reference: trimmed) {
            return [lookedUp]
        }

        let lower = trimmed.lowercased()
        let wantsDiscovery = lower.contains("verse") || lower.contains("passage") || lower.contains("scripture")
            || lower.contains("bible") || lower.contains("find") || lower.contains("about")

        guard wantsDiscovery else { return [] }

        let moodTopics = SpiritualPassageCatalog.matchingTopics(mood: mood, focusTags: TodayFocusStore.tags)
        return discover(query: trimmed, topics: Array(moodTopics))
    }
}
