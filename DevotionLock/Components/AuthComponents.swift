//
//  AuthComponents.swift
//  DevotionLock
//
//  Fabric-inspired auth: white surface, social providers, gray fields, black CTA.
//

import SwiftUI

// MARK: - Screen shell

enum AuthScreenStyle {
    case welcome
    case credentials
}

private struct AuthScreenStyleKey: EnvironmentKey {
    static let defaultValue: AuthScreenStyle = .welcome
}

extension EnvironmentValues {
    var authScreenStyle: AuthScreenStyle {
        get { self[AuthScreenStyleKey.self] }
        set { self[AuthScreenStyleKey.self] = newValue }
    }
}

struct AuthScreen<Content: View>: View {
    let style: AuthScreenStyle
    @ViewBuilder let content: Content

    private var surface: OnboardingSurface {
        switch style {
        case .welcome, .credentials: .light
        }
    }

    var body: some View {
        ZStack {
            ABYWarmSanctuaryBackground()
            ABYJournalScreen(surface: .plain) {
                content
            }
        }
        .environment(\.authScreenStyle, style)
    }
}

// MARK: - Headlines & links

struct AuthFormHeadline: View {
    let intent: AuthIntent

    var body: some View {
        Text(intent == .signUp ? "Sign up" : "Welcome back!")
            .font(ABY.Font.largeTitle)
            .foregroundStyle(ABY.Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

struct AuthIntentToggle: View {
    @Binding var intent: AuthIntent

    var body: some View {
        HStack(spacing: 0) {
            segment(title: "Sign in", isSelected: intent == .signIn) {
                guard intent != .signIn else { return }
                withAnimation(AppTheme.springSnappy) { intent = .signIn }
            }
            segment(title: "Sign up", isSelected: intent == .signUp) {
                guard intent != .signUp else { return }
                withAnimation(AppTheme.springSnappy) { intent = .signUp }
            }
        }
        .padding(4)
        .background(ABY.Color.fieldFill)
        .clipShape(Capsule())
        .accessibilityElement(children: .contain)
    }

    private func segment(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(ABY.Font.footnoteSemibold)
                .foregroundStyle(isSelected ? ABY.Color.textPrimary : ABY.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(ABY.Color.surface)
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct AuthSecondaryTextLink: View {
    let prompt: String
    let actionLabel: String
    let action: () -> Void
    @Environment(\.authScreenStyle) private var screenStyle

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(prompt)
                    .foregroundStyle(promptColor)
                Text(actionLabel)
                    .font(ABY.Font.footnoteSemibold)
                    .underline(screenStyle == .credentials)
                    .foregroundStyle(linkColor)
            }
            .font(ABY.Font.footnote)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var promptColor: Color {
        screenStyle == .welcome ? ABY.Color.textSecondary : ABY.Color.textSecondary
    }

    private var linkColor: Color {
        screenStyle == .welcome ? ABY.Color.textPrimary : ABY.Color.linkBlue
    }
}

struct AuthSwitchIntentLink: View {
    let intent: AuthIntent
    let switchIntent: () -> Void

    var body: some View {
        AuthSecondaryTextLink(
            prompt: prompt,
            actionLabel: actionLabel,
            action: switchIntent
        )
    }

    private var prompt: String {
        intent == .signUp ? "Already have an account?" : "No account?"
    }

    private var actionLabel: String {
        intent == .signUp ? "Sign in" : "Sign up"
    }
}

struct AuthTextLink: View {
    let title: String
    var alignment: Alignment = .leading
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ABY.Font.footnote)
                .foregroundStyle(ABY.Color.linkBlue)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: alignment)
    }
}

struct AuthOrSeparator: View {
    var body: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(ABY.Color.divider)
                .frame(height: 1)
            Text("or")
                .font(ABY.Font.footnote)
                .foregroundStyle(ABY.Color.textTertiary)
            Rectangle()
                .fill(ABY.Color.divider)
                .frame(height: 1)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Social providers

struct AuthSocialProviderButton: View {
    enum Provider {
        case apple
        case google

        var title: String {
            switch self {
            case .apple: "Sign in with Apple"
            case .google: "Sign in with Google"
            }
        }

        func title(for intent: AuthIntent) -> String {
            switch (self, intent) {
            case (.apple, .signUp): "Sign up with Apple"
            case (.apple, .signIn): "Sign in with Apple"
            case (.google, .signUp): "Sign up with Google"
            case (.google, .signIn): "Sign in with Google"
            }
        }
    }

    let provider: Provider
    let intent: AuthIntent
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                providerIcon
                Text(provider.title(for: intent))
                    .font(ABY.Font.body)
                    .foregroundStyle(ABY.Color.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ABY.Color.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(ABY.Color.divider, lineWidth: 1)
                    }
            }
            .opacity(isLoading ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    @ViewBuilder
    private var providerIcon: some View {
        switch provider {
        case .apple:
            Image(systemName: "apple.logo")
                .font(ABY.Font.headline)
                .foregroundStyle(.black)
                .frame(width: 22)
        case .google:
            Text("G")
                .font(ABY.Font.headline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.92, green: 0.26, blue: 0.21),
                            Color(red: 0.98, green: 0.74, blue: 0.18),
                            Color(red: 0.20, green: 0.66, blue: 0.33),
                            Color(red: 0.26, green: 0.52, blue: 0.96),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22)
        }
    }
}

// MARK: - Fields

struct AuthFieldStatus: View {
    enum Tone {
        case neutral
        case checking
        case success
        case error

        var color: Color {
            switch self {
            case .neutral, .checking: ABY.Color.textTertiary
            case .success: Color.green.opacity(0.85)
            case .error: Color.red.opacity(0.88)
            }
        }

        var icon: String? {
            switch self {
            case .neutral, .checking: nil
            case .success: "checkmark.circle.fill"
            case .error: "exclamationmark.circle.fill"
            }
        }
    }

    let message: String
    let tone: Tone

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if tone == .checking {
                ProgressView()
                    .scaleEffect(0.75)
                    .tint(tone.color)
                    .padding(.top, 1)
            } else if let icon = tone.icon {
                Image(systemName: icon)
                    .font(ABY.Font.captionSemibold)
                    .foregroundStyle(tone.color)
                    .padding(.top, 1)
            }

            Text(message)
                .font(ABY.Font.caption)
                .foregroundStyle(tone.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

struct AuthInlineBanner: View {
    let message: String

    private let tint = Color(red: 0.82, green: 0.18, blue: 0.16)

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(ABY.Font.bodySemibold)
                .foregroundStyle(tint)
            Text(message)
                .font(ABY.Font.footnote)
                .foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(tint.opacity(0.20), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

struct AuthPlainTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $text, prompt: prompt)
            .textInputAutocapitalization(.never)
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .font(ABY.Font.body)
            .foregroundStyle(ABY.Color.textPrimary)
            .focused($isFocused)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(AuthFieldBackground(isFocused: isFocused))
    }

    private var prompt: Text {
        Text(placeholder)
            .font(ABY.Font.body)
            .foregroundStyle(ABY.Color.textTertiary)
    }
}

struct AuthPlainSecureField: View {
    let placeholder: String
    @Binding var text: String

    @State private var isVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isVisible {
                    TextField("", text: $text, prompt: prompt)
                } else {
                    SecureField("", text: $text, prompt: prompt)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(ABY.Font.body)
            .foregroundStyle(ABY.Color.textPrimary)
            .focused($isFocused)

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(ABY.Font.bodyMedium)
                    .foregroundStyle(ABY.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AuthFieldBackground(isFocused: isFocused))
    }

    private var prompt: Text {
        Text(placeholder)
            .font(ABY.Font.body)
            .foregroundStyle(ABY.Color.textTertiary)
    }
}

// Legacy icon fields — kept for welcome / other flows
struct AuthIconTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        AuthPlainTextField(placeholder: placeholder, text: $text, keyboardType: keyboardType)
    }
}

struct AuthIconSecureField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        AuthPlainSecureField(placeholder: placeholder, text: $text)
    }
}

private struct AuthFieldBackground: View {
    var isFocused = false

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(ABY.Color.fieldFill)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isFocused ? ABY.Color.linkBlue.opacity(0.45) : Color.clear,
                        lineWidth: 1.5
                    )
            }
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Buttons

struct AuthPrimaryCapsuleButton: View {
    let title: String
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(ABY.Font.button)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(Color.black.opacity(isEnabled && !isLoading ? 1 : 0.45))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isEnabled && !isLoading ? 0.08 : 0), radius: 12, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(title)
    }
}

struct AuthTermsFooter: View {
    @Environment(\.authScreenStyle) private var screenStyle
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        VStack(spacing: 4) {
            Text(footerLine)
                .font(ABY.Font.caption)
                .foregroundStyle(ABY.Color.textTertiary)
                .multilineTextAlignment(.center)

            if screenStyle == .credentials {
                HStack(spacing: 4) {
                    Button("Terms") { showTerms = true }
                        .font(ABY.Font.captionMedium)
                        .underline()
                    Text("and")
                    Button("Privacy Policy") { showPrivacy = true }
                        .font(ABY.Font.captionMedium)
                        .underline()
                }
                .font(ABY.Font.caption)
                .foregroundStyle(ABY.Color.textTertiary)
            }
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack { LegalDocumentView(document: .termsOfService) }
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack { LegalDocumentView(document: .privacyPolicy) }
        }
    }

    private var footerLine: String {
        screenStyle == .welcome
            ? "By tapping 'Get started', you're accepting our terms and privacy policy."
            : "By continuing, you agree to our"
    }
}

struct AuthBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(ABY.Font.iconMedium)
                .foregroundStyle(ABY.Color.textPrimary)
                .frame(width: 40, height: 40)
                .background(ABY.Color.track, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}
