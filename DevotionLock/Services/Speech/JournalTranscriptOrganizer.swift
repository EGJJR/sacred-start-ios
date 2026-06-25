//
//  JournalTranscriptOrganizer.swift
//  DevotionLock
//
//  On-device spoken-text tidy — punctuation & paragraphs only; meaning preserved.
//

import Foundation
import NaturalLanguage

enum JournalTranscriptOrganizer {
    /// Minimum length before polish choice is offered.
    static let polishThreshold = 18

    static func organize(_ raw: String) -> String {
        var text = raw
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { return raw.trimmingCharacters(in: .whitespacesAndNewlines) }

        text = stripFillers(from: text)

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            var sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sentence.isEmpty else { return true }
            sentence = capitalizeFirst(sentence)
            if let last = sentence.last, !".!?".contains(last) {
                sentence += "."
            }
            sentences.append(sentence)
            return true
        }

        guard !sentences.isEmpty else {
            return capitalizeFirst(text)
        }

        if sentences.count <= 2 {
            return sentences.joined(separator: " ")
        }

        var paragraphs: [String] = []
        var index = 0
        while index < sentences.count {
            let end = min(index + 2, sentences.count)
            paragraphs.append(sentences[index..<end].joined(separator: " "))
            index += 2
        }
        return paragraphs.joined(separator: "\n\n")
    }

    static func worthPolishChoice(_ raw: String) -> Bool {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).count >= polishThreshold
    }

    static func merge(base: String, spoken: String) -> String {
        let trimmed = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }
        if base.isEmpty { return trimmed }
        if base.hasSuffix(" ") { return base + trimmed }
        return base + " " + trimmed
    }

    private static func stripFillers(from text: String) -> String {
        var result = text
        let patterns = [#"\bum\b"#, #"\buh\b"#, #"\buhm\b"#, #"\berm\b"#, #"\bah\b"#]
        for pattern in patterns {
            result = result.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        return result
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func capitalizeFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}
