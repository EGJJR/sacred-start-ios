//
//  ChaplainMessageFormatter.swift
//  DevotionLock
//
//  Plain-text rendering for Chaplain replies — no raw Markdown in the thread.
//

import Foundation

enum ChaplainMessageFormatter {
    /// Strips common Markdown / formatting the model may still emit.
    static func plainText(_ raw: String) -> String {
        var text = raw

        text = text.replacingOccurrences(of: "\r\n", with: "\n")
        text = text.replacingOccurrences(of: "***", with: "")
        text = text.replacingOccurrences(of: "**", with: "")
        text = text.replacingOccurrences(of: "__", with: "")
        text = text.replacingOccurrences(
            of: #"\*([^*\n]+)\*"#,
            with: "$1",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"_([^_\n]+)_"#,
            with: "$1",
            options: .regularExpression
        )

        text = text.replacingOccurrences(
            of: #"\n[ \t]*[-*_]{3,}[ \t]*\n"#,
            with: "\n\n",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"(?m)^[ \t]*[-*_]{3,}[ \t]*$"#,
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"(?m)^#{1,6}\s+"#,
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"(?m)^[ \t]*[-*+]\s+"#,
            with: "• ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(of: " — ", with: ", ")
        text = text.replacingOccurrences(of: " – ", with: ", ")
        text = text.replacingOccurrences(of: "—", with: ", ")
        text = text.replacingOccurrences(of: "–", with: ", ")
        text = text.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "*", with: "")

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
