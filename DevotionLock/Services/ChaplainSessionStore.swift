//
//  ChaplainSessionStore.swift
//  DevotionLock
//

import Foundation
import Observation

struct ResumableChaplainConversation: Equatable {
    let id: UUID
    let title: String
    let preview: String
    let updatedAt: Date
}

@Observable
@MainActor
final class ChaplainSessionStore {
    static let shared = ChaplainSessionStore()

    private enum Keys {
        static let lastConversationID = "chaplainLastConversationID"
        static let lastTitle = "chaplainLastConversationTitle"
        static let lastPreview = "chaplainLastConversationPreview"
        static let lastUpdatedAt = "chaplainLastConversationUpdatedAt"
    }

    private(set) var resumableConversation: ResumableChaplainConversation?
    var pendingResumeID: UUID?

    init() {
        load()
    }

    func consumePendingResumeID() -> UUID? {
        defer { pendingResumeID = nil }
        return pendingResumeID
    }

    func recordActiveConversation(id: UUID, title: String?, preview: String?) {
        let trimmedPreview = preview?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Chaplain conversation"
        let conversation = ResumableChaplainConversation(
            id: id,
            title: trimmedTitle,
            preview: trimmedPreview.isEmpty ? "Continue where you left off" : String(trimmedPreview.prefix(120)),
            updatedAt: Date()
        )
        resumableConversation = conversation
        persist(conversation)
    }

    func clear() {
        resumableConversation = nil
        pendingResumeID = nil
        UserDefaults.standard.removeObject(forKey: Keys.lastConversationID)
        UserDefaults.standard.removeObject(forKey: Keys.lastTitle)
        UserDefaults.standard.removeObject(forKey: Keys.lastPreview)
        UserDefaults.standard.removeObject(forKey: Keys.lastUpdatedAt)
    }

    private func load() {
        guard
            let idString = UserDefaults.standard.string(forKey: Keys.lastConversationID),
            let id = UUID(uuidString: idString)
        else { return }

        resumableConversation = ResumableChaplainConversation(
            id: id,
            title: UserDefaults.standard.string(forKey: Keys.lastTitle) ?? "Chaplain conversation",
            preview: UserDefaults.standard.string(forKey: Keys.lastPreview) ?? "Continue where you left off",
            updatedAt: UserDefaults.standard.object(forKey: Keys.lastUpdatedAt) as? Date ?? Date()
        )
    }

    private func persist(_ conversation: ResumableChaplainConversation) {
        UserDefaults.standard.set(conversation.id.uuidString, forKey: Keys.lastConversationID)
        UserDefaults.standard.set(conversation.title, forKey: Keys.lastTitle)
        UserDefaults.standard.set(conversation.preview, forKey: Keys.lastPreview)
        UserDefaults.standard.set(conversation.updatedAt, forKey: Keys.lastUpdatedAt)
    }
}
