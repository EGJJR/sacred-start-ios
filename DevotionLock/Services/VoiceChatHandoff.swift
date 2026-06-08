//
//  VoiceChatHandoff.swift
//  DevotionLock
//
//  Hybrid B: speak first, then continue in Chaplain text chat.
//

import Foundation

enum VoiceChatHandoff {
    /// Formats a voice transcript as the first chat message so Chaplain can reply in text.
    static func starter(from transcript: String, context: String? = nil) -> String {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if let context, !context.isEmpty {
            return "I just shared this about \(context): \"\(trimmed)\" — I'd like to talk it through with you."
        }
        return "I just shared this aloud: \"\(trimmed)\" — I'd like to talk it through with you."
    }

    static func seedMessages(for transcript: String) -> [ChaplainMessage] {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return [
            ChaplainMessage(role: .chaplain, text: "I heard you. Let's sit with that together — what feels most alive in what you shared?"),
        ]
    }
}
