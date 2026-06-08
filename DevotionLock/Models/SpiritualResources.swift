//
//  SpiritualResources.swift
//  DevotionLock
//

import SwiftUI

enum SpiritualResourceKind: String, Codable {
    case promise
    case passage

    var label: String {
        switch self {
        case .promise: "Promise"
        case .passage: "Passage"
        }
    }

    var icon: String {
        switch self {
        case .promise: "book.closed.fill"
        case .passage: "text.quote"
        }
    }
}

enum SpiritualTopic: String, CaseIterable, Identifiable, Codable {
    case peace
    case hope
    case strength
    case anxiety
    case gratitude
    case rest

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var tint: Color {
        switch self {
        case .peace: ABY.Color.pillTeal
        case .hope: ABY.Color.pillPurple
        case .strength: ABY.Color.pillOrange
        case .anxiety: ABY.Color.pillPink
        case .gratitude: ABY.Color.accentDot
        case .rest: ABY.Color.orbSage
        }
    }

    var gradient: [Color] {
        [tint.opacity(0.85), tint.opacity(0.55)]
    }
}

struct SpiritualResource: Identifiable, Equatable, Codable {
    let id: String
    let kind: SpiritualResourceKind
    let topic: SpiritualTopic
    let text: String
    let reference: String
    let author: String?

    var chatPrompt: String {
        switch kind {
        case .promise:
            return "Help me sit with this promise: \"\(text)\" (\(reference))"
        case .passage:
            let source = author.map { "\(reference), \($0)" } ?? reference
            return "I'd like to reflect on this passage from \(source): \"\(text)\""
        }
    }
}

enum SpiritualResourceCatalog {
    static let all: [SpiritualResource] = promises + passages

    static func filtered(by topic: SpiritualTopic?) -> [SpiritualResource] {
        guard let topic else { return all }
        return all.filter { $0.topic == topic }
    }

    static let promises: [SpiritualResource] = [
        SpiritualResource(
            id: "phil-4-6",
            kind: .promise,
            topic: .anxiety,
            text: "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.",
            reference: "Philippians 4:6",
            author: nil
        ),
        SpiritualResource(
            id: "matt-11-28",
            kind: .promise,
            topic: .rest,
            text: "Come to me, all you who are weary and burdened, and I will give you rest.",
            reference: "Matthew 11:28",
            author: nil
        ),
        SpiritualResource(
            id: "isa-26-3",
            kind: .promise,
            topic: .peace,
            text: "You will keep in perfect peace those whose minds are steadfast, because they trust in you.",
            reference: "Isaiah 26:3",
            author: nil
        ),
        SpiritualResource(
            id: "rom-15-13",
            kind: .promise,
            topic: .hope,
            text: "May the God of hope fill you with all joy and peace as you trust in him, so that you may overflow with hope by the power of the Holy Spirit.",
            reference: "Romans 15:13",
            author: nil
        ),
        SpiritualResource(
            id: "isa-40-31",
            kind: .promise,
            topic: .strength,
            text: "Those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary.",
            reference: "Isaiah 40:31",
            author: nil
        ),
        SpiritualResource(
            id: "1pet-5-7",
            kind: .promise,
            topic: .anxiety,
            text: "Cast all your anxiety on him because he cares for you.",
            reference: "1 Peter 5:7",
            author: nil
        ),
        SpiritualResource(
            id: "1thess-5-18",
            kind: .promise,
            topic: .gratitude,
            text: "Give thanks in all circumstances; for this is God's will for you in Christ Jesus.",
            reference: "1 Thessalonians 5:18",
            author: nil
        ),
        SpiritualResource(
            id: "ps-23-1",
            kind: .promise,
            topic: .rest,
            text: "The Lord is my shepherd, I lack nothing. He makes me lie down in green pastures, he leads me beside quiet waters.",
            reference: "Psalm 23:1–2",
            author: nil
        ),
        SpiritualResource(
            id: "josh-1-9",
            kind: .promise,
            topic: .strength,
            text: "Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.",
            reference: "Joshua 1:9",
            author: nil
        ),
        SpiritualResource(
            id: "john-14-27",
            kind: .promise,
            topic: .peace,
            text: "Peace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid.",
            reference: "John 14:27",
            author: nil
        ),
    ]

    static let passages: [SpiritualResource] = [
        SpiritualResource(
            id: "comer-hurry",
            kind: .passage,
            topic: .rest,
            text: "Hurry is not just a disordered schedule. Hurry is a disordered heart.",
            reference: "The Ruthless Elimination of Hurry",
            author: "John Mark Comer"
        ),
        SpiritualResource(
            id: "warren-ordinary",
            kind: .passage,
            topic: .gratitude,
            text: "How we spend our days is, of course, how we spend our lives. The sacred is woven into the ordinary.",
            reference: "Liturgy of the Ordinary",
            author: "Tish Harrison Warren"
        ),
        SpiritualResource(
            id: "barton-rhythms",
            kind: .passage,
            topic: .peace,
            text: "Solitude is a formative place because it gives God time and space to do deep work in us.",
            reference: "Sacred Rhythms",
            author: "Ruth Haley Barton"
        ),
        SpiritualResource(
            id: "nouwen-prayer",
            kind: .passage,
            topic: .anxiety,
            text: "To pray is to listen to the voice of the One who calls you 'my beloved.'",
            reference: "The Way of the Heart",
            author: "Henri Nouwen"
        ),
        SpiritualResource(
            id: "scazzero-emotion",
            kind: .passage,
            topic: .strength,
            text: "It is impossible to be spiritually mature while remaining emotionally immature.",
            reference: "Emotionally Healthy Spirituality",
            author: "Pete Scazzero"
        ),
        SpiritualResource(
            id: "lewis-weight",
            kind: .passage,
            topic: .hope,
            text: "Humility is not thinking less of yourself, but thinking of yourself less.",
            reference: "Mere Christianity",
            author: "C.S. Lewis"
        ),
    ]
}
