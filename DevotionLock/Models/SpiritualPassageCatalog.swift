//
//  SpiritualPassageCatalog.swift
//  DevotionLock
//

import Foundation
import SwiftUI

enum PassageTopic: String, CaseIterable, Identifiable {
    case peace
    case anxiety
    case hope
    case gratitude
    case rest
    case guidance
    case strength
    case love
    case faith
    case grief
    case forgiveness
    case courage
    case provision
    case presence
    case joy
    case promises

    var id: String { rawValue }

    var label: String {
        switch self {
        case .peace: "Peace"
        case .anxiety: "Anxiety"
        case .hope: "Hope"
        case .gratitude: "Gratitude"
        case .rest: "Rest"
        case .guidance: "Guidance"
        case .strength: "Strength"
        case .love: "Love"
        case .faith: "Faith"
        case .grief: "Grief"
        case .forgiveness: "Forgiveness"
        case .courage: "Courage"
        case .provision: "Provision"
        case .presence: "Presence"
        case .joy: "Joy"
        case .promises: "Promises"
        }
    }

    var icon: String {
        switch self {
        case .peace: "leaf.fill"
        case .anxiety: "wind"
        case .hope: "sun.horizon.fill"
        case .gratitude: "heart.fill"
        case .rest: "moon.zzz.fill"
        case .guidance: "signpost.right.fill"
        case .strength: "figure.strengthtraining.traditional"
        case .love: "heart.circle.fill"
        case .faith: "hands.sparkles.fill"
        case .grief: "cloud.rain.fill"
        case .forgiveness: "arrow.triangle.2.circlepath"
        case .courage: "flame.fill"
        case .provision: "basket.fill"
        case .presence: "sparkles"
        case .joy: "sun.max.fill"
        case .promises: "seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .peace, .rest: ABY.Color.pillTeal
        case .anxiety, .grief: ABY.Color.pillPurple
        case .hope, .joy: ABY.Color.pillOrange
        case .gratitude, .love: ABY.Color.pillPink
        case .guidance, .faith, .presence, .promises: ABY.Color.pillPurple
        case .strength, .courage, .provision, .forgiveness: ABY.Color.pillOrange
        }
    }
}

struct SpiritualPassage: Identifiable, Equatable {
    enum Source: String {
        case scripture
        case author

        var label: String {
            switch self {
            case .scripture: "Scripture"
            case .author: "Wisdom"
            }
        }
    }

    let id: String
    let text: String
    let reference: String
    let source: Source
    let author: String?
    let topics: [PassageTopic]

    var attribution: String {
        if source == .scripture { return reference }
        if let author { return "— \(author)" }
        return reference
    }

    static func == (lhs: SpiritualPassage, rhs: SpiritualPassage) -> Bool {
        lhs.id == rhs.id
    }
}

enum SpiritualPassageCatalog {
    static let all: [SpiritualPassage] = [
        // Scripture
        SpiritualPassage(id: "s1", text: "Cast all your anxiety on him because he cares for you.", reference: "1 Peter 5:7", source: .scripture, author: nil, topics: [.anxiety, .peace, .presence]),
        SpiritualPassage(id: "s2", text: "The Lord is my shepherd; I shall not want.", reference: "Psalm 23:1", source: .scripture, author: nil, topics: [.guidance, .provision, .presence, .promises]),
        SpiritualPassage(id: "s3", text: "Be still, and know that I am God.", reference: "Psalm 46:10", source: .scripture, author: nil, topics: [.peace, .presence, .faith]),
        SpiritualPassage(id: "s4", text: "Trust in the Lord with all your heart and lean not on your own understanding.", reference: "Proverbs 3:5", source: .scripture, author: nil, topics: [.guidance, .faith, .courage]),
        SpiritualPassage(id: "s5", text: "Come to me, all you who are weary and burdened, and I will give you rest.", reference: "Matthew 11:28", source: .scripture, author: nil, topics: [.rest, .peace, .presence]),
        SpiritualPassage(id: "s6", text: "The steadfast love of the Lord never ceases; his mercies never come to an end.", reference: "Lamentations 3:22", source: .scripture, author: nil, topics: [.hope, .love, .promises]),
        SpiritualPassage(id: "s7", text: "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.", reference: "Philippians 4:6", source: .scripture, author: nil, topics: [.anxiety, .peace, .gratitude]),
        SpiritualPassage(id: "s8", text: "Weeping may stay for the night, but rejoicing comes in the morning.", reference: "Psalm 30:5", source: .scripture, author: nil, topics: [.hope, .grief, .joy]),
        SpiritualPassage(id: "s9", text: "I can do all things through Christ who strengthens me.", reference: "Philippians 4:13", source: .scripture, author: nil, topics: [.strength, .courage, .faith]),
        SpiritualPassage(id: "s10", text: "And we know that in all things God works for the good of those who love him.", reference: "Romans 8:28", source: .scripture, author: nil, topics: [.hope, .faith, .promises]),
        SpiritualPassage(id: "s11", text: "Give thanks to the Lord, for he is good; his love endures forever.", reference: "Psalm 107:1", source: .scripture, author: nil, topics: [.gratitude, .love, .joy]),
        SpiritualPassage(id: "s12", text: "Be kind to one another, tenderhearted, forgiving one another, as God in Christ forgave you.", reference: "Ephesians 4:32", source: .scripture, author: nil, topics: [.forgiveness, .love]),
        SpiritualPassage(id: "s13", text: "So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you.", reference: "Isaiah 41:10", source: .scripture, author: nil, topics: [.strength, .courage, .faith]),
        SpiritualPassage(id: "s14", text: "Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.", reference: "Joshua 1:9", source: .scripture, author: nil, topics: [.courage, .strength, .guidance]),
        SpiritualPassage(id: "s15", text: "Therefore do not worry about tomorrow, for tomorrow will worry about itself.", reference: "Matthew 6:34", source: .scripture, author: nil, topics: [.anxiety, .peace, .rest]),
        SpiritualPassage(id: "s16", text: "But those who hope in the Lord will renew their strength. They will soar on wings like eagles.", reference: "Isaiah 40:31", source: .scripture, author: nil, topics: [.strength, .hope, .faith]),
        SpiritualPassage(id: "s17", text: "I sought the Lord, and he answered me; he delivered me from all my fears.", reference: "Psalm 34:4", source: .scripture, author: nil, topics: [.anxiety, .peace, .faith]),
        SpiritualPassage(id: "s18", text: "Cast your cares on the Lord and he will sustain you; he will never let the righteous be shaken.", reference: "Psalm 55:22", source: .scripture, author: nil, topics: [.anxiety, .rest, .presence]),
        SpiritualPassage(id: "s19", text: "Peace I leave with you; my peace I give you. Do not let your hearts be troubled and do not be afraid.", reference: "John 14:27", source: .scripture, author: nil, topics: [.peace, .anxiety, .presence]),
        SpiritualPassage(id: "s20", text: "May the God of hope fill you with all joy and peace as you trust in him.", reference: "Romans 15:13", source: .scripture, author: nil, topics: [.hope, .joy, .peace]),
        SpiritualPassage(id: "s21", text: "For God has not given us a spirit of fear, but of power, love and self-discipline.", reference: "2 Timothy 1:7", source: .scripture, author: nil, topics: [.courage, .strength, .love]),
        SpiritualPassage(id: "s22", text: "Be strong and courageous. Do not be afraid or terrified, for the Lord your God goes with you.", reference: "Deuteronomy 31:6", source: .scripture, author: nil, topics: [.courage, .strength, .presence]),
        SpiritualPassage(id: "s23", text: "The Lord is good, a refuge in times of trouble. He cares for those who trust in him.", reference: "Nahum 1:7", source: .scripture, author: nil, topics: [.grief, .hope, .presence]),
        SpiritualPassage(id: "s24", text: "When you pass through the waters, I will be with you; when you pass through the rivers, they will not sweep over you.", reference: "Isaiah 43:2", source: .scripture, author: nil, topics: [.courage, .promises, .presence]),
        SpiritualPassage(id: "s25", text: "And surely I am with you always, to the very end of the age.", reference: "Matthew 28:20", source: .scripture, author: nil, topics: [.presence, .promises, .faith]),
        SpiritualPassage(id: "s26", text: "Let the peace of Christ rule in your hearts, since as members of one body you were called to peace.", reference: "Colossians 3:15", source: .scripture, author: nil, topics: [.peace, .love]),
        SpiritualPassage(id: "s27", text: "If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault.", reference: "James 1:5", source: .scripture, author: nil, topics: [.guidance, .faith]),
        SpiritualPassage(id: "s28", text: "Whoever dwells in the shelter of the Most High will rest in the shadow of the Almighty.", reference: "Psalm 91:1", source: .scripture, author: nil, topics: [.rest, .presence, .peace]),
        SpiritualPassage(id: "s29", text: "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.", reference: "Jeremiah 29:11", source: .scripture, author: nil, topics: [.hope, .promises, .guidance]),
        SpiritualPassage(id: "s30", text: "Never will I leave you; never will I forsake you.", reference: "Hebrews 13:5", source: .scripture, author: nil, topics: [.provision, .presence, .promises]),
        SpiritualPassage(id: "s31", text: "The Lord is my light and my salvation—whom shall I fear?", reference: "Psalm 27:1", source: .scripture, author: nil, topics: [.courage, .strength, .faith]),

        // Martin Luther
        SpiritualPassage(id: "l1", text: "Pray, and let God worry.", reference: "On Prayer", source: .author, author: "Martin Luther", topics: [.anxiety, .faith, .rest]),
        SpiritualPassage(id: "l2", text: "Faith is a living, daring confidence in God's grace.", reference: "Preface to Romans", source: .author, author: "Martin Luther", topics: [.faith, .courage]),
        SpiritualPassage(id: "l3", text: "Everything that is done in the world is done by hope.", reference: "Table Talk", source: .author, author: "Martin Luther", topics: [.hope, .courage]),

        // C.S. Lewis
        SpiritualPassage(id: "c1", text: "You can't go back and change the beginning, but you can start where you are and change the ending.", reference: "Letters", source: .author, author: "C.S. Lewis", topics: [.hope, .courage, .forgiveness]),
        SpiritualPassage(id: "c2", text: "Humility is not thinking less of yourself, it's thinking of yourself less.", reference: "Mere Christianity", source: .author, author: "C.S. Lewis", topics: [.guidance, .love]),
        SpiritualPassage(id: "c3", text: "God whispers to us in our pleasures, speaks in our conscience, but shouts in our pains.", reference: "The Problem of Pain", source: .author, author: "C.S. Lewis", topics: [.grief, .faith, .presence]),
        SpiritualPassage(id: "c4", text: "There are far, far better things ahead than any we leave behind.", reference: "Letters", source: .author, author: "C.S. Lewis", topics: [.hope, .grief, .joy]),

        // Billy Graham
        SpiritualPassage(id: "b1", text: "Courage is contagious. When a brave man takes a stand, the spines of others are often stiffened.", reference: "Quotes", source: .author, author: "Billy Graham", topics: [.courage, .strength]),
        SpiritualPassage(id: "b2", text: "God has given us two hands—one to receive with and the other to give with.", reference: "Quotes", source: .author, author: "Billy Graham", topics: [.gratitude, .love]),
        SpiritualPassage(id: "b3", text: "When we come to the end of ourselves, we come to the beginning of God.", reference: "Quotes", source: .author, author: "Billy Graham", topics: [.faith, .strength, .hope]),

        // Additional voices
        SpiritualPassage(id: "t1", text: "Let gratitude be the pillow upon which you kneel to say your nightly prayer.", reference: "Letters to My Daughter", source: .author, author: "Maya Angelou", topics: [.gratitude, .rest]),
        SpiritualPassage(id: "t2", text: "Faith does not eliminate questions. But faith knows where to take them.", reference: "Walking with God", source: .author, author: "Elisabeth Elliot", topics: [.faith, .guidance]),
        SpiritualPassage(id: "t3", text: "The Christian life is not a constant high. I have my moments of deep discouragement.", reference: "Through Gates of Splendor", source: .author, author: "Elisabeth Elliot", topics: [.hope, .grief, .faith]),
    ]

    // MARK: - Daily rotation

    static var today: SpiritualPassage {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return all[(day - 1) % all.count]
    }

    static var todayScripture: SpiritualPassage {
        let scriptures = all.filter { $0.source == .scripture }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return scriptures[(day - 1) % scriptures.count]
    }

    static func passage(for date: Date = Date()) -> SpiritualPassage {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return all[(day - 1) % all.count]
    }

    // MARK: - Topical

    static func passages(for topic: PassageTopic) -> [SpiritualPassage] {
        all.filter { $0.topics.contains(topic) }
    }

    static let browsableTopics: [PassageTopic] = [
        .peace, .anxiety, .hope, .gratitude, .rest, .guidance,
        .strength, .faith, .grief, .courage, .love, .promises,
    ]

    /// Picks a passage tuned to mood + focus tags, avoiding recent repeats.
    static func recommended(
        mood: String,
        focusTags: [FocusTag],
        excludingIDs: Set<String> = []
    ) -> SpiritualPassage {
        let topics = matchingTopics(mood: mood, focusTags: focusTags)

        let scored = all.map { passage -> (SpiritualPassage, Int) in
            let overlap = passage.topics.filter { topics.contains($0) }.count
            let penalty = excludingIDs.contains(passage.id) ? -5 : 0
            return (passage, overlap + penalty)
        }

        let best = scored.max { $0.1 < $1.1 }
        if let best, best.1 > 0 {
            // Among top-scoring, rotate by day for variety.
            let topScore = best.1
            let candidates = scored.filter { $0.1 == topScore }.map(\.0)
            let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            return candidates[day % candidates.count]
        }
        return today
    }

    static func matchingTopics(mood: String, focusTags: [FocusTag]) -> Set<PassageTopic> {
        var topics = Set<PassageTopic>()

        switch mood.lowercased() {
        case "peaceful": topics.formUnion([.peace, .gratitude, .presence])
        case "overwhelmed": topics.formUnion([.anxiety, .rest, .peace, .strength])
        case "grateful": topics.formUnion([.gratitude, .joy, .love])
        case "restless": topics.formUnion([.rest, .peace, .guidance])
        case "hopeful": topics.formUnion([.hope, .faith, .joy])
        default: topics.formUnion([.peace, .faith])
        }

        for tag in focusTags {
            switch tag {
            case .family: topics.formUnion([.love, .presence])
            case .work: topics.formUnion([.guidance, .strength, .provision])
            case .rest: topics.formUnion([.rest, .peace])
            case .faith: topics.formUnion([.faith, .hope])
            case .health: topics.formUnion([.strength, .rest, .hope])
            case .relationships: topics.formUnion([.love, .forgiveness])
            }
        }
        return topics
    }

    // MARK: - Search

    static func search(_ query: String) -> [SpiritualPassage] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return all }
        return all.filter { passage in
            passage.text.lowercased().contains(trimmed)
                || passage.reference.lowercased().contains(trimmed)
                || (passage.author?.lowercased().contains(trimmed) ?? false)
                || passage.topics.contains { $0.label.lowercased().contains(trimmed) }
        }
    }
}

struct GuidedPrayer: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let steps: [String]
    let icon: String
    let tintHex: UInt32
}

enum GuidedPrayerCatalog {
    static let all: [GuidedPrayer] = [
        GuidedPrayer(
            id: "morning",
            title: "Morning surrender",
            subtitle: "Begin the day with open hands",
            steps: [
                "Lord, I bring you this day before it begins.",
                "Quiet my mind and settle my heart.",
                "Show me one person who needs my kindness today.",
                "Help me receive your grace as freely as I hope to give it.",
            ],
            icon: "sun.horizon.fill",
            tintHex: 0x4A9B8E
        ),
        GuidedPrayer(
            id: "anxiety",
            title: "When anxious",
            subtitle: "Release what you cannot carry",
            steps: [
                "Father, you see what weighs on me.",
                "I name my fear honestly before you.",
                "Replace my tight grip with your steady peace.",
                "Remind me that you are nearer than my worry.",
            ],
            icon: "leaf.fill",
            tintHex: 0x6B7FD7
        ),
        GuidedPrayer(
            id: "gratitude",
            title: "Gratitude pause",
            subtitle: "Notice grace in small things",
            steps: [
                "Thank you for breath, shelter, and this moment.",
                "Thank you for one person who has loved me well.",
                "Thank you for one mercy I almost overlooked today.",
                "Make my heart quick to notice and slow to complain.",
            ],
            icon: "heart.fill",
            tintHex: 0xE07A5F
        ),
        GuidedPrayer(
            id: "evening",
            title: "Evening examen",
            subtitle: "Review the day with gentleness",
            steps: [
                "Lord, where did I feel your presence with me today?",
                "Father, forgive where I missed the mark — and thank you for where you still met me.",
                "Thank you for one moment today that deserves my gratitude.",
                "Receive me as I am tonight, and guard my rest.",
            ],
            icon: "moon.stars.fill",
            tintHex: 0x7B6BA8
        ),
        GuidedPrayer(
            id: "others",
            title: "Praying for others",
            subtitle: "Hold someone in intercession",
            steps: [
                "Father, I bring someone who is struggling before you now.",
                "Surround them with your comfort and courage.",
                "Give wisdom to everyone who is caring for them.",
                "Send them your peace — whether they know I prayed or not.",
            ],
            icon: "person.2.fill",
            tintHex: 0x5B8DEF
        ),
    ]
}
