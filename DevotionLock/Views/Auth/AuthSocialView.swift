//
//  AuthSocialView.swift
//  DevotionLock
//
//  Fabric-inspired sign-in / sign-up: white surface, social providers, gray fields.
//

import SwiftUI

struct AuthSocialView: View {
    @State var intent: AuthIntent
    var onBack: () -> Void

    @Environment(\.authManager) private var auth
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var usernameStatus: UsernameAvailability = .idle
    @State private var availabilityTask: Task<Void, Never>?
    @FocusState private var focusedField: Field?

    private enum Field {
        case username
        case email
        case password
    }

    private enum UsernameAvailability: Equatable {
        case idle
        case checking
        case available
        case taken
        case invalid
    }

    var body: some View {
        AuthScreen(style: .credentials) {
            VStack(spacing: 0) {
                authNavigationBar

                AuthIntentToggle(intent: $intent)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 4)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        AuthFormHeadline(intent: intent)
                            .padding(.top, 4)

                        credentialFieldsSection

                        if let error = auth.errorMessage {
                            AuthInlineBanner(message: error)
                        }

                        AuthPrimaryCapsuleButton(
                            title: intent == .signUp ? "Sign up" : "Sign in",
                            isLoading: auth.isLoading,
                            isEnabled: canSubmit
                        ) {
                            submit()
                        }
                        .padding(.top, 4)

                        footerLinksSection

                        AuthTermsFooter()
                            .padding(.top, 8)
                            .padding(.bottom, 28)
                    }
                    .animation(AppTheme.springSnappy, value: intent)
                    .padding(.horizontal, ABY.Spacing.screen)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            auth.clearMessages()
            focusInitialField()
        }
        .onChange(of: intent) { _, newIntent in
            auth.clearMessages()
            resetUsernameState()
            focusInitialField(for: newIntent)
        }
    }

    private var authNavigationBar: some View {
        HStack {
            AuthBackButton(action: onBack)
            Spacer()
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var credentialFieldsSection: some View {
        VStack(spacing: 12) {
            if intent == .signUp {
                AuthPlainTextField(placeholder: "Username", text: $username)
                    .focused($focusedField, equals: .username)
                    .textContentType(.username)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
                    .onChange(of: username) { _, _ in scheduleUsernameCheck() }

                if usernameStatus != .idle {
                    AuthFieldStatus(message: usernameStatusMessage, tone: usernameStatusTone)
                }
            }

            AuthPlainTextField(
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress
            )
            .focused($focusedField, equals: .email)
            .textContentType(.emailAddress)
            .submitLabel(.next)
            .onSubmit { focusedField = .password }

            AuthPlainSecureField(placeholder: "Password", text: $password)
                .focused($focusedField, equals: .password)
                .textContentType(intent == .signUp ? .newPassword : .password)
                .submitLabel(.done)
                .onSubmit { submitIfReady() }

            if intent == .signUp {
                AuthFieldStatus(
                    message: "Password must be at least 8 characters.",
                    tone: .neutral
                )
            }
        }
    }

    @ViewBuilder
    private var footerLinksSection: some View {
        VStack(spacing: 16) {
            if intent == .signIn {
                AuthTextLink(title: "Forgot password?") {
                    auth.errorMessage = "Password reset is coming soon — use email sign-in for now."
                }
            }

            AuthSwitchIntentLink(intent: intent) {
                switchIntent()
            }
        }
        .padding(.top, 4)
    }

    private var canSubmit: Bool {
        let hasEmail = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch intent {
        case .signUp:
            guard UsernameValidator.normalize(username) != nil else { return false }
            guard hasEmail, password.count >= 8 else { return false }
            return usernameStatus == .available
        case .signIn:
            return hasEmail && !password.isEmpty
        }
    }

    private var usernameStatusMessage: String {
        switch usernameStatus {
        case .idle: ""
        case .checking: "Checking availability…"
        case .available: "Username is available."
        case .taken: "That username is already taken."
        case .invalid: "Use 2–30 characters: letters, numbers, dots, dashes, or underscores."
        }
    }

    private var usernameStatusTone: AuthFieldStatus.Tone {
        switch usernameStatus {
        case .idle: .neutral
        case .checking: .checking
        case .available: .success
        case .taken, .invalid: .error
        }
    }

    private func switchIntent() {
        withAnimation(AppTheme.springSnappy) {
            intent = intent == .signUp ? .signIn : .signUp
        }
    }

    private func submitIfReady() {
        guard canSubmit, !auth.isLoading else { return }
        submit()
    }

    private func submit() {
        focusedField = nil
        Task {
            if intent == .signUp {
                await auth.signUp(username: username, email: email, password: password)
            } else {
                await auth.signIn(email: email, password: password)
            }
        }
    }

    private func focusInitialField(for targetIntent: AuthIntent? = nil) {
        let mode = targetIntent ?? intent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            focusedField = mode == .signUp ? .username : .email
        }
    }

    private func resetUsernameState() {
        username = ""
        usernameStatus = .idle
        availabilityTask?.cancel()
    }

    private func scheduleUsernameCheck() {
        availabilityTask?.cancel()
        guard intent == .signUp else { return }

        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            usernameStatus = .idle
            return
        }

        guard UsernameValidator.normalize(trimmed) != nil else {
            usernameStatus = .invalid
            return
        }

        usernameStatus = .checking
        availabilityTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            do {
                let available = try await ProfileRepository.shared.isUsernameAvailable(trimmed)
                guard !Task.isCancelled else { return }
                usernameStatus = available ? .available : .taken
            } catch {
                guard !Task.isCancelled else { return }
                usernameStatus = .idle
            }
        }
    }
}

#Preview("Sign up") {
    AuthSocialView(intent: .signUp, onBack: {})
        .environment(\.authManager, AuthManager.shared)
}

#Preview("Log in") {
    AuthSocialView(intent: .signIn, onBack: {})
        .environment(\.authManager, AuthManager.shared)
}
