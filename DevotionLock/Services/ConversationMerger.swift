//
//  ConversationMerger.swift
//  DevotionLock
//

import Foundation

enum ConversationMerger {
    /// Minimum words for a standalone reflection to appear on the journal timeline.
    static let journalSubstanceWordThreshold = 12

    @MainActor
    static func chaplainChats(limit: Int? = nil) -> [Conversation] {
        let chats = mergedTimeline().filter(isChaplainChat)
        if let limit { return Array(chats.prefix(limit)) }
        return chats
    }

    /// Journal tab — substantive captures only; Chaplain threads live in Chaplain history.
    @MainActor
    static func journalTimeline(limit: Int? = nil) -> [Conversation] {
        let filtered = mergedTimeline().filter(isJournalTimelineEntry)
        if let limit { return Array(filtered.prefix(limit)) }
        return filtered
    }

    static func isChaplainChat(_ conversation: Conversation) -> Bool {
        if isInternalChaplainRequest(conversation) { return false }
        if conversation.tag == "Chaplain" { return true }
        if conversation.remoteID != nil { return true }
        return conversation.transcript.contains { $0.speaker == "Chaplain" }
    }

    /// Background AI tasks (guided prayer enrichment) must not appear in chat history.
    static func isInternalChaplainRequest(_ conversation: Conversation) -> Bool {
        let haystack = [
            conversation.title,
            conversation.preview,
            conversation.transcript.first(where: { $0.speaker == "You" })?.text ?? "",
        ]
        .joined(separator: " ")
        .lowercased()

        if haystack.contains("write a guided prayer as json") { return true }
        if haystack.contains("guided prayer") && haystack.contains("json only") { return true }
        if haystack.contains("format this spoken journal") { return true }
        return false
    }

    static func isJournalTimelineEntry(_ conversation: Conversation) -> Bool {
        guard !isInternalChaplainRequest(conversation) else { return false }
        guard !isChaplainChat(conversation) else { return false }
        return isSubstantiveReflection(conversation)
    }

    private static func isSubstantiveReflection(_ conversation: Conversation) -> Bool {
        let userText = conversation.transcript
            .filter { $0.speaker == "You" }
            .map(\.text)
            .joined(separator: " ")
        let wordCount = userText.split(whereSeparator: \.isWhitespace).count

        if conversation.tag.lowercased() == "voice" {
            return !userText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if conversation.transcript.contains(where: { $0.speaker == "Chaplain" }) { return false }
        if wordCount >= journalSubstanceWordThreshold { return true }
        return conversation.transcript.count > 1
    }

    @MainActor
    static func mergedTimeline(limit: Int? = nil) -> [Conversation] {
        let combined = JournalLocalStore.shared.conversations + ConversationRepository.shared.conversations
        let merged = dedupe(combined)
            .sorted { ($0.recordedAt ?? .distantPast) > ($1.recordedAt ?? .distantPast) }
        if let limit { return Array(merged.prefix(limit)) }
        return merged
    }

    static func dedupe(_ conversations: [Conversation]) -> [Conversation] {
        var seenRemoteIDs = Set<UUID>()
        var seenContentKeys = Set<String>()
        var result: [Conversation] = []

        for conversation in conversations {
            if let remoteID = conversation.remoteID {
                guard !seenRemoteIDs.contains(remoteID) else { continue }
                seenRemoteIDs.insert(remoteID)
            }

            let key = contentKey(for: conversation)
            guard !seenContentKeys.contains(key) else { continue }
            seenContentKeys.insert(key)
            result.append(conversation)
        }

        return result
    }

    private static func contentKey(for conversation: Conversation) -> String {
        let day = conversation.recordedAt.map {
            Calendar.current.startOfDay(for: $0).timeIntervalSince1970
        } ?? 0
        let preview = conversation.preview.prefix(80).lowercased()
        return "\(conversation.tag)|\(conversation.title.lowercased())|\(preview)|\(Int(day))"
    }
}
