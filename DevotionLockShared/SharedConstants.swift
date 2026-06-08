//
//  SharedConstants.swift
//  DevotionLockShared
//

import Foundation

enum DevotionAppGroup {
    static let identifier = "group.com.devotionlock.mobile"
}

enum SharedStorageKey {
    static let widgetSnapshot = "widgetSnapshot"
    static let pendingWidgetAction = "pendingWidgetAction"
    static let answeredCelebrationText = "answeredCelebrationText"
    static let answeredCelebrationUntil = "answeredCelebrationUntil"
}

enum TodayFocusStore {
    private static let key = "todayFocusTags"

    static var tags: [FocusTag] {
        let raw = UserDefaults.standard.stringArray(forKey: key) ?? []
        return FocusTag.from(rawValues: raw)
    }

    static func save(_ tags: [String]) {
        UserDefaults.standard.set(tags, forKey: key)
    }
}

enum FocusTag: String, CaseIterable, Identifiable, Codable {
    case family
    case work
    case rest
    case faith
    case health
    case relationships

    var id: String { rawValue }

    var label: String {
        switch self {
        case .family: "Family"
        case .work: "Work"
        case .rest: "Rest"
        case .faith: "Faith"
        case .health: "Health"
        case .relationships: "Relationships"
        }
    }

    var icon: String {
        switch self {
        case .family: "house.fill"
        case .work: "briefcase.fill"
        case .rest: "leaf.fill"
        case .faith: "hands.sparkles.fill"
        case .health: "heart.fill"
        case .relationships: "person.2.fill"
        }
    }

    static func from(rawValues: [String]) -> [FocusTag] {
        rawValues.compactMap(FocusTag.init(rawValue:))
    }

    static func chaplainPrompt(for tags: [FocusTag]) -> String? {
        guard let first = tags.first else { return nil }
        return switch first {
        case .family: "Help me bring today's devotion into my family life."
        case .work: "I'm carrying work on my heart — guide me with wisdom."
        case .rest: "I need rest today. What might God be inviting me toward?"
        case .faith: "Deepen my faith through what I'm walking through today."
        case .health: "Pray with me over my body and wellbeing today."
        case .relationships: "Help me love the people in my life well today."
        }
    }

    static func prayerWallSuggestion(for tags: [FocusTag]) -> String {
        guard let first = tags.first else {
            return "Lord, meet me in this ordinary day."
        }
        return switch first {
        case .family: "Cover my family with peace and patience today."
        case .work: "Give me clarity and integrity in my work."
        case .rest: "Help me receive the rest my soul needs."
        case .faith: "Draw me closer when my faith feels thin."
        case .health: "Strengthen and sustain my body and spirit."
        case .relationships: "Heal and soften the relationships on my heart."
        }
    }
}

enum AnsweredCelebrationStore {
    static func activate(text: String, duration: TimeInterval = 3600) {
        guard let defaults = UserDefaults(suiteName: DevotionAppGroup.identifier) else { return }
        defaults.set(text, forKey: SharedStorageKey.answeredCelebrationText)
        defaults.set(Date().addingTimeInterval(duration).timeIntervalSince1970, forKey: SharedStorageKey.answeredCelebrationUntil)
    }

    static func current() -> (text: String, active: Bool) {
        guard let defaults = UserDefaults(suiteName: DevotionAppGroup.identifier),
              let text = defaults.string(forKey: SharedStorageKey.answeredCelebrationText)
        else { return ("", false) }
        let until = defaults.double(forKey: SharedStorageKey.answeredCelebrationUntil)
        if until > Date().timeIntervalSince1970 {
            return (text, true)
        }
        clear()
        return ("", false)
    }

    static func clear() {
        guard let defaults = UserDefaults(suiteName: DevotionAppGroup.identifier) else { return }
        defaults.removeObject(forKey: SharedStorageKey.answeredCelebrationText)
        defaults.removeObject(forKey: SharedStorageKey.answeredCelebrationUntil)
    }
}

enum PendingWidgetAction: String, Codable {
    case addPrayerRequest
    case addReminder
    case addAnsweredPrayer
    case openPrayerWall
}

enum PendingWidgetActionStore {
    static func set(_ action: PendingWidgetAction) {
        guard let defaults = UserDefaults(suiteName: DevotionAppGroup.identifier) else { return }
        defaults.set(action.rawValue, forKey: SharedStorageKey.pendingWidgetAction)
    }

    static func consume() -> PendingWidgetAction? {
        guard let defaults = UserDefaults(suiteName: DevotionAppGroup.identifier),
              let raw = defaults.string(forKey: SharedStorageKey.pendingWidgetAction),
              let action = PendingWidgetAction(rawValue: raw)
        else { return nil }
        defaults.removeObject(forKey: SharedStorageKey.pendingWidgetAction)
        return action
    }
}

enum DevotionDeepLink {
    static let scheme = "devotionlock"

    enum Host: String {
        case home
        case journal
        case chaplain
        case prayerWall = "prayer-wall"
        case streak
        case addPrayer = "add-prayer"
        case joinCircle = "join-circle"
    }

    static func url(host: Host, query: [String: String] = [:]) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host.rawValue
        if query.isEmpty == false {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components.url
    }

    static func parse(_ url: URL) -> (host: Host, query: [String: String])? {
        guard url.scheme == scheme, let hostRaw = url.host,
              let host = Host(rawValue: hostRaw) else { return nil }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce(into: [String: String]()) { result, item in
                if let value = item.value { result[item.name] = value }
            } ?? [:]
        return (host, query)
    }
}

extension Notification.Name {
    static let devotionRhythmDidUpdate = Notification.Name("devotionRhythmDidUpdate")
}
