//
//  ABYChatComponents.swift
//  DevotionLock
//
//  Mobbin refs:
//  - ABY chat: https://mobbin.com/screens/f1a56ab6-6c52-46e7-9f6d-66fb287b00b0
//  - Gemini empty: https://mobbin.com/screens/8cb0be56-3634-46eb-bc04-7fd121164726
//  - Gemini chips: https://mobbin.com/screens/7097fe26-5a50-4577-a64e-e47ffcf9097f
//

import SwiftUI
import UIKit

// MARK: - Mascot

struct ABYChaplainAvatar: View {
    var size: CGFloat = 44

    var body: some View {
        DevotionLockBrandMark(size: size, showsShadow: size >= 40)
    }
}

// MARK: - Hub hero

struct ABYChaplainHubHero: View {
    @Environment(\.sanctuaryPalette) private var palette
    let voice: ChaplainVoice
    var streak: Int = 0
    var onStartChat: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ABYChaplainAvatar(size: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("Chaplain \(voice.name)")
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Text(voice.personality)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
                if streak > 0 {
                    Text("\(streak) day streak")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }
            }

            Spacer(minLength: 0)

            Button(action: onStartChat) {
                Image(systemName: "ellipsis.bubble.fill")
                    .font(ABY.Font.bodySemibold)
                    .foregroundStyle(palette.buttonForeground)
                    .frame(width: 44, height: 44)
                    .background(palette.buttonFill)
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Start a conversation")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
    }
}

struct ABYChaplainIdentityBubble: View {
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        Text("A companion for reflection, not clinical care.")
            .font(ABY.Font.caption)
            .foregroundStyle(palette.textTertiary)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }
}

struct ABYChatEmptyState: View {
    @Environment(\.sanctuaryPalette) private var palette
    let voiceName: String
    let greeting: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ABYChaplainAvatar(size: 36)
                Text("Chaplain \(voiceName)")
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(palette.textPrimary)
            }

            Text(greeting)
                .font(ABY.Font.editorialCallout)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            ABYChaplainIdentityBubble()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

// MARK: - Gemini-style chat (Mobbin Google Gemini)

struct GeminiChatGreeting: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.authManager) private var auth

    private var firstName: String {
        let name = auth.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "friend" }
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hi \(firstName)")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
            Text("Where should we start?")
                .font(ABY.Font.editorialTitle)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
}

struct GeminiChatSuggestionRail: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChaplainStarterPrompt.geminiChips) { chip in
                    Button {
                        onSelect(chip.prompt)
                    } label: {
                        HStack(spacing: 6) {
                            Text(chip.emoji)
                                .font(ABY.Font.callout)
                            Text(chip.prompt)
                                .font(ABY.Font.footnote)
                                .foregroundStyle(palette.textPrimary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(palette.surface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
        }
        .scrollClipDisabled()
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }
}

/// Legacy wrapper — greeting only; chips live in `GeminiChatSuggestionRail`.
// MARK: - Chat canvas (Mobbin Gemini — flat wash, no edge bands)

/// Flat off-white canvas — matches [Gemini chat](https://mobbin.com/screens/8cb0be56-3634-46eb-bc04-7fd121164726).
struct ABYChatWashBackground: View {
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue

    private var mode: SanctuaryGradientMode {
        SanctuaryGradientMode.resolved(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    var body: some View {
        Group {
            switch mode {
            case .light:
                ABY.Color.tabWashTop
            case .night:
                ABYNightSanctuaryBackground()
            }
        }
        .ignoresSafeArea()
    }
}

struct GeminiChatEmptyState: View {
    var onSelectChip: (String) -> Void

    var body: some View {
        GeminiChatGreeting()
    }
}

struct GeminiChatInputBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var text: String
    var placeholder: String = "Ask Chaplain"
    var onSend: () -> Void
    var onVoice: (() -> Void)? = nil
    var floatingStyle: Bool = false
    var isBusy: Bool = false
    var enablesDictation: Bool = true
    var focused: FocusState<Bool>.Binding

    @State private var transcription = SpeechTranscriptionService()
    @State private var isDictating = false
    @State private var dictationBase = ""
    @State private var showMicPermissionAlert = false

    private var canSend: Bool {
        !isBusy && !isDictating && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var resolvedPlaceholder: String {
        if isDictating { return "Listening…" }
        if isBusy { return "Chaplain is responding…" }
        return placeholder
    }

    private var showsCenteredPlaceholder: Bool {
        text.isEmpty && !focused.wrappedValue && !isDictating
    }

    var body: some View {
        Group {
            if isDictating {
                dictationRow
            } else {
                composeRow
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .opacity(isBusy ? 0.78 : 1)
        .animation(AppTheme.springSnappy, value: isDictating)
        .animation(.easeOut(duration: 0.22), value: isBusy)
        .background { inputChrome }
        .onChange(of: transcription.transcript) { _, spoken in
            guard isDictating else { return }
            text = Self.mergedDictation(base: dictationBase, spoken: spoken)
        }
        .onDisappear {
            if isDictating {
                cancelDictation(silent: true)
            }
        }
        .alert("Microphone access needed", isPresented: $showMicPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Allow microphone and speech recognition in Settings to speak to your Chaplain.")
        }
    }

    private var composeRow: some View {
        HStack(alignment: showsCenteredPlaceholder ? .center : .bottom, spacing: 8) {
            if enablesDictation, !isBusy {
                speechMicButton
            }

            ZStack(alignment: showsCenteredPlaceholder ? .center : .topLeading) {
                if showsCenteredPlaceholder {
                    Text(resolvedPlaceholder)
                        .font(ABY.Font.body)
                        .foregroundStyle(palette.textTertiary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .allowsHitTesting(false)
                }

                TextField("", text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(text.isEmpty ? .center : .leading)
                    .focused(focused)
                    .submitLabel(.return)
                    .padding(.vertical, 2)
                    .disabled(isBusy)
            }
            .frame(minHeight: 32)

            Button(action: onSend) {
                Group {
                    if isBusy {
                        Image(systemName: "ellipsis")
                            .symbolEffect(.pulse, options: .repeating)
                    } else {
                        Image(systemName: "arrow.up")
                    }
                }
                .font(ABY.Font.captionSemibold)
                .foregroundStyle(canSend ? palette.buttonForeground : palette.textTertiary)
                .frame(width: 32, height: 32)
                .background(canSend ? palette.buttonFill : palette.surfaceMuted.opacity(0.6))
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel(isBusy ? "Chaplain is responding" : "Send message")
        }
    }

    private var dictationRow: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: { cancelDictation() }) {
                Image(systemName: "xmark")
                    .font(ABY.Font.footnoteSemibold)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(palette.surfaceMuted.opacity(0.55))
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Cancel dictation")

            HStack(spacing: 10) {
                VoiceWaveformIcon(active: transcription.isListening)
                    .frame(width: 28, height: 28)

                Text(text.isEmpty ? resolvedPlaceholder : text)
                    .font(ABY.Font.body)
                    .foregroundStyle(text.isEmpty ? palette.textTertiary : palette.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(AppTheme.springGentle, value: text)
            }

            Button(action: finishDictation) {
                Image(systemName: "arrow.up")
                    .font(ABY.Font.captionSemibold)
                    .foregroundStyle(palette.buttonForeground)
                    .frame(width: 32, height: 32)
                    .background(palette.buttonFill)
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Done dictating")
        }
    }

    private var speechMicButton: some View {
        Button(action: { Task { await startDictation() } }) {
            Image(systemName: "mic.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 32, height: 32)
                .background(palette.surfaceMuted.opacity(0.45))
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Speak to type")
    }

    @ViewBuilder
    private var inputChrome: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        if floatingStyle {
            shape
                .fill(Color.white)
                .overlay {
                    shape.stroke(
                        isDictating ? ABY.Color.pillTeal.opacity(0.45) : palette.divider.opacity(0.35),
                        lineWidth: isDictating ? 1.5 : 1
                    )
                }
                .shadow(color: .black.opacity(isDictating ? 0.09 : 0.07), radius: isDictating ? 18 : 16, y: 6)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        } else {
            ABYGlassBarBackground(cornerRadius: 22)
        }
    }

    @MainActor
    private func startDictation() async {
        guard !isBusy, !isDictating else { return }
        DevotionHaptics.light()
        dictationBase = text
        focused.wrappedValue = false

        let authorized = await transcription.requestAuthorization()
        guard authorized else {
            showMicPermissionAlert = true
            DevotionHaptics.medium()
            return
        }

        do {
            try transcription.start()
            withAnimation(AppTheme.springSnappy) {
                isDictating = true
            }
            DevotionHaptics.medium()
        } catch {
            showMicPermissionAlert = true
            DevotionHaptics.medium()
        }
    }

    private func finishDictation() {
        let spoken = transcription.stop().trimmingCharacters(in: .whitespacesAndNewlines)
        text = Self.mergedDictation(base: dictationBase, spoken: spoken)
        isDictating = false
        dictationBase = ""
        DevotionHaptics.success()
    }

    private func cancelDictation(silent: Bool = false) {
        _ = transcription.stop()
        text = dictationBase
        isDictating = false
        dictationBase = ""
        if !silent {
            DevotionHaptics.light()
        }
    }

    private static func mergedDictation(base: String, spoken: String) -> String {
        let trimmedSpoken = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSpoken.isEmpty else { return base }
        if base.isEmpty { return trimmedSpoken }
        if base.hasSuffix(" ") { return base + trimmedSpoken }
        return base + " " + trimmedSpoken
    }
}

// MARK: - Compose launcher & overlay (Mobbin Pi / Claude / Copilot refs)

/// Floating pill on the hub — tap to summon the compose card.
struct ChaplainComposeLauncher: View {
    @Environment(\.sanctuaryPalette) private var palette
    let voiceName: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            DevotionHaptics.soft()
            action()
        } label: {
            HStack(spacing: 12) {
                ABYChaplainAvatar(size: 30)
                Text("Message Chaplain \(voiceName)…")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.circle.fill")
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.buttonFill)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color.white.opacity(0.96))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isPressed ? 0.04 : 0.07), radius: isPressed ? 10 : 16, y: isPressed ? 3 : 6)
            .scaleEffect(isPressed ? 0.97 : 1)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AppTheme.springSnappy) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(AppTheme.springSnappy) { isPressed = false }
                }
        )
        .accessibilityLabel("Message Chaplain \(voiceName)")
    }
}

/// Brief sanctuary bloom — compose pill dissolves into Chaplain chat.
struct ChaplainPortalTransition: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let voiceName: String
    let onComplete: () -> Void

    @State private var washVisible = false
    @State private var bloomScale: CGFloat = 0.2
    @State private var bloomOpacity = 0.0
    @State private var avatarRevealed = false
    @State private var avatarLift: CGFloat = 120
    @State private var fieldIntensity: CGFloat = 0
    @State private var ringPulse = false
    @State private var departing = false

    var body: some View {
        GeometryReader { geometry in
            let anchorY = geometry.size.height - geometry.safeAreaInsets.bottom - 118

            ZStack {
                ABY.Color.tabWashTop
                    .opacity(washVisible ? 1 : 0)
                    .ignoresSafeArea()

                SoftLightFieldView(intensity: fieldIntensity)
                    .ignoresSafeArea()
                    .opacity(departing ? 0 : 1)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ABY.Color.orbTeal.opacity(0.42),
                                    ABY.Color.pillPurple.opacity(0.22),
                                    .clear,
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 160
                            )
                        )
                        .frame(width: 280, height: 280)
                        .blur(radius: 28)
                        .scaleEffect(bloomScale)
                        .opacity(bloomOpacity)

                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    ABY.Color.orbTeal.opacity(0.7),
                                    ABY.Color.orbSage.opacity(0.35),
                                    ABY.Color.pillPurple.opacity(0.55),
                                    ABY.Color.orbTeal.opacity(0.7),
                                ],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: ringPulse ? 118 : 92, height: ringPulse ? 118 : 92)
                        .opacity(avatarRevealed ? 0.55 : 0)
                        .blur(radius: 0.5)
                }
                .position(x: geometry.size.width / 2, y: anchorY)

                VStack(spacing: 14) {
                    ABYChaplainAvatar(size: 64)
                        .blurReveal(avatarRevealed, blurRadius: 14, scale: 1.1)

                    VStack(spacing: 4) {
                        Text("Chaplain \(voiceName)")
                            .font(ABY.Font.calloutSemibold)
                            .foregroundStyle(ABY.Color.textPrimary)
                        Text("A quiet place to begin")
                            .font(ABY.Font.caption)
                            .foregroundStyle(ABY.Color.textSecondary)
                    }
                    .blurReveal(avatarRevealed, blurRadius: 8, scale: 1.02)
                }
                .offset(y: avatarLift)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(!departing)
        .onAppear(perform: runPortal)
    }

    private func runPortal() {
        if reduceMotion {
            onComplete()
            return
        }

        withAnimation(.easeOut(duration: 0.42)) {
            washVisible = true
            bloomScale = 1.35
            bloomOpacity = 0.95
            fieldIntensity = 0.85
        }

        withAnimation(AppTheme.springGentle.delay(0.06)) {
            avatarRevealed = true
            avatarLift = -24
        }

        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.2)) {
            ringPulse = true
        }

        Task {
            try? await Task.sleep(for: .milliseconds(520))
            await MainActor.run {
                DevotionHaptics.light()
                withAnimation(.easeIn(duration: 0.22)) {
                    departing = true
                    bloomOpacity = 0
                    fieldIntensity = 0
                }
            }
            try? await Task.sleep(for: .milliseconds(180))
            await MainActor.run {
                onComplete()
            }
        }
    }
}

/// Rising compose card — Copilot / Meta AI style overlay before full chat.
struct ChaplainComposeOverlay: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var isPresented: Bool
    @Binding var draft: String
    let voice: ChaplainVoice
    let suggestions: [String]
    var onSend: (String) -> Void

    @State private var cardVisible = false
    @State private var isDictating = false
    @State private var keyboardOverlap: CGFloat = 0
    @FocusState private var focused: Bool

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(Color.black.opacity(cardVisible ? 0.22 : 0))
                    .ignoresSafeArea()
                    .onTapGesture { dismissOverlay() }

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    composeCard
                        .padding(.horizontal, 10)
                        .offset(y: cardVisible ? 0 : geometry.size.height * 0.5)
                        .opacity(cardVisible ? 1 : 0.7)
                }
                .padding(.bottom, keyboardBottomPadding(in: geometry))
            }
        }
        .ignoresSafeArea()
        .animation(AppTheme.springGentle, value: cardVisible)
        .animation(.easeOut(duration: 0.25), value: keyboardOverlap)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            updateKeyboardOverlap(from: note)
        }
        .onAppear(perform: presentOverlay)
    }

    private func keyboardBottomPadding(in geometry: GeometryProxy) -> CGFloat {
        guard keyboardOverlap > 0 else { return geometry.safeAreaInsets.bottom + 8 }
        return max(8, keyboardOverlap - geometry.safeAreaInsets.bottom)
    }

    private func updateKeyboardOverlap(from note: Notification) {
        guard
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
        else { return }

        let overlap = max(0, window.bounds.height - frame.origin.y)
        let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        withAnimation(.easeOut(duration: duration)) {
            keyboardOverlap = overlap
        }
    }

    private var composeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(palette.divider)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            HStack(spacing: 12) {
                ABYChaplainAvatar(size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Chaplain \(voice.name)")
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textPrimary)
                    Text(voice.personality)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer(minLength: 0)
                Button(action: dismissOverlay) {
                    Image(systemName: "xmark")
                        .font(ABY.Font.captionSemibold)
                        .foregroundStyle(palette.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(palette.surfaceMuted.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Text("What's on your heart?")
                .font(ABY.Font.editorialHeadline)
                .foregroundStyle(ABY.Color.moodPeachText)
                .lineSpacing(4)

            if isDictating {
                ABYInlineDictationCapture(text: $draft, isActive: $isDictating)
            } else {
                TextField("Share what's on your mind", text: $draft, axis: .vertical)
                    .lineLimit(2...6)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textPrimary)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit { submitIfPossible() }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { prompt in
                            Button {
                                draft = prompt
                                focused = true
                            } label: {
                                Text(prompt)
                                    .font(ABY.Font.captionMedium)
                                    .foregroundStyle(palette.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(palette.surfaceMuted.opacity(0.5))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        focused = false
                        withAnimation(AppTheme.springGentle) { isDictating = true }
                    } label: {
                        Image(systemName: "mic")
                            .font(ABY.Font.bodyMedium)
                            .foregroundStyle(palette.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(palette.surfaceMuted.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Speak instead")

                    Spacer(minLength: 0)

                    Button(action: submitIfPossible) {
                        HStack(spacing: 6) {
                            Text("Continue")
                                .font(ABY.Font.calloutSemibold)
                            Image(systemName: "arrow.right")
                                .font(ABY.Font.captionSemibold)
                        }
                        .foregroundStyle(canSend ? palette.buttonForeground : palette.textTertiary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(canSend ? palette.buttonFill : palette.surfaceMuted)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!canSend)
                }
            }

            Text("AI may be imperfect · not pastoral or clinical care")
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textTertiary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.bottom, 20)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 28, y: -4)
        }
    }

    private func presentOverlay() {
        withAnimation(AppTheme.springGentle) { cardVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            if !isDictating { focused = true }
        }
    }

    private func dismissOverlay() {
        focused = false
        withAnimation(AppTheme.springSnappy) { cardVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            isPresented = false
            isDictating = false
        }
    }

    private func submitIfPossible() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        focused = false
        withAnimation(AppTheme.springSnappy) { cardVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            isPresented = false
            isDictating = false
            onSend(trimmed)
            draft = ""
        }
    }
}

// MARK: - Suggestions

struct ABYChatSuggestionSection: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    let prompts: [String]
    var onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(prompts, id: \.self) { prompt in
                        Button {
                            onSelect(prompt)
                        } label: {
                            Text(prompt)
                                .font(ABY.Font.captionMedium)
                                .foregroundStyle(palette.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.92))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(palette.divider.opacity(0.8), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Chat bubbles (Gemini-style thread)

struct ABYChaplainMessageCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let text: String
    var timestamp: String? = nil
    var useSerifStyle: Bool = false
    var isRevealed: Bool = true
    var isStreaming: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ABYChaplainAvatar(size: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text(displayText)
                        .font(useSerifStyle ? ABY.Font.editorialCallout : ABY.Font.body)
                        .foregroundStyle(palette.textPrimary)
                        .lineSpacing(5)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.easeOut(duration: 0.12), value: text.count)

                    if isStreaming {
                        ChaplainStreamCursor()
                    }
                }

                if let timestamp, !isStreaming {
                    Text(timestamp)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .blurReveal(isRevealed, blurRadius: 6, scale: 1.004)
    }

    private var displayText: String {
        if text.isEmpty, isStreaming { return " " }
        return text
    }
}

struct ABYUserMessageBubble: View {
    @Environment(\.sanctuaryPalette) private var palette
    let text: String

    var body: some View {
        HStack {
            Spacer(minLength: 52)
            Text(text)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(ABY.Color.moodPeach.opacity(0.58))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(ABY.Color.moodPeach.opacity(0.35), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
                }
        }
    }
}

// MARK: - Composer (text-only, ABY pill)

struct ABYChatComposerBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var text: String
    var placeholder: String = "Say something to your Chaplain…"
    var onSend: () -> Void
    var enablesDictation: Bool = true
    @FocusState private var focused: Bool
    @State private var isDictating = false

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 10) {
            if isDictating {
                ABYInlineDictationCapture(text: $text, isActive: $isDictating)
            } else {
                composerField
            }
        }
    }

    private var composerField: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(1...4)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .focused($focused)
                .submitLabel(.send)
                .onSubmit { if canSend { onSend() } }

            if enablesDictation {
                Button {
                    focused = false
                    isDictating = true
                } label: {
                    VoiceWaveformIcon(active: false)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Speak to type")
            }

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(ABY.Font.captionSemibold)
                    .foregroundStyle(canSend ? .white : palette.textTertiary)
                    .frame(width: 30, height: 30)
                    .background(canSend ? palette.buttonFill : palette.surfaceMuted)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            ABYGlassBarBackground()
        }
    }
}

struct ABYChatDisclaimer: View {
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        Text("AI can miss the mark. This isn't pastoral or clinical care.")
            .font(ABY.Font.caption)
            .foregroundStyle(palette.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }
}

struct ABYChatScreenHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let voiceName: String
    var threadTitle: String? = nil
    var onClose: () -> Void
    var onHistory: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil
    var onClear: (() -> Void)? = nil
    var saveDisabled: Bool = false
    var geminiStyle: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Image(systemName: geminiStyle ? "chevron.down" : "chevron.down")
                    .font(ABY.Font.bodySemibold)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)

            Spacer(minLength: 0)

            if geminiStyle {
                if let threadTitle, !threadTitle.isEmpty {
                    VStack(spacing: 2) {
                        Text(threadTitle)
                            .font(ABY.Font.calloutSemibold)
                            .foregroundStyle(palette.textPrimary)
                            .lineLimit(1)
                        Text("Chaplain")
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textTertiary)
                    }
                } else {
                    Text("Chaplain")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                }
            } else {
                HStack(spacing: 6) {
                    ABYChaplainAvatar(size: 24)
                    Text("Chaplain \(voiceName)")
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textPrimary)
                }
            }

            Spacer(minLength: 0)

            if geminiStyle {
                if let onHistory {
                    compactIconButton("clock.arrow.circlepath", action: onHistory)
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
            } else {
                HStack(spacing: 4) {
                    if let onHistory {
                        compactIconButton("clock.arrow.circlepath", action: onHistory)
                    }
                    if let onSave {
                        compactIconButton("square.and.arrow.down", action: onSave)
                            .opacity(saveDisabled ? 0.35 : 1)
                            .disabled(saveDisabled)
                    }
                    if let onClear {
                        compactIconButton("arrow.counterclockwise", action: onClear)
                    }
                }
            }
        }
    }

    private func compactIconButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(ABY.Font.footnoteMedium)
                .foregroundStyle(palette.textSecondary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - Chaplain hub (Mobbin ChatGPT / Copilot refs)

/// Compact continue banner — single line, not a full card.
struct ChaplainResumeBanner: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.uturn.forward.circle.fill")
                    .font(ABY.Font.headline)
                    .foregroundStyle(ABY.Color.pillTeal)
                Text("Continue")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.pillTeal)
                Text(title)
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(ABY.Font.emojiSmall)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.92))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(palette.divider.opacity(0.6), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.borderless)
    }
}

/// Slim resource links — one grouped card instead of stacked sections.
struct ChaplainExploreLinksCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onGuidedPrayer: () -> Void
    var onPassages: () -> Void
    var onWisdom: () -> Void

    private let links: [(String, String, () -> Void)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Explore")
                .font(ABY.Font.captionMedium)
                .foregroundStyle(palette.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                exploreRow(icon: "hands.sparkles", title: "Guided prayers", action: onGuidedPrayer)
                Divider().padding(.leading, 44)
                exploreRow(icon: "book.closed", title: "Passages & promises", action: onPassages)
                Divider().padding(.leading, 44)
                exploreRow(icon: "leaf", title: "Reflection", action: onWisdom)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.divider.opacity(0.45), lineWidth: 1)
            }
        }
    }

    private func exploreRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 28)
                Text(title)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(ABY.Font.emojiSmall)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - Resumed thread context (Mobbin Gemini — title + mood in header)

struct ChaplainResumedThreadHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation

    private var dateLabel: String {
        guard let date = conversation.recordedAt else { return conversation.timeAgo }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(dateLabel)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textTertiary)
                if conversation.moodLabel != "Present", !conversation.moodLabel.isEmpty {
                    Text("·")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                    Text("\(conversation.moodEmoji) \(conversation.moodLabel)")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer(minLength: 0)
                Text(conversation.timelineTime)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
            }

            HStack(alignment: .top, spacing: 10) {
                ABYChaplainAvatar(size: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Continuing your conversation")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.4)
                    Text(conversation.chaplainHistoryTitle)
                        .font(ABY.Font.editorialCallout)
                        .foregroundStyle(palette.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.divider.opacity(0.45), lineWidth: 1)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 6)
    }
}

struct ChaplainThreadDateDivider: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String

    var body: some View {
        Text(label)
            .font(ABY.Font.caption)
            .foregroundStyle(palette.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }
}

// MARK: - History display helpers

extension Conversation {
    private static let genericChaplainTitles: Set<String> = [
        "Chaplain Chat",
        "Chaplain Conversation",
    ]

    /// Prefer a user-message snippet over auto-generated mood titles like "Morning — Peaceful".
    var chaplainHistoryTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPreview = preview.trimmingCharacters(in: .whitespacesAndNewlines)

        if Self.genericChaplainTitles.contains(trimmedTitle)
            || trimmedTitle.hasPrefix("Morning —")
            || trimmedTitle.hasPrefix("Evening —") {
            if !trimmedPreview.isEmpty {
                return String(trimmedPreview.prefix(72))
            }
        }
        return trimmedTitle
    }

    var chaplainHistorySubtitle: String? {
        let trimmedPreview = preview.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPreview.isEmpty else { return nil }

        let displayTitle = chaplainHistoryTitle
        if displayTitle == trimmedPreview || displayTitle == String(trimmedPreview.prefix(72)) {
            return nil
        }
        return String(trimmedPreview.prefix(88))
    }
}

/// Copilot recents + Gemini section headers — one card, consistent rhythm.
/// Mobbin: https://mobbin.com/screens/40046f7b-1621-4099-a9e9-76910e645eb3
/// Mobbin: https://mobbin.com/screens/24e61d69-e92e-428f-a800-265e22419ae5
struct ChaplainChatHistoryGroupedList: View {
    @Environment(\.sanctuaryPalette) private var palette
    let groups: [(String, [Conversation])]
    let onSelect: (Conversation) -> Void
    var onDelete: ((Conversation) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(groups.enumerated()), id: \.offset) { groupIndex, group in
                sectionHeader(group.0, isFirst: groupIndex == 0)

                ForEach(Array(group.1.enumerated()), id: \.element.id) { itemIndex, conversation in
                    historyRow(conversation)

                    let isLastInGroup = itemIndex == group.1.count - 1
                    let isLastGroup = groupIndex == groups.count - 1
                    if !(isLastInGroup && isLastGroup) {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.divider.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.03), radius: 10, y: 3)
    }

    private func sectionHeader(_ title: String, isFirst: Bool) -> some View {
        HStack {
            Text(title)
                .font(ABY.Font.footnoteSemibold)
                .foregroundStyle(palette.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, isFirst ? 14 : 18)
        .padding(.bottom, 4)
    }

    private func historyRow(_ conversation: Conversation) -> some View {
        Button {
            onSelect(conversation)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(conversation.chaplainHistoryTitle)
                        .font(ABY.Font.calloutMedium)
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let subtitle = conversation.chaplainHistorySubtitle {
                        Text(subtitle)
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Text(conversation.timelineTime)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
                    .layoutPriority(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .contextMenu {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete(conversation)
                } label: {
                    Label("Delete chat", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Chat history (Mobbin Raycast / Bevel / ChatGPT refs)

struct ABYChatHistoryRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                Text(conversation.preview)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(2)
                Text(relativeLabel)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(ABY.Font.emojiSmall)
                .foregroundStyle(palette.textTertiary)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    private var relativeLabel: String {
        if let date = conversation.recordedAt {
            return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
        }
        return conversation.timeAgo
    }
}

struct ABYChatHistoryStartButton: View {
    @Environment(\.sanctuaryPalette) private var palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.pencil")
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(ABY.Color.pillTeal)
                    .frame(width: 28)
                Text("New chat")
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(palette.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.divider.opacity(0.45), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.borderless)
    }
}
