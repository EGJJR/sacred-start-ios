//
//  ConversationRepository.swift
//  DevotionLock
//
//  Remote Chaplain/journal conversations. `refresh()` loads metadata only; full transcripts
//  are fetched on demand via `loadTranscript(for:)` to keep memory bounded on the list screen.
//

import Foundation
import Supabase

struct DBConversation: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let title: String?
    let mood: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case mood
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DBMessage: Codable, Identifiable {
    let id: UUID
    let conversationId: UUID
    let role: String
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case role
        case content
        case createdAt = "created_at"
    }
}

private struct StoredTranscriptSegment: Codable {
    let id: UUID
    let speaker: String
    let text: String
    let timestamp: String
}

private struct StoredConversation: Codable {
    let id: UUID
    let remoteID: UUID?
    let tag: String
    let timeAgo: String
    let timelineTime: String
    let emoji: String
    let moodEmoji: String
    let moodLabel: String
    let title: String
    let preview: String
    let duration: String
    let isToday: Bool
    let transcript: [StoredTranscriptSegment]
    let recordedAt: Date?

    init(_ conversation: Conversation, includeTranscript: Bool = false) {
        id = conversation.id
        remoteID = conversation.remoteID
        tag = conversation.tag
        timeAgo = conversation.timeAgo
        timelineTime = conversation.timelineTime
        emoji = conversation.emoji
        moodEmoji = conversation.moodEmoji
        moodLabel = conversation.moodLabel
        title = conversation.title
        preview = conversation.preview
        duration = conversation.duration
        isToday = conversation.isToday
        transcript = includeTranscript
            ? conversation.transcript.map {
                StoredTranscriptSegment(id: $0.id, speaker: $0.speaker, text: $0.text, timestamp: $0.timestamp)
            }
            : []
        recordedAt = conversation.recordedAt
    }

    var conversation: Conversation {
        Conversation(
            id: id,
            remoteID: remoteID,
            tag: tag,
            timeAgo: timeAgo,
            timelineTime: timelineTime,
            emoji: emoji,
            moodEmoji: moodEmoji,
            moodLabel: moodLabel,
            title: title,
            preview: preview,
            duration: duration,
            isToday: isToday,
            transcript: [],
            recordedAt: recordedAt
        )
    }
}

@Observable
@MainActor
final class ConversationRepository {
    static let shared = ConversationRepository()

    private enum Keys {
        static let cache = "conversationRepositoryCache"
    }

    private(set) var conversations: [Conversation] = []
    private(set) var isLoading = false

    init() {
        loadCache()
    }

    func clear() {
        conversations = []
        UserDefaults.standard.removeObject(forKey: Keys.cache)
    }

    func conversation(for id: UUID) -> Conversation? {
        conversations.first { $0.id == id || $0.remoteID == id }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        guard AuthManager.shared.isAuthenticated else { return }

        do {
            let rows: [DBConversation] = try await SupabaseManager.client
                .from("conversations")
                .select()
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            let conversationIDs = rows.map(\.id)
            var latestMessages: [UUID: DBMessage] = [:]
            var latestUserMessages: [UUID: DBMessage] = [:]
            var messageCounts: [UUID: Int] = [:]

            if !conversationIDs.isEmpty {
                let recentMessages: [DBMessage] = try await SupabaseManager.client
                    .from("messages")
                    .select()
                    .in("conversation_id", values: conversationIDs.map(\.uuidString))
                    .order("created_at", ascending: false)
                    .limit(120)
                    .execute()
                    .value

                for message in recentMessages {
                    messageCounts[message.conversationId, default: 0] += 1
                    if latestMessages[message.conversationId] == nil {
                        latestMessages[message.conversationId] = message
                    }
                    if message.role == "user", latestUserMessages[message.conversationId] == nil {
                        latestUserMessages[message.conversationId] = message
                    }
                }
            }

            conversations = rows.map { row in
                let previewSource = latestUserMessages[row.id] ?? latestMessages[row.id]
                let previewMessages = previewSource.map { [$0] } ?? []
                let count = messageCounts[row.id] ?? previewMessages.count
                return mapConversation(
                    row,
                    messages: previewMessages,
                    messageCount: count,
                    includeTranscript: false
                )
            }
            await purgeInternalChaplainLeaks()
            saveCache()
        } catch {
            SyncErrorFilter.logPullFailure("ConversationRepository refresh", error)
        }
    }

    func deleteConversation(id: UUID) async {
        let existing = conversation(for: id)
        let remoteID = existing?.remoteID ?? existing?.id ?? id

        conversations.removeAll {
            $0.id == id || $0.remoteID == id || $0.remoteID == remoteID
        }
        saveCache()

        JournalLocalStore.shared.deleteChaplainConversation(id: id, remoteID: remoteID)

        if ChaplainSessionStore.shared.resumableConversation?.id == remoteID {
            ChaplainSessionStore.shared.clear()
        }

        guard AuthManager.shared.isAuthenticated else { return }

        do {
            try await SupabaseManager.client
                .from("conversations")
                .delete()
                .eq("id", value: remoteID.uuidString)
                .execute()
        } catch {
            #if DEBUG
            print("ConversationRepository deleteConversation failed: \(error)")
            #endif
        }
    }

    func loadTranscript(for conversationID: UUID) async -> Conversation? {
        guard AuthManager.shared.isAuthenticated else { return conversation(for: conversationID) }

        let existing = conversation(for: conversationID)
        if let existing, !existing.transcript.isEmpty {
            return existing
        }

        let remoteID = existing?.remoteID ?? existing?.id ?? conversationID

        do {
            let row: DBConversation = try await SupabaseManager.client
                .from("conversations")
                .select()
                .eq("id", value: remoteID.uuidString)
                .single()
                .execute()
                .value

            let messages: [DBMessage] = try await SupabaseManager.client
                .from("messages")
                .select()
                .eq("conversation_id", value: remoteID.uuidString)
                .order("created_at", ascending: true)
                .limit(200)
                .execute()
                .value

            let loaded = mapConversation(
                row,
                messages: messages,
                messageCount: messages.count,
                includeTranscript: true
            )

            if let index = conversations.firstIndex(where: { $0.id == loaded.id || $0.remoteID == loaded.id }) {
                conversations[index] = loaded
            } else {
                conversations.insert(loaded, at: 0)
            }
            return loaded
        } catch {
            #if DEBUG
            print("ConversationRepository loadTranscript failed: \(error)")
            #endif
            return existing
        }
    }

    private func mapConversation(
        _ row: DBConversation,
        messages: [DBMessage],
        messageCount: Int,
        includeTranscript: Bool
    ) -> Conversation {
        let preview = messages.last(where: { $0.role == "user" })?.content
            ?? messages.first?.content
            ?? row.title
            ?? "A conversation with your Chaplain."

        let transcript = includeTranscript
            ? messages.map { message in
                TranscriptSegment(
                    speaker: message.role == "user" ? "You" : "Chaplain",
                    text: message.content,
                    timestamp: formattedTimestamp(message.createdAt)
                )
            }
            : []

        return Conversation(
            id: row.id,
            remoteID: row.id,
            tag: "Chaplain",
            timeAgo: relativeTime(from: row.createdAt),
            timelineTime: timelineTime(from: row.createdAt),
            emoji: "🙏",
            moodEmoji: moodEmoji(for: row.mood),
            moodLabel: row.mood ?? "Present",
            title: row.title ?? "Chaplain Conversation",
            preview: String(preview.prefix(160)),
            duration: estimatedDuration(messageCount: messageCount),
            isToday: Calendar.current.isDateInToday(row.createdAt),
            transcript: transcript,
            recordedAt: row.createdAt
        )
    }

    private func relativeTime(from date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }

    private func timelineTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formattedTimestamp(_ date: Date) -> String {
        let elapsed = max(0, Int(Date().timeIntervalSince(date)))
        return String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    private func moodEmoji(for mood: String?) -> String {
        switch mood?.lowercased() {
        case "peaceful": "🍃"
        case "grateful": "😊"
        case "hopeful": "🌅"
        case "anxious", "overwhelmed": "🌧️"
        default: "✨"
        }
    }

    private func estimatedDuration(messageCount: Int) -> String {
        "\(max(1, messageCount * 2))m"
    }

    private func loadCache() {
        guard
            let data = UserDefaults.standard.data(forKey: Keys.cache),
            let stored = try? JSONDecoder().decode([StoredConversation].self, from: data)
        else { return }
        conversations = stored.map(\.conversation).filter {
            !ConversationMerger.isInternalChaplainRequest($0)
        }
    }

    /// Deletes background Chaplain tasks (guided-prayer JSON prompts, etc.) that leaked into sync.
    private func purgeInternalChaplainLeaks() async {
        let leaks = conversations.filter(ConversationMerger.isInternalChaplainRequest)
        guard !leaks.isEmpty else { return }

        conversations.removeAll { ConversationMerger.isInternalChaplainRequest($0) }

        for leak in leaks {
            let remoteID = leak.remoteID ?? leak.id
            JournalLocalStore.shared.deleteChaplainConversation(id: leak.id, remoteID: remoteID)
            guard AuthManager.shared.isAuthenticated else { continue }
            do {
                try await SupabaseManager.client
                    .from("conversations")
                    .delete()
                    .eq("id", value: remoteID.uuidString)
                    .execute()
            } catch {
                #if DEBUG
                print("ConversationRepository purgeInternalChaplainLeaks failed: \(error)")
                #endif
            }
        }
    }

    private func saveCache() {
        let stored = conversations.map { StoredConversation($0, includeTranscript: false) }
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: Keys.cache)
        }
    }
}
