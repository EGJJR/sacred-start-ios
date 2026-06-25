//
//  MainTabPresentation.swift
//  DevotionLock
//
//  Item-driven sheet and full-screen routing for the main tab shell.
//

import SwiftUI

struct ChaplainChatLaunch: Identifiable, Hashable {
    let sessionID = UUID()
    var starterText: String = ""
    var seedMessages: [ChaplainMessage] = []
    var contextIntent: String?
    var resumeConversationID: UUID?
    var resumedContext: Conversation?
    /// Staggered blur reveal when opened via the hub portal transition.
    var playsPortalEntrance: Bool = false

    var id: UUID { sessionID }
}

struct ChaplainPortalPresentation: Equatable {
    let voiceName: String
    let launch: ChaplainChatLaunch
}

struct PrayerWallLaunch: Identifiable, Hashable {
    var addKind: PrayerNoteKind?
    var initialTab: PrayerWallTab = .myWall
    var joinCode: String?

    var id: String {
        "\(initialTab.rawValue)-\(addKind?.rawValue ?? "none")-\(joinCode ?? "")"
    }
}

enum MainSheetPresentation: Identifiable {
    case streakScreen
    case conversation(Conversation)
    case prayerWall(PrayerWallLaunch)
    case journalEntryHub
    case dailyVerse
    case eveningReflection
    case sacredOrbMenu

    var id: String {
        switch self {
        case .streakScreen:
            "streak-screen"
        case .conversation(let conversation):
            "conversation-\(conversation.id)"
        case .prayerWall(let launch):
            "prayer-wall-\(launch.id)"
        case .journalEntryHub:
            "journal-entry-hub"
        case .dailyVerse:
            "daily-verse"
        case .eveningReflection:
            "evening-reflection"
        case .sacredOrbMenu:
            "sacred-orb-menu"
        }
    }
}

enum MainFullScreenPresentation: Identifiable {
    case chaplain(ChaplainChatLaunch)
    case guidedJournal
    case assistedJournal
    case voiceJournal
    case streakBorn
    case morningWrapped
    case widgetOnboarding
    case journeyTimeline
    case celebration(DevotionFinishResult)
    case milestone(MilestonePresentation)

    var id: String {
        switch self {
        case .chaplain(let launch):
            "chaplain-\(launch.sessionID)"
        case .guidedJournal:
            "guided-journal"
        case .assistedJournal:
            "assisted-journal"
        case .voiceJournal:
            "voice-journal"
        case .streakBorn:
            "streak-born"
        case .morningWrapped:
            "morning-wrapped"
        case .widgetOnboarding:
            "widget-onboarding"
        case .journeyTimeline:
            "journey-timeline"
        case .celebration(let result):
            "celebration-\(result.id)"
        case .milestone(let presentation):
            "milestone-\(presentation.id)"
        }
    }
}
