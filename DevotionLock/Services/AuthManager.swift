//
//  AuthManager.swift
//  DevotionLock
//

import Foundation
import Observation
import Supabase

enum AuthProvider: String, Codable {
    case email
    case apple
    case google
}

enum AuthIntent {
    case signUp
    case signIn
}

@Observable
@MainActor
final class AuthManager {
    static let shared = AuthManager()

    private(set) var isAuthenticated = false
    private(set) var userId: UUID?
    private(set) var email: String?
    private(set) var username: String?
    private(set) var avatarURL: URL?
    private(set) var localAvatarData: Data?

    var provider: AuthProvider? {
        isAuthenticated ? .email : nil
    }

    var displayName: String {
        username ?? "Morning Seeker"
    }

    var isLoading = false
    var errorMessage: String?
    /// False until the first `.initialSession` auth event is handled (session may still be refreshing).
    private(set) var hasResolvedInitialSession = false

    private var authTask: Task<Void, Never>?

    init() {
        authTask = Task { await listenForAuthChanges() }
    }

    func signUp(username rawUsername: String, email rawEmail: String, password: String) async {
        guard let username = UsernameValidator.normalize(rawUsername) else {
            errorMessage = ProfileError.invalidUsername.localizedDescription
            return
        }
        guard let email = normalizedEmail(rawEmail) else {
            errorMessage = "Enter a valid email address."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let available = try await ProfileRepository.shared.isUsernameAvailable(username)
            guard available else {
                errorMessage = ProfileError.usernameTaken.localizedDescription
                return
            }

            let response = try await SupabaseManager.client.auth.signUp(
                email: email,
                password: password,
                data: ["display_name": .string(username)]
            )
            if let session = response.session {
                applySession(session, fallbackUsername: username)
                try await finalizeUsernameClaim(username)
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            } else {
                try await completeSignInAfterSignUp(email: email, password: password, username: username)
            }
        } catch {
            errorMessage = friendlyAuthError(from: error)
        }
    }

    private func completeSignInAfterSignUp(email: String, password: String, username: String) async throws {
        let session = try await SupabaseManager.client.auth.signIn(
            email: email,
            password: password
        )
        applySession(session, fallbackUsername: username)
        try await finalizeUsernameClaim(username)
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }

    func signIn(email rawEmail: String, password: String) async {
        guard let email = normalizedEmail(rawEmail) else {
            errorMessage = "Enter a valid email address."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Enter your password."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await SupabaseManager.client.auth.signIn(
                email: email,
                password: password
            )
            applySession(session)
        } catch {
            errorMessage = friendlyAuthError(from: error)
        }
    }

    func signIn(with provider: AuthProvider, intent: AuthIntent) async {
        switch provider {
        case .email:
            break
        case .apple, .google:
            errorMessage = "Coming soon. Use email sign-in for now."
        }
    }

    func updateUsername(_ rawUsername: String) async throws {
        guard isAuthenticated else { throw ProfileError.notAuthenticated }
        guard let username = UsernameValidator.normalize(rawUsername) else {
            throw ProfileError.invalidUsername
        }

        if username == self.username { return }

        let available = try await ProfileRepository.shared.isUsernameAvailable(username)
        guard available else { throw ProfileError.usernameTaken }

        let profile = try await ProfileRepository.shared.claimUsername(username)
        try await SupabaseManager.client.auth.update(
            user: UserAttributes(data: ["display_name": .string(username)])
        )

        self.username = profile.username ?? username
        if let userId {
            cacheUsername(username, for: userId)
        }
    }

    func updateAvatar(data: Data, contentType: String = "image/jpeg") async throws {
        guard isAuthenticated, let userId else { throw ProfileError.notAuthenticated }

        let processed = AvatarImageProcessor.jpegData(from: data) ?? data
        let url = try await ProfileRepository.shared.uploadAvatar(
            userId: userId,
            data: processed,
            contentType: contentType
        )
        AvatarLocalCache.save(processed, for: userId)
        localAvatarData = processed
        avatarURL = Self.cacheBustedAvatarURL(url)
    }

    func refreshProfileFromServer() async {
        guard let userId else { return }
        await refreshProfile(for: userId)
    }

    private static func cacheBustedAvatarURL(_ url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems = (components?.queryItems ?? []).filter { $0.name != "v" }
        queryItems.append(URLQueryItem(name: "v", value: String(Int(Date().timeIntervalSince1970))))
        components?.queryItems = queryItems
        return components?.url ?? url
    }

    func deleteAccount() async throws {
        guard isAuthenticated else { throw ProfileError.notAuthenticated }

        let deletingUserId = userId
        try await ProfileRepository.shared.deleteAccount()
        if let deletingUserId {
            AvatarLocalCache.remove(for: deletingUserId)
        }
        try? await SupabaseManager.client.auth.signOut()
        clearCachedUsername()
        if let deletingUserId {
            JournalLocalStore.shared.clearAll(for: deletingUserId)
        }
        clearSessionState()
        ConversationRepository.shared.clear()
        AppShieldManager.shared.unlockForCompletedDevotion()
    }

    func signOut() async {
        do {
            try await SupabaseManager.client.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
        clearCachedUsername()
        clearSessionState()
        ConversationRepository.shared.clear()
        AppShieldManager.shared.unlockForCompletedDevotion()
        UserDefaults.standard.set(false, forKey: "hasDismissedPaywall")
        // Onboarding completion is intentionally preserved — signing out and back in
        // should land on auth, not restart onboarding. (Fresh sign-ups still onboard;
        // signUp resets the flag.)
    }

    func clearMessages() {
        errorMessage = nil
    }

    private func listenForAuthChanges() async {
        for await (event, session) in SupabaseManager.client.auth.authStateChanges {
            switch event {
            case .signedOut, .userDeleted:
                hasResolvedInitialSession = true
                clearSessionState()
            case .initialSession:
                hasResolvedInitialSession = true
                if let session, !session.isExpired {
                    applySession(session, clearGuestDemoData: true)
                    SyncCoordinator.shared.scheduleFlush(force: true)
                } else if session == nil {
                    clearSessionState()
                }
            case .signedIn:
                if let session, !session.isExpired {
                    applySession(session, clearGuestDemoData: true)
                    // Full sync only on sign-in — not on tokenRefreshed (avoids redundant pulls).
                    SyncCoordinator.shared.scheduleFlush(force: true)
                }
            case .tokenRefreshed, .passwordRecovery, .userUpdated, .mfaChallengeVerified:
                if let session, !session.isExpired {
                    applySession(session)
                }
            }
        }
    }

    private func clearSessionState() {
        isAuthenticated = false
        userId = nil
        email = nil
        username = nil
        avatarURL = nil
        localAvatarData = nil
        JournalLocalStore.shared.activateAccount(userId: nil)
    }

    private func applySession(_ session: Session, fallbackUsername: String? = nil, clearGuestDemoData: Bool = false) {
        guard !session.isExpired else { return }
        isAuthenticated = true
        userId = session.user.id
        JournalLocalStore.shared.activateAccount(userId: session.user.id)
        email = session.user.email
        username = username(from: session.user) ?? fallbackUsername ?? cachedUsername(for: session.user.id)
        if let username {
            cacheUsername(username, for: session.user.id)
        }
        if clearGuestDemoData {
            DemoDataCleaner.clearIfAuthenticated()
        }
        Task { await refreshProfile(for: session.user.id) }
    }

    private func refreshProfile(for userId: UUID) async {
        do {
            if let profile = try await ProfileRepository.shared.fetchProfile(userId: userId) {
                if let profileUsername = profile.username {
                    username = profileUsername
                    cacheUsername(profileUsername, for: userId)
                }
                avatarURL = profile.avatarURLValue.map(Self.cacheBustedAvatarURL)
                await syncLocalAvatar(for: userId)
                if let voice = profile.chaplainVoiceId, !voice.isEmpty {
                    UserDefaults.standard.set(voice, forKey: "selectedChaplainVoice")
                }
                if let mood = profile.intentionMood, !mood.isEmpty {
                    UserDefaults.standard.set(mood, forKey: "intentionMood")
                }
                if profile.isPremium == true {
                    PaywallAccess.markPurchaseSucceeded()
                }
            } else {
                try await ProfileRepository.shared.ensureProfileExists()
            }
            await UserPreferencesSync.shared.pullAndApply()
        } catch {
            // Profile table may not be migrated yet; auth metadata remains the fallback.
        }
    }

    private func finalizeUsernameClaim(_ username: String) async throws {
        let profile = try await ProfileRepository.shared.claimUsername(username)
        self.username = profile.username ?? username
        if let userId {
            cacheUsername(self.username ?? username, for: userId)
        }
        avatarURL = profile.avatarURLValue.map(Self.cacheBustedAvatarURL)
        if let userId {
            Task { await syncLocalAvatar(for: userId) }
        }
    }

    private func syncLocalAvatar(for userId: UUID) async {
        if let cached = AvatarLocalCache.load(for: userId) {
            localAvatarData = cached
            return
        }

        guard let avatarURL else {
            localAvatarData = nil
            return
        }

        let fetchURL = Self.cacheBustedAvatarURL(avatarURL)
        guard let (data, response) = try? await URLSession.shared.data(from: fetchURL),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              !data.isEmpty else {
            return
        }

        let processed = AvatarImageProcessor.jpegData(from: data) ?? data
        AvatarLocalCache.save(processed, for: userId)
        localAvatarData = processed
    }

    private func username(from user: User) -> String? {
        if let name = user.userMetadata["display_name"]?.stringValue {
            return UsernameValidator.normalize(name)
        }
        if let name = user.userMetadata["username"]?.stringValue {
            return UsernameValidator.normalize(name)
        }
        return nil
    }

    private func cacheUsername(_ name: String, for userId: UUID) {
        UserDefaults.standard.set(name, forKey: usernameCacheKey(for: userId))
    }

    private func cachedUsername(for userId: UUID) -> String? {
        UserDefaults.standard.string(forKey: usernameCacheKey(for: userId))
    }

    private func clearCachedUsername() {
        guard let userId else { return }
        UserDefaults.standard.removeObject(forKey: usernameCacheKey(for: userId))
    }

    private func usernameCacheKey(for userId: UUID) -> String {
        "authUsername_\(userId.uuidString)"
    }

    private func normalizedEmail(_ rawEmail: String) -> String? {
        let trimmed = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.contains("@"), trimmed.contains(".") else { return nil }
        return trimmed
    }

    private func friendlyAuthError(from error: Error) -> String {
        if let profileError = error as? ProfileError {
            return profileError.localizedDescription
        }
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid login credentials") {
            return "Email or password is incorrect."
        }
        if message.contains("user already registered") {
            return "An account with this email already exists. Try signing in."
        }
        if message.contains("email not confirmed") {
            return "Email confirmation is still enabled in Supabase. Turn off Confirm email under Authentication → Providers → Email."
        }
        if message.contains("username_taken") || message.contains("duplicate key") {
            return ProfileError.usernameTaken.localizedDescription
        }
        if message.contains("hostname could not be found")
            || message.contains("could not connect to the server")
            || message.contains("network connection was lost") {
            return "Can't reach the DevotionLock server. Check your internet connection and try again."
        }
        return error.localizedDescription
    }
}
