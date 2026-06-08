//
//  LoadingQuotes.swift
//  DevotionLock
//

import Foundation

struct LoadingQuote: Equatable {
    let text: String
    let reference: String
}

enum LoadingQuoteCatalog {
    static let all: [LoadingQuote] = [
        LoadingQuote(
            text: "Be still, and know that I am God.",
            reference: "Psalm 46:10"
        ),
        LoadingQuote(
            text: "The Lord is my shepherd; I shall not want.",
            reference: "Psalm 23:1"
        ),
        LoadingQuote(
            text: "Come to me, all you who are weary, and I will give you rest.",
            reference: "Matthew 11:28"
        ),
        LoadingQuote(
            text: "You will keep in perfect peace those whose minds are steadfast.",
            reference: "Isaiah 26:3"
        ),
        LoadingQuote(
            text: "Cast all your anxiety on him because he cares for you.",
            reference: "1 Peter 5:7"
        ),
        LoadingQuote(
            text: "May the God of hope fill you with all joy and peace as you trust in him.",
            reference: "Romans 15:13"
        ),
        LoadingQuote(
            text: "Solitude is a formative place because it gives God time and space to do deep work in us.",
            reference: "Ruth Haley Barton"
        ),
        LoadingQuote(
            text: "The sacred is woven into the ordinary.",
            reference: "Tish Harrison Warren"
        ),
        LoadingQuote(
            text: "To pray is to listen to the voice of the One who calls you 'my beloved.'",
            reference: "Henri Nouwen"
        ),
        LoadingQuote(
            text: "Peace I leave with you; my peace I give you.",
            reference: "John 14:27"
        ),
    ]

    static var today: LoadingQuote {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return all[day % all.count]
    }
}
