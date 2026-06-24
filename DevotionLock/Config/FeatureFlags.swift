//
//  FeatureFlags.swift
//  DevotionLock
//

import Foundation

enum FeatureFlags {
    /// Full Bible reader (reference lookup + chapter browse via bible-api CDN).
    /// Set to `false` to ship v1 with curated passages only.
    static let bibleReaderEnabled = true

    /// Voice capture + talk-with-Chaplain flows. Disabled while text chat UI is refined.
    static let voiceChatEnabled = false
}
