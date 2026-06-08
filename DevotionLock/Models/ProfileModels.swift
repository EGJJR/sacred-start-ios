//
//  ProfileModels.swift
//  DevotionLock
//

import Foundation

struct UserProfile: Codable, Equatable {
    let id: UUID
    var username: String?
    var avatarURL: String?
    var chaplainVoiceId: String?
    var intentionMood: String?
    var isPremium: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarURL = "avatar_url"
        case chaplainVoiceId = "chaplain_voice_id"
        case intentionMood = "intention_mood"
        case isPremium = "is_premium"
    }

    var avatarURLValue: URL? {
        guard let avatarURL, !avatarURL.isEmpty else { return nil }
        return URL(string: avatarURL)
    }
}

enum UsernameValidator {
    static func normalize(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, trimmed.count <= 30 else { return nil }
        guard !trimmed.contains("@") else { return nil }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._- "))
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        return trimmed
    }

    static func initials(for name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init)
        if letters.isEmpty, let first = name.first {
            return String(first).uppercased()
        }
        return letters.joined().uppercased()
    }
}

enum ProfileError: LocalizedError {
    case notAuthenticated
    case invalidUsername
    case usernameTaken
    case uploadFailed
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            "You must be signed in."
        case .invalidUsername:
            "Username must be 2–30 characters and can only use letters, numbers, spaces, dots, dashes, and underscores."
        case .usernameTaken:
            "That username is already taken."
        case .uploadFailed:
            "Could not upload your photo. Try again."
        case .deleteFailed(let message):
            message
        }
    }
}
