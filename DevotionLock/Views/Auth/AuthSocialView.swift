//
//  AuthSocialView.swift
//  DevotionLock
//

import SwiftUI

struct AuthSocialView: View {
    @State var intent: AuthIntent
    var onBack: () -> Void

    @State private var auth = AuthManager.shared
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var appeared = false
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
        AuthMeshScreen {
            VStack(spacing: 0) {
                AuthCredentialsHeader(intent: intent, onBack: onBack)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        AuthFormCard {
                            formFields

                            if let error = auth.errorMessage {
                                AuthInlineBanner(message: error)
                            }

                            AuthPrimaryCapsuleButton(
                                title: intent == .signUp ? "Create account" : "Log in",
                                isLoading: auth.isLoading,
                                isEnabled: canSubmit
                            ) {
                                submit()
                            }
                        }

                        AuthSwitchIntentLink(intent: intent) {
                            switchIntent()
                        }
                    }
                    .animation(AppTheme.springSnappy, value: intent)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }
                .scrollDismissesKeyboard(.interactively)

                AuthTermsFooter()
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            auth.clearMessages()
            withAnimation(AppTheme.springGentle) { appeared = true }
            focusInitialField()
        }
        .onChange(of: intent) { _, newIntent in
            auth.clearMessages()
            resetUsernameState()
            focusInitialField(for: newIntent)
        }
    }

    // MARK: - Form

    @ViewBuilder
    private var formFields: some View {
        VStack(spacing: 14) {
            if intent == .signUp {
                AuthLabeledField(label: "Username", hint: "Public") {
                    AuthGlassTextField(
                        placeholder: "How should we greet you?",
                        text: $username
                    )
                    .focused($focusedField, equals: .username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
                    .onChange(of: username) { _, _ in
                        scheduleUsernameCheck()
                    }
                }

                if usernameStatus != .idle {
                    AuthFieldStatus(
                        message: usernameStatusMessage,
                        tone: usernameStatusTone
                    )
                }
            }

            AuthLabeledField(label: "Email") {
                AuthGlassTextField(
                    placeholder: "you@example.com",
                    text: $email,
                    keyboardType: .emailAddress
                )
                .focused($focusedField, equals: .email)
                .textContentType(.emailAddress)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
            }

            AuthLabeledField(
                label: "Password",
                hint: intent == .signUp ? "8+ characters" : nil
            ) {
                AuthSecureTextField(
                    placeholder: intent == .signUp ? "Create a password" : "Your password",
                    text: $password
                )
                .focused($focusedField, equals: .password)
                .textContentType(intent == .signUp ? .newPassword : .password)
                .submitLabel(.done)
                .onSubmit { submitIfReady() }
            }

        }
    }

    // MARK: - Validation

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
        case .idle:
            ""
        case .checking:
            "Checking availability…"
        case .available:
            "Username is available."
        case .taken:
            "That username is already taken."
        case .invalid:
            "Use 2–30 characters: letters, numbers, dots, dashes, or underscores."
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

    // MARK: - Actions

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
}

#Preview("Log in") {
    AuthSocialView(intent: .signIn, onBack: {})
}

