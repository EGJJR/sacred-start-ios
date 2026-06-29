//
//  ReleaseNotes.swift
//  DevotionLock
//
//  In-app release notes via Notelet. Version strings must match CFBundleShortVersionString.
//

import Notelet
import SwiftUI

enum SacredStartReleaseNotes {
    static let all: [NoteletVersionNotes] = [
        .init(
            version: "1.2",
            items: [
                .list(
                    title: "What's new in Sacred Start",
                    rows: [
                        .init(
                            symbolSystemName: "moon.stars.fill",
                            title: "Evening sanctuary",
                            description: "A twilight appearance for night and low-light devotion — frosted cards, starlight buttons, and calm plum backgrounds."
                        ),
                        .init(
                            symbolSystemName: "circle.hexagongrid.fill",
                            title: "Sacred orb shortcuts",
                            description: "Press and hold the orb for quick capture — morning devotion, journal, assisted write, or Chaplain."
                        ),
                        .init(
                            symbolSystemName: "rectangle.bottomthird.inset.filled",
                            title: "Refined navigation",
                            description: "A clearer glass tab bar with the Sacred orb as your daily rhythm coach."
                        ),
                        .init(
                            symbolSystemName: "textformat.size",
                            title: "Easier to read",
                            description: "Contrast and color fixes across journal, Chaplain, morning devotion, guided prayers, and your week in review."
                        ),
                        .init(
                            symbolSystemName: "sparkles",
                            title: "Sacred Start polish",
                            description: "A refreshed app icon, evening-aware loading screen, and a smoother onboarding path."
                        ),
                    ]
                ),
            ]
        ),
        .init(
            version: "1.1",
            items: [
                .list(
                    title: "What's new in Sacred Start",
                    rows: [
                        .init(
                            symbolSystemName: "house.fill",
                            title: "A calmer Home",
                            description: "Today's devotion is front and center — less scrolling, more beginning."
                        ),
                        .init(
                            symbolSystemName: "book.closed.fill",
                            title: "Journal, redesigned",
                            description: "Week strip, capture chips, and a clearer timeline for your reflections."
                        ),
                        .init(
                            symbolSystemName: "bubble.left.and.bubble.right.fill",
                            title: "Chaplain chat polish",
                            description: "A cleaner composer, suggestion chips, and conversation history."
                        ),
                        .init(
                            symbolSystemName: "heart.fill",
                            title: "Sacred Start branding",
                            description: "Refined typography and the Sacred Start name across the app."
                        ),
                        .init(
                            symbolSystemName: "person.3.fill",
                            title: "Prayer circle fixes",
                            description: "Invite codes work more reliably when friends join your circle."
                        ),
                    ]
                ),
            ]
        ),
    ]

    static let configuration = NoteletConfiguration(
        nextButtonLabel: "Continue",
        doneButtonLabel: "Begin today",
        accentColor: DevotionTheme.sage
    )
}
