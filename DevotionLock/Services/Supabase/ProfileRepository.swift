//
//  ProfileRepository.swift
//  DevotionLock
//

import Foundation
import Supabase

@MainActor
final class ProfileRepository {
    static let shared = ProfileRepository()

    private init() {}

    func fetchProfile(userId: UUID) async throws -> UserProfile? {
        let rows: [UserProfile] = try await SupabaseManager.client
            .from("profiles")
            .select("id, username, avatar_url, chaplain_voice_id, intention_mood, is_premium")
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    func ensureProfileExists() async throws {
        try await SupabaseManager.client.rpc("ensure_profile").execute()
    }

    func isUsernameAvailable(_ rawUsername: String) async throws -> Bool {
        guard let username = UsernameValidator.normalize(rawUsername) else { return false }

        let available: Bool = try await SupabaseManager.client
            .rpc("is_username_available", params: ["desired_username": username])
            .execute()
            .value

        return available
    }

    func claimUsername(_ rawUsername: String) async throws -> UserProfile {
        guard let username = UsernameValidator.normalize(rawUsername) else {
            throw ProfileError.invalidUsername
        }

        do {
            let profile: UserProfile = try await SupabaseManager.client
                .rpc("claim_username", params: ["desired_username": username])
                .execute()
                .value
            return profile
        } catch {
            if isUsernameTakenError(error) {
                throw ProfileError.usernameTaken
            }
            throw error
        }
    }

    func updateAvatarURL(_ url: URL?) async throws -> UserProfile {
        let profile: UserProfile = try await SupabaseManager.client
            .rpc(
                "update_profile_avatar",
                params: ["new_avatar_url": url?.absoluteString ?? ""]
            )
            .execute()
            .value
        return profile
    }

    func uploadAvatar(userId: UUID, data: Data, contentType: String) async throws -> URL {
        let ext = fileExtension(for: contentType)
        let path = "\(userId.uuidString.lowercased())/avatar.\(ext)"

        try await SupabaseManager.client.storage
            .from("avatars")
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: contentType, upsert: true)
            )

        let publicURL = try SupabaseManager.client.storage
            .from("avatars")
            .getPublicURL(path: path)

        _ = try await updateAvatarURL(publicURL)
        return publicURL
    }

    func deleteAccount() async throws {
        do {
            try await SupabaseManager.client.functions.invoke(
                "delete-account",
                options: FunctionInvokeOptions(method: .post)
            )
        } catch {
            throw ProfileError.deleteFailed(error.localizedDescription)
        }
    }

    private func fileExtension(for contentType: String) -> String {
        switch contentType {
        case "image/png": "png"
        case "image/webp": "webp"
        default: "jpg"
        }
    }

    private func isUsernameTakenError(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("username_taken")
            || message.contains("duplicate key")
            || message.contains("unique constraint")
            || message.contains("23505")
    }
}
