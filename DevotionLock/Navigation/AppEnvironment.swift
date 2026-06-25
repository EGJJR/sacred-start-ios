//
//  AppEnvironment.swift
//  DevotionLock
//
//  Shared environment keys for app shell routing and services.
//

import SwiftUI

// MARK: - Root

private struct PresentDevotionPaywallKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct AuthManagerKey: EnvironmentKey {
    static let defaultValue = AuthManager.shared
}

// MARK: - Main tab actions

private struct OpenConversationKey: EnvironmentKey {
    static let defaultValue: (Conversation) -> Void = { _ in }
}

private struct OpenChaplainChatKey: EnvironmentKey {
    static let defaultValue: (String?, [ChaplainMessage]) -> Void = { _, _ in }
}

private struct OpenChaplainChatWithPortalKey: EnvironmentKey {
    static let defaultValue: (String, String?, [ChaplainMessage]) -> Void = { _, _, _ in }
}

private struct ResumeChaplainChatKey: EnvironmentKey {
    static let defaultValue: (Conversation) -> Void = { _ in }
}

private struct OpenVoiceSessionKey: EnvironmentKey {
    static let defaultValue: (String?) -> Void = { _ in }
}

private struct OpenGuidedJournalKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenJournalEntryHubKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenAssistedJournalKey: EnvironmentKey {
    static let defaultValue: (String?) -> Void = { _ in }
}

private struct OpenVoiceJournalKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenStreakScreenKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenMorningWrappedKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenPrayerWallKey: EnvironmentKey {
    static let defaultValue: (PrayerNoteKind?) -> Void = { _ in }
}

private struct OpenJourneyTimelineKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenDailyVerseKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenEveningReflectionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct SelectTabKey: EnvironmentKey {
    static let defaultValue: (AppTab) -> Void = { _ in }
}

private struct StreakManagerKey: EnvironmentKey {
    static let defaultValue = StreakManager.shared
}

extension EnvironmentValues {
    var presentDevotionPaywall: () -> Void {
        get { self[PresentDevotionPaywallKey.self] }
        set { self[PresentDevotionPaywallKey.self] = newValue }
    }

    var authManager: AuthManager {
        get { self[AuthManagerKey.self] }
        set { self[AuthManagerKey.self] = newValue }
    }

    var openConversation: (Conversation) -> Void {
        get { self[OpenConversationKey.self] }
        set { self[OpenConversationKey.self] = newValue }
    }

    var openChaplainChat: (String?, [ChaplainMessage]) -> Void {
        get { self[OpenChaplainChatKey.self] }
        set { self[OpenChaplainChatKey.self] = newValue }
    }

    /// Hub compose pill — plays the sanctuary portal bloom before full chat.
    var openChaplainChatWithPortal: (String, String?, [ChaplainMessage]) -> Void {
        get { self[OpenChaplainChatWithPortalKey.self] }
        set { self[OpenChaplainChatWithPortalKey.self] = newValue }
    }

    var resumeChaplainChat: (Conversation) -> Void {
        get { self[ResumeChaplainChatKey.self] }
        set { self[ResumeChaplainChatKey.self] = newValue }
    }

    var openVoiceSession: (String?) -> Void {
        get { self[OpenVoiceSessionKey.self] }
        set { self[OpenVoiceSessionKey.self] = newValue }
    }

    var openGuidedJournal: () -> Void {
        get { self[OpenGuidedJournalKey.self] }
        set { self[OpenGuidedJournalKey.self] = newValue }
    }

    var openJournalEntryHub: () -> Void {
        get { self[OpenJournalEntryHubKey.self] }
        set { self[OpenJournalEntryHubKey.self] = newValue }
    }

    var openAssistedJournal: (String?) -> Void {
        get { self[OpenAssistedJournalKey.self] }
        set { self[OpenAssistedJournalKey.self] = newValue }
    }

    var openVoiceJournal: () -> Void {
        get { self[OpenVoiceJournalKey.self] }
        set { self[OpenVoiceJournalKey.self] = newValue }
    }

    var openStreakScreen: () -> Void {
        get { self[OpenStreakScreenKey.self] }
        set { self[OpenStreakScreenKey.self] = newValue }
    }

    var openMorningWrapped: () -> Void {
        get { self[OpenMorningWrappedKey.self] }
        set { self[OpenMorningWrappedKey.self] = newValue }
    }

    var openPrayerWall: (PrayerNoteKind?) -> Void {
        get { self[OpenPrayerWallKey.self] }
        set { self[OpenPrayerWallKey.self] = newValue }
    }

    var openJourneyTimeline: () -> Void {
        get { self[OpenJourneyTimelineKey.self] }
        set { self[OpenJourneyTimelineKey.self] = newValue }
    }

    var openDailyVerse: () -> Void {
        get { self[OpenDailyVerseKey.self] }
        set { self[OpenDailyVerseKey.self] = newValue }
    }

    var openEveningReflection: () -> Void {
        get { self[OpenEveningReflectionKey.self] }
        set { self[OpenEveningReflectionKey.self] = newValue }
    }

    var selectTab: (AppTab) -> Void {
        get { self[SelectTabKey.self] }
        set { self[SelectTabKey.self] = newValue }
    }

    var streakManager: StreakManager {
        get { self[StreakManagerKey.self] }
        set { self[StreakManagerKey.self] = newValue }
    }
}
