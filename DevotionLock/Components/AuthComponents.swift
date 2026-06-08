//
//  AuthComponents.swift
//  DevotionLock
//

import SwiftUI

// MARK: - Screen shell

struct AuthMeshScreen<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            ABYOnboardingMeshBackground()
            AuthAmbientOrbs()
            content
        }
        .preferredColorScheme(.dark)
    }
}

struct AuthAmbientOrbs: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 2)
                .offset(x: drift ? -90 : -110, y: drift ? -280 : -300)

            Circle()
                .fill(ABY.Color.meshSage.opacity(0.22))
                .frame(width: 160, height: 160)
                .blur(radius: 1)
                .offset(x: drift ? 120 : 140, y: drift ? -180 : -200)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 4)
                .offset(x: drift ? 40 : 20, y: drift ? 320 : 340)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

// MARK: - Welcome

struct AuthSunriseHero: View {
    @State private var glow = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.05), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 90
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(glow ? 1.05 : 0.95)

            Circle()
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                .frame(width: 96, height: 96)

            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.95))
                .offset(y: 6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

struct AuthBottomPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 14) {
            content
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 20)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                .fill(Color.white.opacity(0.12))
                .background {
                    UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                        .fill(.ultraThinMaterial)
                        .opacity(0.65)
                }
                .overlay {
                    UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                        .strokeBorder(Color.white.opacity(0.24), lineWidth: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Credentials layout

struct AuthCredentialsHeader: View {
    let intent: AuthIntent
    let onBack: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            AuthBackButton(action: onBack)

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                Text(intent == .signUp ? "Create account" : "Log in")
                    .font(ABY.Font.title2)
                    .foregroundStyle(ABY.Color.onboardingText)
                Text(intent == .signUp ? "Join your morning sanctuary" : "Welcome back")
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.onboardingTextSecondary)
            }

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

struct AuthFormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.55)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                }
        }
    }
}

struct AuthSecondaryTextLink: View {
    let prompt: String
    let actionLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(prompt)
                    .foregroundStyle(ABY.Color.onboardingTextSecondary)
                Text(actionLabel)
                    .fontWeight(.semibold)
                    .foregroundStyle(ABY.Color.onboardingText)
            }
            .font(ABY.Font.footnote)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
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
        intent == .signUp ? "Already have an account?" : "New to Devotion Lock?"
    }

    private var actionLabel: String {
        intent == .signUp ? "Log in" : "Create account"
    }
}

// MARK: - Fields

struct AuthLabeledField<Content: View>: View {
    let label: String
    var hint: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.onboardingTextSecondary)
                Spacer(minLength: 8)
                if let hint {
                    Text(hint)
                        .font(ABY.Font.caption)
                        .foregroundStyle(ABY.Color.onboardingTextMuted)
                }
            }
            content
        }
    }
}

struct AuthFieldStatus: View {
    enum Tone {
        case neutral
        case checking
        case success
        case error

        var color: Color {
            switch self {
            case .neutral, .checking: ABY.Color.onboardingTextMuted
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
                    .tint(ABY.Color.onboardingTextMuted)
                    .padding(.top, 1)
            } else if let icon = tone.icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tone.color)
                    .padding(.top, 1)
            }

            Text(message)
                .font(ABY.Font.caption)
                .foregroundStyle(tone.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AuthInlineBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.red.opacity(0.9))
            Text(message)
                .font(ABY.Font.footnote)
                .foregroundStyle(Color.red.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.red.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.22), lineWidth: 1)
                }
        }
    }
}

struct AuthGlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var alignment: TextAlignment = .leading

    var body: some View {
        TextField(placeholder, text: $text)
            .textInputAutocapitalization(autocapitalization)
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .multilineTextAlignment(alignment)
            .font(ABY.Font.body)
            .foregroundStyle(ABY.Color.onboardingText)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(AuthFieldBackground())
    }
}

private struct AuthFieldBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: ABY.Radius.glass, style: .continuous)
            .fill(Color.black.opacity(0.14))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.glass, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
            }
    }
}

struct AuthSecureTextField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(ABY.Font.body)
            .foregroundStyle(ABY.Color.onboardingText)

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ABY.Color.onboardingTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(AuthFieldBackground())
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
                        .tint(ABY.Color.onboardingButtonText)
                }
                Text(title)
                    .font(ABY.Font.button)
            }
            .foregroundStyle(ABY.Color.onboardingButtonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white.opacity(isEnabled ? 1 : 0.55))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isEnabled ? 0.08 : 0), radius: 12, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
    }
}

struct AuthTermsFooter: View {
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        VStack(spacing: 4) {
            Text("By continuing, you agree to our")
                .font(ABY.Font.caption)
                .foregroundStyle(ABY.Color.onboardingTextMuted)
            HStack(spacing: 4) {
                Button("Terms") { showTerms = true }
                    .font(ABY.Font.caption.weight(.medium))
                    .underline()
                    .foregroundStyle(ABY.Color.onboardingTextMuted)
                Text("and")
                    .font(ABY.Font.caption)
                    .foregroundStyle(ABY.Color.onboardingTextMuted)
                Button("Privacy Policy") { showPrivacy = true }
                    .font(ABY.Font.caption.weight(.medium))
                    .underline()
                    .foregroundStyle(ABY.Color.onboardingTextMuted)
            }
        }
        .multilineTextAlignment(.center)
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                LegalDocumentView(document: .termsOfService)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack {
                LegalDocumentView(document: .privacyPolicy)
            }
        }
    }
}

struct AuthBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(ABY.Font.iconMedium)
                .foregroundStyle(ABY.Color.onboardingText)
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}
