//
//  ScriptureLibraryStore.swift
//  DevotionLock
//

import Foundation
import Observation

@Observable
@MainActor
final class ScriptureLibraryStore {
    static let shared = ScriptureLibraryStore()

    private enum Keys {
        static let saved = "scriptureLibrarySaved"
    }

    private(set) var items: [SavedScripture] = []

    init() {
        load()
    }

    var count: Int { items.count }

    func isSaved(dedupKey: String) -> Bool {
        items.contains { $0.dedupKey == dedupKey }
    }

    func isSaved(passage: SpiritualPassage) -> Bool {
        isSaved(dedupKey: "curated:\(passage.id)")
    }

    func isSaved(reference: String) -> Bool {
        isSaved(dedupKey: "bible:\(reference.lowercased())")
    }

    @discardableResult
    func save(_ item: SavedScripture) -> SavedScripture {
        items.removeAll { $0.dedupKey == item.dedupKey }
        items.insert(item, at: 0)
        persist()

        JourneyTimelineStore.shared.add(JourneyTimelineEntry(
            kind: .verse,
            title: "Saved to library",
            body: item.text,
            verseReference: item.reference
        ))
        return item
    }

    @discardableResult
    func toggleCurated(_ passage: SpiritualPassage) -> Bool {
        let key = "curated:\(passage.id)"
        if isSaved(dedupKey: key) {
            remove(dedupKey: key)
            return false
        }
        save(.fromCurated(passage))
        return true
    }

    @discardableResult
    func toggleBible(
        verses: [BibleVerse],
        content: BibleChapterContent,
        reference: String
    ) -> Bool {
        let key = "bible:\(reference.lowercased())"
        if isSaved(dedupKey: key) {
            remove(dedupKey: key)
            return false
        }
        save(.fromBible(verses: verses, content: content, reference: reference))
        return true
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    func remove(dedupKey: String) {
        items.removeAll { $0.dedupKey == dedupKey }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Keys.saved),
              let decoded = try? JSONDecoder().decode([SavedScripture].self, from: data)
        else { return }
        items = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: Keys.saved)
    }
}
