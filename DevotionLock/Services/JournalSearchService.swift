//
//  JournalSearchService.swift
//  DevotionLock
//

import Foundation

struct JournalSearchResult: Identifiable {
    enum Source: String {
        case conversation
        case journey
    }

    let id: UUID
    let source: Source
    let title: String
    let preview: String
    let tag: String
    let recordedAt: Date?
    let conversation: Conversation?
    let journeyEntry: JourneyTimelineEntry?
}

enum JournalSearchService {
    @MainActor
    static func search(query: String, tagFilter: String? = nil) -> [JournalSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let normalizedQuery = trimmed.lowercased()
        let normalizedTag = tagFilter?.lowercased()
        let tagMatchesAll = normalizedTag == nil || normalizedTag == "all"

        var results: [JournalSearchResult] = []

        for conversation in ConversationMerger.mergedTimeline() {
            guard matchesTag(conversation.tag, filter: normalizedTag, matchesAll: tagMatchesAll) else { continue }
            guard matchesText(conversation.title, conversation.preview, conversation.tag, query: normalizedQuery) else { continue }

            results.append(JournalSearchResult(
                id: conversation.id,
                source: .conversation,
                title: conversation.title,
                preview: conversation.preview,
                tag: conversation.tag,
                recordedAt: conversation.recordedAt,
                conversation: conversation,
                journeyEntry: nil
            ))
        }

        for entry in JourneyTimelineStore.shared.entries {
            let tag = entry.kind.label
            guard matchesTag(tag, filter: normalizedTag, matchesAll: tagMatchesAll) else { continue }
            let body = entry.body ?? ""
            guard matchesText(entry.title, body, tag, query: normalizedQuery) else { continue }

            results.append(JournalSearchResult(
                id: entry.id,
                source: .journey,
                title: entry.title,
                preview: String(body.prefix(200)),
                tag: tag,
                recordedAt: entry.createdAt,
                conversation: nil,
                journeyEntry: entry
            ))
        }

        return results.sorted { ($0.recordedAt ?? .distantPast) > ($1.recordedAt ?? .distantPast) }
    }

    private static func matchesTag(_ tag: String, filter: String?, matchesAll: Bool) -> Bool {
        guard !matchesAll, let filter else { return true }
        return tag.lowercased().contains(filter)
    }

    private static func matchesText(_ title: String, _ body: String, _ tag: String, query: String) -> Bool {
        title.localizedCaseInsensitiveContains(query)
            || body.localizedCaseInsensitiveContains(query)
            || tag.localizedCaseInsensitiveContains(query)
    }
}
