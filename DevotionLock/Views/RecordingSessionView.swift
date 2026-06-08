//
//  RecordingSessionView.swift
//  test1
//

import Combine
import SwiftUI

private enum VoiceCapturePhase {
    case recording
    case handoff
}

struct RecordingSessionView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var isPresented: Bool
    var initialPrompt: String? = nil
    var onComplete: ((String) -> Void)? = nil
    var onSwitchToChat: ((String) -> Void)? = nil
    var voiceTranscript: String? = nil
    var saveOnlyLabel: String = "Save only"
    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"

    @State private var transcription = SpeechTranscriptionService()
    @State private var voiceState: VoiceOrbState = .listening
    @State private var elapsed: TimeInterval = 0
    @State private var appeared = false
    @State private var promptIndex = 0
    @State private var isMuted = false
    @State private var starterLocked = false
    @State private var showCaptions = true
    @State private var speechStarted = false
    @State private var phase: VoiceCapturePhase = .recording
    @State private var capturedTranscript = ""

    private var offersChatHandoff: Bool { onSwitchToChat != nil }

    private var statusLabel: String {
        switch phase {
        case .handoff: "Ready to continue"
        case .recording:
            if transcription.authorizationDenied { "Microphone access needed" }
            else if isMuted { "Muted" }
            else if transcription.isListening { "Listening…" }
            else { "Ready to capture" }
        }
    }

    private var sessionPrompts: [String] {
        if let initialPrompt {
            [initialPrompt, "Speak freely — your words appear below.", "Tap done when you're finished."]
        } else {
            [
                "What's on your heart?",
                "Speak freely — your words appear below.",
                "Tap done when you're finished.",
            ]
        }
    }

    private var placeholderCaption: String {
        "Your words will appear here as you speak."
    }

    private var liveCaption: String {
        let spoken = transcription.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !spoken.isEmpty { return spoken }
        return placeholderCaption
    }

    private var hillIntensity: CGFloat {
        if isMuted || phase == .handoff { return 0.35 }
        return voiceState == .listening ? 1.0 : 0.55
    }

    private var selectedVoice: ChaplainVoice {
        ChaplainVoice.options.first { $0.id == selectedVoiceID } ?? ChaplainVoice.options[0]
    }

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            ABYCleanGradientBackground()

            PiVoiceHillsView(intensity: hillIntensity)
                .frame(height: 220)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 16)

                if phase == .handoff {
                    handoffContent
                } else {
                    recordingContent
                }
            }
        }
        .abyScreen()
        .onAppear {
            starterLocked = initialPrompt != nil
            if let seed = voiceTranscript?.trimmingCharacters(in: .whitespacesAndNewlines), !seed.isEmpty {
                transcription.transcript = seed
            }
            withAnimation(AppTheme.springGentle) { appeared = true }
            Task { await beginSpeechIfNeeded() }
        }
        .onDisappear {
            _ = transcription.stop()
        }
        .onReceive(timer) { _ in
            guard phase == .recording, !isMuted else { return }
            elapsed += 1
            if Int(elapsed) % 5 == 0 {
                withAnimation(AppTheme.springGentle) {
                    voiceState = voiceState == .listening ? .speaking : .listening
                }
            }
            if !starterLocked, Int(elapsed) % 6 == 0 {
                withAnimation {
                    promptIndex = (promptIndex + 1) % sessionPrompts.count
                }
            } else if starterLocked, elapsed >= 8 {
                starterLocked = false
            }
        }
    }

    // MARK: - Recording phase

    private var recordingContent: some View {
        Group {
            Spacer()

            VStack(spacing: 12) {
                Text(statusLabel)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)

                Text(sessionPrompts[promptIndex])
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .animation(AppTheme.springGentle, value: promptIndex)
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .opacity(appeared ? 1 : 0)

            VoiceOrb(state: isMuted ? .idle : voiceState, size: 220)
                .padding(.vertical, 28)
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 4) {
                if offersChatHandoff {
                    Text("Chaplain \(selectedVoice.name)")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("Speak first — your Chaplain replies in chat")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                } else {
                    Text("Voice capture")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("Your words save to your journal")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
            .opacity(appeared ? 1 : 0)

            if showCaptions {
                Text(liveCaption)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.isNight ? palette.textSecondary : ABY.Color.moodPeachText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
                    .padding(.top, 20)
                    .animation(AppTheme.springGentle, value: liveCaption)
            }

            Spacer()

            recordingControls
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 48)
        }
    }

    // MARK: - Handoff phase (Hybrid B)

    private var handoffContent: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            VStack(spacing: 10) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(ABY.Color.pillPurple)
                    .frame(width: 56, height: 56)
                    .background(ABY.Color.pillPurple.opacity(0.12))
                    .clipShape(Circle())

                Text("Continue with Chaplain?")
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)

                Text("Your Chaplain will respond in text chat — you can keep the conversation going there.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 12)
            }

            Text(capturedTranscript)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                }
                .padding(.horizontal, ABY.Spacing.screen)

            Spacer()

            VStack(spacing: 12) {
                ABYPrimaryButton(title: "Continue with Chaplain", icon: "sparkles") {
                    handoffToChat()
                }

                Button(saveOnlyLabel) {
                    saveOnlyAndDismiss()
                }
                .font(ABY.Font.callout.weight(.medium))
                .foregroundStyle(palette.textSecondary)
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 48)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Controls

    private var recordingControls: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(AppTheme.springSnappy) {
                    isMuted.toggle()
                    if isMuted {
                        _ = transcription.stop()
                        voiceState = .idle
                    } else {
                        Task { await beginSpeechIfNeeded() }
                        voiceState = .listening
                    }
                }
            } label: {
                Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                    .font(ABY.Font.iconLarge)
                    .foregroundStyle(isMuted ? palette.textTertiary : palette.textPrimary)
                    .frame(width: 52, height: 52)
                    .background(palette.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(palette.divider, lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            Button(action: finishRecording) {
                HStack(spacing: 8) {
                    VoiceWaveformIcon(active: !isMuted && transcription.isListening)
                    Text("Done")
                        .font(ABY.Font.button)
                }
                .foregroundStyle(palette.buttonForeground)
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(palette.buttonFill)
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var topBar: some View {
        HStack {
            ABYIconButton(icon: "xmark") {
                _ = transcription.stop()
                isPresented = false
            }

            Spacer()

            if phase == .recording {
                Text(formattedTime)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            if phase == .recording {
                ABYIconButton(icon: showCaptions ? "captions.bubble.fill" : "captions.bubble") {
                    withAnimation(AppTheme.springSnappy) { showCaptions.toggle() }
                }
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - Actions

    private func beginSpeechIfNeeded() async {
        guard !speechStarted, !isMuted else { return }
        let authorized = await transcription.requestAuthorization()
        guard authorized else { return }
        speechStarted = true
        do {
            try transcription.start()
            voiceState = .listening
        } catch {
            speechStarted = false
        }
    }

    private func currentTranscript() -> String {
        let spoken = transcription.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !spoken.isEmpty { return spoken }
        if let seed = voiceTranscript?.trimmingCharacters(in: .whitespacesAndNewlines), !seed.isEmpty {
            return seed
        }
        return ""
    }

    private func finishRecording() {
        _ = transcription.stop()
        let transcript = currentTranscript()
        capturedTranscript = transcript

        if offersChatHandoff, !transcript.isEmpty {
            withAnimation(AppTheme.springGentle) { phase = .handoff }
            DevotionHaptics.light()
        } else if let onComplete {
            onComplete(transcript)
            isPresented = false
        } else if offersChatHandoff {
            handoffToChat()
        } else {
            isPresented = false
        }
    }

    private func handoffToChat() {
        let transcript = capturedTranscript.isEmpty ? currentTranscript() : capturedTranscript
        isPresented = false
        onSwitchToChat?(transcript)
    }

    private func saveOnlyAndDismiss() {
        let transcript = capturedTranscript.isEmpty ? currentTranscript() : capturedTranscript
        onComplete?(transcript)
        isPresented = false
    }

    private var formattedTime: String {
        String(format: "%d:%02d", Int(elapsed) / 60, Int(elapsed) % 60)
    }
}

#Preview {
    RecordingSessionView(isPresented: .constant(true))
}
