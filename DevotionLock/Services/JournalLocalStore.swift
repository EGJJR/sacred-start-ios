//
//  JournalLocalStore.swift
//  DevotionLock
//

import Foundation
import Observation

struct SavedChatLine: Codable, Equatable {
    let speaker: String
    let text: String
}

struct JournalLocalEntry: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case assisted
        case evening
        case voiceNote
        case chaplainChat
    }

    let id: UUID
    let createdAt: Date
    let kind: Kind
    let title: String
    let body: String
    let moodLabel: String
    let moodEmoji: String
    var chatLines: [SavedChatLine]?
    var conversationID: UUID?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        kind: Kind,
        title: String,
        body: String,
        moodLabel: String = "Present",
        moodEmoji: String = "✨",
        chatLines: [SavedChatLine]? = nil,
        conversationID: UUID? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.title = title
        self.body = body
        self.moodLabel = moodLabel
        self.moodEmoji = moodEmoji
        self.chatLines = chatLines
        self.conversationID = conversationID
    }

    func asConversation() -> Conversation {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timelineTime = formatter.string(from: createdAt)

        let tag: String
        let displayTitle: String
        let emoji: String
        let duration: String

        switch kind {
        case .voiceNote:
            tag = "Voice"
            displayTitle = "Voice note"
            emoji = "🎙️"
            duration = "Voice"
        case .assisted:
            tag = "Reflection"
            displayTitle = title
            emoji = "✍️"
            duration = "Written"
        case .evening:
            tag = "Evening"
            displayTitle = title
            emoji = "🌙"
            duration = "Written"
        case .chaplainChat:
            tag = "Chaplain"
            displayTitle = title
            emoji = "💬"
            duration = "\(chatLines?.count ?? 1) msgs"
        }

        let transcript: [TranscriptSegment]
        if let chatLines, !chatLines.isEmpty {
            transcript = chatLines.enumerated().map { index, line in
                TranscriptSegment(
                    speaker: line.speaker,
                    text: line.text,
                    timestamp: String(format: "%d:%02d", index, 0)
                )
            }
        } else {
            transcript = [TranscriptSegment(speaker: "You", text: body, timestamp: "0:00")]
        }

        return Conversation(
            id: id,
            remoteID: conversationID,
            tag: tag,
            timeAgo: RelativeDateTimeFormatter().localizedString(for: createdAt, relativeTo: Date()),
            timelineTime: timelineTime,
            emoji: emoji,
            moodEmoji: moodEmoji,
            moodLabel: moodLabel,
            title: displayTitle,
            preview: String(body.prefix(200)),
            duration: duration,
            isToday: Calendar.current.isDateInToday(createdAt),
            transcript: transcript,
            recordedAt: createdAt
        )
    }
}

@Observable
@MainActor
final class JournalLocalStore {
    static let shared = JournalLocalStore()

    private enum Keys {
        static let legacyEntries = "journalLocalEntries"

        static func entries(for userId: UUID) -> String {
            "journalLocalEntries.\(userId.uuidString)"
        }
    }

    private(set) var entries: [JournalLocalEntry] = []
    private(set) var revision = 0
    private var activeUserId: UUID?

    init() {
        purgeLegacyGlobalEntries()
    }

    /// Switches the in-memory store to the signed-in user. Each account has its own timeline.
    func activateAccount(userId: UUID?) {
        guard activeUserId != userId else { return }
        activeUserId = userId
        if let userId {
            load(for: userId)
        } else {
            entries = []
        }
        revision += 1
    }

    func clearAll(for userId: UUID? = nil) {
        let targetId = userId ?? activeUserId
        entries = []
        if let targetId {
            UserDefaults.standard.removeObject(forKey: Keys.entries(for: targetId))
        }
    }

    var conversations: [Conversation] {
        entries.map { $0.asConversation() }
    }

    func entry(id: UUID) -> JournalLocalEntry? {
        entries.first { $0.id == id }
    }

    @discardableResult
    func updateEntry(id: UUID, body: String) -> JournalLocalEntry? {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return nil }
        let existing = entries[index]
        guard existing.kind == .assisted || existing.kind == .evening || existing.kind == .voiceNote else { return nil }

        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let updated = JournalLocalEntry(
            id: existing.id,
            createdAt: existing.createdAt,
            kind: existing.kind,
            title: existing.title,
            body: trimmed,
            moodLabel: existing.moodLabel,
            moodEmoji: existing.moodEmoji,
            chatLines: nil,
            conversationID: existing.conversationID
        )
        entries[index] = updated
        persist()
        JourneyTimelineStore.shared.updateEntryBody(id: id, body: trimmed)
        markChanged()
        return updated
    }

    @discardableResult
    func addEveningReflection(highlight: String) -> JournalLocalEntry {
        let trimmed = highlight.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = trimmed.isEmpty ? "Quiet gratitude for today." : trimmed
        let entryID = UUID()
        let entry = JournalLocalEntry(
            id: entryID,
            kind: .evening,
            title: "Evening reflection",
            body: body,
            moodLabel: "Present",
            moodEmoji: "🌙"
        )
        entries.insert(entry, at: 0)
        persist()
        markChanged()

        JourneyTimelineStore.shared.add(JourneyTimelineEntry(
            id: entryID,
            kind: .evening,
            title: "Evening reflection",
            body: body,
            moodEmoji: "🌙"
        ))
        return entry
    }

    @discardableResult
    func addAssistedEntry(
        body: String,
        title: String = "Journal entry",
        moodLabel: String = "Present",
        moodEmoji: String = "✨"
    ) -> JournalLocalEntry {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let entryID = UUID()
        let entry = JournalLocalEntry(
            id: entryID,
            kind: .assisted,
            title: title,
            body: trimmed,
            moodLabel: moodLabel,
            moodEmoji: moodEmoji
        )
        entries.insert(entry, at: 0)
        persist()
        markChanged()

        JourneyTimelineStore.shared.add(JourneyTimelineEntry(
            id: entryID,
            kind: .reflection,
            title: title,
            body: trimmed,
            moodEmoji: moodEmoji,
            focusTags: TodayFocusStore.tags.map(\.rawValue)
        ))
        return entry
    }

    @discardableResult
    func addVoiceNote(
        transcript: String,
        moodLabel: String = "Present",
        moodEmoji: String = "✨"
    ) -> JournalLocalEntry {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let entryID = UUID()
        let entry = JournalLocalEntry(
            id: entryID,
            kind: .voiceNote,
            title: "Voice note",
            body: trimmed,
            moodLabel: moodLabel,
            moodEmoji: moodEmoji
        )
        entries.insert(entry, at: 0)
        persist()
        markChanged()

        JourneyTimelineStore.shared.add(JourneyTimelineEntry(
            id: entryID,
            kind: .voiceNote,
            title: "Voice note",
            body: trimmed,
            moodEmoji: moodEmoji,
            focusTags: TodayFocusStore.tags.map(\.rawValue)
        ))
        return entry
    }

    func deleteChaplainConversation(id: UUID, remoteID: UUID?) {
        entries.removeAll {
            $0.id == id
                || $0.conversationID == id
                || (remoteID != nil && $0.conversationID == remoteID)
        }
        persist()
        markChanged()
    }

    @discardableResult
    func saveChaplainChat(
        messages: [ChaplainMessage],
        title: String? = nil,
        conversationID: UUID? = nil
    ) -> JournalLocalEntry? {
        let meaningful = messages.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard meaningful.count >= 2 else { return nil }

        let lines = meaningful.map {
            SavedChatLine(
                speaker: $0.role == .user ? "You" : "Chaplain",
                text: $0.text
            )
        }

        let preview = meaningful.last(where: { $0.role == .chaplain })?.text
            ?? meaningful.last?.text
            ?? ""

        let firstUser = meaningful.first(where: { $0.role == .user })?.text ?? "Chaplain conversation"
        let autoTitle = title ?? String(firstUser.prefix(48)).trimmingCharacters(in: .whitespacesAndNewlines)

        let entryID = conversationID ?? UUID()
        let entry = JournalLocalEntry(
            id: entryID,
            kind: .chaplainChat,
            title: autoTitle.isEmpty ? "Chaplain conversation" : autoTitle,
            body: preview,
            moodLabel: "Present",
            moodEmoji: "🙏",
            chatLines: lines,
            conversationID: conversationID
        )

        entries.removeAll { $0.id == entryID || $0.conversationID == conversationID }
        entries.insert(entry, at: 0)
        persist()
        markChanged()

        JourneyTimelineStore.shared.add(JourneyTimelineEntry(
            id: entryID,
            kind: .reflection,
            title: "Saved with Chaplain",
            body: preview,
            moodEmoji: "🙏"
        ))
        return entry
    }

    private func markChanged() {
        revision += 1
        NotificationCenter.default.post(name: .devotionRhythmDidUpdate, object: nil)
    }

    private func load(for userId: UUID) {
        guard let data = UserDefaults.standard.data(forKey: Keys.entries(for: userId)),
              let decoded = try? JSONDecoder().decode([JournalLocalEntry].self, from: data)
        else {
            entries = []
            return
        }
        entries = decoded.map { entry in
            guard entry.kind == .assisted, entry.title == "Evening reflection" else { return entry }
            return JournalLocalEntry(
                id: entry.id,
                createdAt: entry.createdAt,
                kind: .evening,
                title: entry.title,
                body: entry.body,
                moodLabel: entry.moodLabel,
                moodEmoji: entry.moodEmoji,
                chatLines: entry.chatLines,
                conversationID: entry.conversationID
            )
        }
    }

    private func persist() {
        guard let userId = activeUserId,
              let data = try? JSONEncoder().encode(entries)
        else { return }
        UserDefaults.standard.set(data, forKey: Keys.entries(for: userId))
    }

    /// Pre-account journal data lived in a global key and leaked across sign-ups.
    private func purgeLegacyGlobalEntries() {
        UserDefaults.standard.removeObject(forKey: Keys.legacyEntries)
    }
}
