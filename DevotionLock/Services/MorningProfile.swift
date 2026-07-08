//
//  MorningProfile.swift
//  DevotionLock
//
//  Lightweight, on-device personalization for the adaptive morning flow.
//  Learns the user's recent moods, focus, preferred input, and which
//  passages they've already seen so each morning feels fresh and personal.
//

import Foundation
import SwiftUI

enum MorningInputPreference: String, Codable {
    case unset
    case speak
    case type
}

enum MorningTier: String, Codable, CaseIterable, Identifiable {
    case quick      // ~90s
    case standard   // ~5m
    case deep       // ~10m

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quick: "Quick"
        case .standard: "Steady"
        case .deep: "Deep"
        }
    }

    var minutesLabel: String {
        switch self {
        case .quick: "90 sec"
        case .standard: "5 min"
        case .deep: "10 min"
        }
    }

    var subtitle: String {
        switch self {
        case .quick: "A breath and a verse"
        case .standard: "Reflect and pray"
        case .deep: "Sit a while longer"
        }
    }

    var icon: String {
        switch self {
        case .quick: "bolt.fill"
        case .standard: "sun.horizon.fill"
        case .deep: "moon.stars.fill"
        }
    }

    /// Whether the optional "depth" card is offered for this tier.
    var includesDepth: Bool { self != .quick }
}

@Observable
@MainActor
final class MorningProfile {
    static let shared = MorningProfile()

    private enum Keys {
        static let recentMoods = "morningProfile.recentMoods"
        static let recentTags = "morningProfile.recentTags"
        static let seenPassages = "morningProfile.seenPassages"
        static let inputPreference = "morningProfile.inputPreference"
        static let preferredTier = "morningProfile.preferredTier"
        static let preferredPath = "morningProfile.preferredPath"
        static let completionCount = "morningProfile.completionCount"
    }

    private(set) var recentMoods: [String] = []
    private(set) var recentTags: [String] = []
    private(set) var seenPassageIDs: [String] = []
    private(set) var completionCount: Int = 0
    var inputPreference: MorningInputPreference = .unset
    var preferredTier: MorningTier = .standard
    var preferredPath: MorningPath = .pray

    init() { load() }

    // MARK: - Derived signals

    var isReturning: Bool { completionCount > 0 }

    var dominantMood: String? {
        guard !recentMoods.isEmpty else { return nil }
        let counts = Dictionary(grouping: recentMoods, by: { $0 }).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }

    var dominantTags: [FocusTag] {
        let counts = Dictionary(grouping: recentTags, by: { $0 }).mapValues(\.count)
        let sorted = counts.sorted { $0.value > $1.value }.map(\.key)
        return FocusTag.from(rawValues: Array(sorted.prefix(2)))
    }

    /// Time-aware greeting that nods to the user's recent pattern.
    func greeting(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let salutation: String
        switch hour {
        case 0..<5: salutation = "Still awake"
        case 5..<12: salutation = "Good morning"
        case 12..<17: salutation = "Good afternoon"
        default: salutation = "Good evening"
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? salutation : "\(salutation), \(trimmed)"
    }

    /// One open, reflective prompt tuned to mood + focus + local patterns.
    func openPrompt(mood: String, tags: [FocusTag]) -> String {
        let themes = LocalInsightEngine.analyze().topThemes
        if let theme = themes.first {
            switch theme.id {
            case "anxiety":
                return "You've been carrying worry lately. What's one small weight you could set down this morning?"
            case "gratitude":
                return "Gratitude keeps surfacing for you. What grace are you noticing before the day begins?"
            case "rest":
                return "Rest has been on your heart. Where could you receive gentleness today?"
            case "family":
                return "Family keeps showing up in your reflections. Who needs your presence today?"
            case "work":
                return "Work is on your mind. What would it look like to bring your whole self, not just your tasks?"
            case "faith":
                return "Your faith thread is deepening. Where do you most want to sense God with you today?"
            case "relationships":
                return "Relationships are stirring in you. Who is on your heart this morning, and why?"
            case "health":
                return "You've been thinking about health. How can you be kind to your body today?"
            default:
                break
            }
        }

        let moodKey = mood.lowercased()

        if let tag = tags.first {
            switch tag {
            case .family: return "What does love look like for your family today?"
            case .work: return "What would it mean to bring your whole self to work today?"
            case .rest: return "Where could you let yourself slow down today?"
            case .faith: return "Where do you most want to sense God with you today?"
            case .health: return "How can you be gentle with your body today?"
            case .relationships: return "Who is on your heart this morning, and why?"
            }
        }

        switch moodKey {
        case "peaceful": return "What is one thing you don't want to take for granted today?"
        case "overwhelmed": return "If you could set down one weight this morning, what would it be?"
        case "grateful": return "What small grace are you most thankful for right now?"
        case "restless": return "What is your heart actually searching for today?"
        case "hopeful": return "What are you quietly hoping God will do today?"
        default: return "What's true for you right now, before the day begins?"
        }
    }

    /// A short "carry with you" line paired with the revealed passage.
    /// Anchored to the passage's themes so it echoes the verse, and rotated
    /// by day + passage so the same line never greets every morning.
    func affirmation(mood: String, tags: [FocusTag], passage: SpiritualPassage? = nil) -> String {
        if let passage {
            let lines = passage.topics.flatMap { Self.carryLines[$0] ?? [] }
            if !lines.isEmpty {
                return lines[carrySeed(for: passage) % lines.count]
            }
        }

        if let tag = tags.first {
            switch tag {
            case .family: return "Today I will love the people closest to me with patience."
            case .work: return "I bring my work to God and ask for clarity, one task at a time."
            case .rest: return "I am allowed to rest. I don't have to earn this day."
            case .faith: return "I will look for God in the ordinary moments today."
            case .health: return "I will care for my body as a gift, not a project."
            case .relationships: return "I choose grace in the relationships I carry today."
            }
        }
        switch mood.lowercased() {
        case "overwhelmed": return "I don't have to hold everything. I am held."
        case "restless": return "I can be still. What I need will meet me here."
        case "grateful": return "Gratitude will set the tone for my whole day."
        case "hopeful": return "I will walk toward today with open, hopeful hands."
        default: return "I begin this day grounded, unhurried, and not alone."
        }
    }

    /// Stable per-day, per-passage seed (String.hashValue is randomized per launch).
    private func carrySeed(for passage: SpiritualPassage) -> Int {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let idHash = passage.id.unicodeScalars.reduce(0) { $0 &* 31 &+ Int($1.value) }
        return abs(day &+ idHash)
    }

    /// Carry-with-you lines keyed to passage themes — each echoes the verse it follows.
    private static let carryLines: [PassageTopic: [String]] = [
        .peace: [
            "I carry God's peace into whatever today holds.",
            "Stillness is one breath away, all day long.",
            "I don't have to manufacture calm. I can receive it.",
        ],
        .anxiety: [
            "What worries me today, I hand over as it comes.",
            "I am held, even when my thoughts race.",
            "Today I trade my grip for God's care, one worry at a time.",
        ],
        .hope: [
            "I will watch for the small ways light breaks in today.",
            "Today is not finished, and neither is God.",
            "I carry a hope that doesn't depend on how today goes.",
        ],
        .gratitude: [
            "I will name the small graces as they come today.",
            "Today I choose to notice before I ask.",
            "Thankfulness will be my first response, not my last.",
        ],
        .rest: [
            "I am allowed to move gently through today.",
            "I don't have to earn my rest. It is given.",
            "Today I will stop before I am empty.",
        ],
        .guidance: [
            "One step at a time is enough for today.",
            "I don't need the whole map, just the next step.",
            "Today I will listen before I decide.",
        ],
        .strength: [
            "I do not face today in my own strength.",
            "What today asks of me, God will carry with me.",
            "I am stronger held than striving.",
        ],
        .love: [
            "Today I will let myself be loved first, and love from there.",
            "I will lead with tenderness today.",
            "Love is the strongest thing I carry today.",
        ],
        .faith: [
            "I will look for God in the ordinary moments today.",
            "Today I act on what I believe, not only what I feel.",
            "I walk into today trusting God is already ahead of me.",
        ],
        .grief: [
            "I can carry sorrow and hope in the same hands today.",
            "My tears are safe with God today.",
            "Today I let myself feel, and let myself be comforted.",
        ],
        .forgiveness: [
            "Today I loosen my grip on what someone owes me.",
            "I receive mercy today, and I pass it on.",
            "Grace brought me here; grace can go with me.",
        ],
        .courage: [
            "I will do the brave thing today, even quietly.",
            "Fear may ride along today, but it doesn't drive.",
            "I am not alone in what I have to face today.",
        ],
        .provision: [
            "What I truly need today will be there.",
            "I have enough for today, and today is all I'm asked to carry.",
            "I will hold what I have with open hands today.",
        ],
        .presence: [
            "God is with me in every room I enter today.",
            "I will pause today and remember I am accompanied.",
            "No moment of today is out of God's sight or reach.",
        ],
        .joy: [
            "I will let delight interrupt me today.",
            "Joy is allowed today, even here.",
            "I will take the joy today offers without apology.",
        ],
        .promises: [
            "What God said, God will do. I can build on that today.",
            "I stand on promises older than my worries.",
            "Today I lean on what is promised, not just what I can see.",
        ],
    ]

    // MARK: - Recording a session

    func recordCompletion(mood: String, tags: [FocusTag], passageID: String, tier: MorningTier) {
        recentMoods.insert(mood, at: 0)
        recentMoods = Array(recentMoods.prefix(10))

        for tag in tags {
            recentTags.insert(tag.rawValue, at: 0)
        }
        recentTags = Array(recentTags.prefix(12))

        if !seenPassageIDs.contains(passageID) {
            seenPassageIDs.insert(passageID, at: 0)
            seenPassageIDs = Array(seenPassageIDs.prefix(12))
        }

        preferredTier = tier
        completionCount += 1
        save()
        Task { await UserPreferencesSync.shared.pushMorningProfile() }
    }

    func notePathChoice(_ path: MorningPath) {
        preferredPath = path
        save()
        Task { await UserPreferencesSync.shared.pushMorningProfile() }
    }

    func noteInputChoice(_ choice: MorningInputPreference) {
        inputPreference = choice
        save()
        Task { await UserPreferencesSync.shared.pushMorningProfile() }
    }

    func applyRemote(_ payload: MorningProfilePayload) {
        recentMoods = payload.recentMoods
        recentTags = payload.recentTags
        seenPassageIDs = payload.seenPassageIDs
        completionCount = payload.completionCount
        if let pref = MorningInputPreference(rawValue: payload.inputPreference) {
            inputPreference = pref
        }
        if let tier = MorningTier(rawValue: payload.preferredTier) {
            preferredTier = tier
        }
        if let path = MorningPath(rawValue: payload.preferredPath ?? "") {
            preferredPath = path
        }
        save()
    }

    var recentlySeen: Set<String> { Set(seenPassageIDs) }

    // MARK: - Persistence

    private func load() {
        let defaults = UserDefaults.standard
        recentMoods = defaults.stringArray(forKey: Keys.recentMoods) ?? []
        recentTags = defaults.stringArray(forKey: Keys.recentTags) ?? []
        seenPassageIDs = defaults.stringArray(forKey: Keys.seenPassages) ?? []
        completionCount = defaults.integer(forKey: Keys.completionCount)
        if let raw = defaults.string(forKey: Keys.inputPreference),
           let pref = MorningInputPreference(rawValue: raw) {
            inputPreference = pref
        }
        if let raw = defaults.string(forKey: Keys.preferredTier),
           let tier = MorningTier(rawValue: raw) {
            preferredTier = tier
        }
        if let raw = defaults.string(forKey: Keys.preferredPath),
           let path = MorningPath(rawValue: raw) {
            preferredPath = path
        }
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(recentMoods, forKey: Keys.recentMoods)
        defaults.set(recentTags, forKey: Keys.recentTags)
        defaults.set(seenPassageIDs, forKey: Keys.seenPassages)
        defaults.set(completionCount, forKey: Keys.completionCount)
        defaults.set(inputPreference.rawValue, forKey: Keys.inputPreference)
        defaults.set(preferredTier.rawValue, forKey: Keys.preferredTier)
        defaults.set(preferredPath.rawValue, forKey: Keys.preferredPath)
    }
}
