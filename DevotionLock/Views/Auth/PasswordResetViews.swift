//
//  PasswordResetViews.swift
//  DevotionLock
//

import SwiftUI

struct PasswordResetRequestView: View {
    @Environment(\.authManager) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var step: Step = .request
    @FocusState private var focused: Bool

    private enum Step {
        case request
        case code
    }

    init(initialEmail: String = "") {
        _email = State(initialValue: initialEmail)
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        AuthScreen(style: .credentials) {
            VStack(spacing: 0) {
                HStack {
                    AuthBackButton(action: goBack)
                    Spacer()
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)

                switch step {
                case .request:
                    requestContent
                case .code:
                    PasswordResetCodeForm(email: email) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            auth.clearMessages()
            focused = true
        }
        .onDisappear {
            auth.clearMessages()
            if !auth.pendingPasswordUpdate {
                auth.clearPasswordResetEmail()
            }
        }
        .onChange(of: auth.pendingPasswordUpdate) { _, pending in
            if pending { dismiss() }
        }
    }

    private var requestContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reset password")
                        .font(ABY.Font.title2)
                        .foregroundStyle(ABY.Color.textPrimary)
                    Text("Enter the email for your account. We will send a 6-digit code you can enter here.")
                        .font(ABY.Font.callout)
                        .foregroundStyle(ABY.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)

                AuthPlainTextField(
                    placeholder: "Email",
                    text: $email,
                    keyboardType: .emailAddress
                )
                .focused($focused)
                .textContentType(.emailAddress)
                .submitLabel(.send)
                .onSubmit { sendIfReady() }

                if let error = auth.errorMessage {
                    AuthInlineBanner(message: error)
                }

                AuthPrimaryCapsuleButton(
                    title: "Send code",
                    isLoading: auth.isLoading,
                    isEnabled: canSubmit
                ) {
                    Task {
                        let sent = await auth.requestPasswordReset(email: email)
                        if sent {
                            withAnimation(AppTheme.springSnappy) {
                                step = .code
                            }
                        }
                    }
                }

                AuthTextLink(title: "Back to sign in") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, ABY.Spacing.screen)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func goBack() {
        if step == .code {
            auth.clearMessages()
            withAnimation(AppTheme.springSnappy) {
                step = .request
            }
        } else {
            dismiss()
        }
    }

    private func sendIfReady() {
        guard canSubmit else { return }
        Task {
            let sent = await auth.requestPasswordReset(email: email)
            if sent {
                withAnimation(AppTheme.springSnappy) {
                    step = .code
                }
            }
        }
    }
}

private struct PasswordResetCodeForm: View {
    @Environment(\.authManager) private var auth

    let email: String
    var onFinished: () -> Void

    @State private var code = ""
    @FocusState private var focused: Bool

    private var canSubmit: Bool {
        code.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter your code")
                        .font(ABY.Font.title2)
                        .foregroundStyle(ABY.Color.textPrimary)
                    Text("We sent a 6-digit code to \(email). Enter it here. Prefer the code over the email link, which some mail apps open too early.")
                        .font(ABY.Font.callout)
                        .foregroundStyle(ABY.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)

                AuthPlainTextField(
                    placeholder: "6-digit code",
                    text: $code,
                    keyboardType: .numberPad
                )
                .focused($focused)
                .textContentType(.oneTimeCode)
                .onChange(of: code) { _, value in
                    let digits = value.filter(\.isNumber)
                    if digits != value {
                        code = String(digits.prefix(8))
                    }
                }

                if let success = auth.successMessage {
                    AuthInlineBanner(message: success, tone: .success)
                }

                if let error = auth.errorMessage {
                    AuthInlineBanner(message: error)
                }

                AuthPrimaryCapsuleButton(
                    title: "Continue",
                    isLoading: auth.isLoading,
                    isEnabled: canSubmit
                ) {
                    Task { await auth.verifyPasswordResetCode(code) }
                }

                AuthTextLink(title: "Resend code") {
                    Task {
                        _ = await auth.requestPasswordReset(email: email)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, ABY.Spacing.screen)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            focused = true
        }
        .onChange(of: auth.pendingPasswordUpdate) { _, pending in
            if pending { onFinished() }
        }
    }
}

struct PasswordUpdateView: View {
    @Environment(\.authManager) private var auth

    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case password
        case confirm
    }

    private var canSubmit: Bool {
        password.count >= 8 && password == confirmPassword
    }

    var body: some View {
        AuthScreen(style: .credentials) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose a new password")
                            .font(ABY.Font.title2)
                            .foregroundStyle(ABY.Color.textPrimary)
                        Text("Use at least 8 characters. You will stay signed in after you save.")
                            .font(ABY.Font.callout)
                            .foregroundStyle(ABY.Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 28)

                    VStack(spacing: 12) {
                        AuthPlainSecureField(placeholder: "New password", text: $password)
                            .focused($focusedField, equals: .password)
                            .textContentType(.newPassword)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .confirm }

                        AuthPlainSecureField(placeholder: "Confirm password", text: $confirmPassword)
                            .focused($focusedField, equals: .confirm)
                            .textContentType(.newPassword)
                            .submitLabel(.done)
                            .onSubmit { saveIfReady() }

                        AuthFieldStatus(
                            message: confirmHint,
                            tone: confirmTone
                        )
                    }

                    if let error = auth.errorMessage {
                        AuthInlineBanner(message: error)
                    }

                    AuthPrimaryCapsuleButton(
                        title: "Save password",
                        isLoading: auth.isLoading,
                        isEnabled: canSubmit
                    ) {
                        Task { await auth.updatePassword(password) }
                    }

                    AuthTextLink(title: "Cancel") {
                        auth.cancelPasswordUpdate()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, ABY.Spacing.screen)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            auth.clearMessages()
            focusedField = .password
        }
    }

    private var confirmHint: String {
        if confirmPassword.isEmpty {
            return "Password must be at least 8 characters."
        }
        if password != confirmPassword {
            return "Passwords do not match yet."
        }
        return "Looks good."
    }

    private var confirmTone: AuthFieldStatus.Tone {
        if confirmPassword.isEmpty { return .neutral }
        if password != confirmPassword { return .error }
        return .success
    }

    private func saveIfReady() {
        guard canSubmit else { return }
        Task { await auth.updatePassword(password) }
    }
}
