//
//  UserPreferencesSync.swift
//  DevotionLock
//

import Foundation
import Supabase

struct MorningProfilePayload: Codable, Equatable {
    var recentMoods: [String]
    var recentTags: [String]
    var seenPassageIDs: [String]
    var inputPreference: String
    var preferredTier: String
    var preferredPath: String?
    var completionCount: Int

    static func from(_ profile: MorningProfile) -> MorningProfilePayload {
        MorningProfilePayload(
            recentMoods: profile.recentMoods,
            recentTags: profile.recentTags,
            seenPassageIDs: profile.seenPassageIDs,
            inputPreference: profile.inputPreference.rawValue,
            preferredTier: profile.preferredTier.rawValue,
            preferredPath: profile.preferredPath.rawValue,
            completionCount: profile.completionCount
        )
    }
}

private struct ProfilePreferencesUpdate: Encodable {
    let chaplainVoiceId: String
    let intentionMood: String
    let morningProfile: MorningProfilePayload?

    enum CodingKeys: String, CodingKey {
        case chaplainVoiceId = "chaplain_voice_id"
        case intentionMood = "intention_mood"
        case morningProfile = "morning_profile"
    }
}

private struct RemoteProfilePreferences: Decodable {
    let chaplainVoiceId: String?
    let intentionMood: String?
    let isPremium: Bool?
    let morningProfile: MorningProfilePayload?

    enum CodingKeys: String, CodingKey {
        case chaplainVoiceId = "chaplain_voice_id"
        case intentionMood = "intention_mood"
        case isPremium = "is_premium"
        case morningProfile = "morning_profile"
    }
}

@MainActor
final class UserPreferencesSync {
    static let shared = UserPreferencesSync()

    func pullAndApply() async {
        guard AuthManager.shared.isAuthenticated, let userId = AuthManager.shared.userId else { return }

        do {
            let rows: [RemoteProfilePreferences] = try await SupabaseManager.client
                .from("profiles")
                .select("chaplain_voice_id, intention_mood, is_premium, morning_profile")
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            guard let profile = rows.first else { return }

            if let voice = profile.chaplainVoiceId, !voice.isEmpty {
                UserDefaults.standard.set(voice, forKey: "selectedChaplainVoice")
            }
            if let mood = profile.intentionMood, !mood.isEmpty {
                UserDefaults.standard.set(mood, forKey: "intentionMood")
            }
            if let payload = profile.morningProfile {
                MorningProfile.shared.applyRemote(payload)
            }
            if profile.isPremium == true {
                PaywallAccess.markPurchaseSucceeded()
            }
        } catch {
            SyncErrorFilter.logPullFailure("UserPreferencesSync", error)
        }
    }

    func pushPreferences(
        chaplainVoiceID: String? = nil,
        intentionMood: String? = nil,
        morningProfile: MorningProfilePayload? = nil
    ) async {
        guard AuthManager.shared.isAuthenticated, let userId = AuthManager.shared.userId else { return }

        let voice = chaplainVoiceID ?? UserDefaults.standard.string(forKey: "selectedChaplainVoice") ?? "grace"
        let mood = intentionMood ?? UserDefaults.standard.string(forKey: "intentionMood") ?? "Peaceful"
        let profilePayload = morningProfile ?? MorningProfilePayload.from(MorningProfile.shared)

        let update = ProfilePreferencesUpdate(
            chaplainVoiceId: voice,
            intentionMood: mood,
            morningProfile: profilePayload
        )

        do {
            try await SupabaseManager.client
                .from("profiles")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            #if DEBUG
            print("UserPreferencesSync push failed: \(error)")
            #endif
        }
    }

    func pushMorningProfile() async {
        await pushPreferences(morningProfile: MorningProfilePayload.from(MorningProfile.shared))
    }

    func updatePremium(_ isPremium: Bool) async {
        guard AuthManager.shared.isAuthenticated, let userId = AuthManager.shared.userId else { return }

        struct PremiumUpdate: Encodable {
            let isPremium: Bool
            enum CodingKeys: String, CodingKey { case isPremium = "is_premium" }
        }

        do {
            try await SupabaseManager.client
                .from("profiles")
                .update(PremiumUpdate(isPremium: isPremium))
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            SyncErrorFilter.logPullFailure("UserPreferencesSync.updatePremium", error)
        }
    }
}
