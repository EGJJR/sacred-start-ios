//
//  ConversationMerger.swift
//  DevotionLock
//

import Foundation

enum ConversationMerger {
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
