//
//  RecordingSessionView.swift
//  DevotionLock
//
//  Mobbin ABY Journal: transcript up top, floating waveform card at bottom.
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
    @State private var elapsed: TimeInterval = 0
    @State private var appeared = false
    @State private var speechStarted = false
    @State private var phase: VoiceCapturePhase = .recording
    @State private var capturedTranscript = ""
    @State private var sessionStartedAt = Date()

    private var offersChatHandoff: Bool { onSwitchToChat != nil }

    private var placeholderCaption: String {
        "Your words will appear here as you speak."
    }

    private var liveCaption: String {
        let spoken = transcription.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !spoken.isEmpty { return spoken }
        if let seed = voiceTranscript?.trimmingCharacters(in: .whitespacesAndNewlines), !seed.isEmpty {
            return seed
        }
        return placeholderCaption
    }

    private var isListening: Bool {
        phase == .recording && transcription.isListening
    }

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            ABYCleanGradientBackground()

            VStack(spacing: 0) {
                if phase == .handoff {
                    handoffContent
                } else {
                    recordingContent
                }
            }
        }
        .abyScreen()
        .onAppear {
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
            guard phase == .recording, transcription.isListening else { return }
            elapsed += 1
        }
    }

    // MARK: - Recording phase

    private var recordingContent: some View {
        VStack(spacing: 0) {
            ABYVoiceEntryTopBar(
                sessionTime: sessionStartedAt.formatted(date: .omitted, time: .shortened),
                onDismiss: cancelSession,
                onDone: finishRecording
            )
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 16)
            .opacity(appeared ? 1 : 0)

            Text(liveCaption)
                .font(ABY.Font.body)
                .foregroundStyle(
                    liveCaption == placeholderCaption ? palette.textTertiary : palette.textPrimary
                )
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 28)
                .animation(AppTheme.springGentle, value: liveCaption)
                .opacity(appeared ? 1 : 0)

            Spacer()

            ABYVoiceCaptureCard(
                timerText: cardTimerText,
                isListening: isListening,
                onCancel: cancelSession,
                onSubmit: finishRecording
            )
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
        }
    }

    // MARK: - Handoff phase

    private var handoffContent: some View {
        VStack(spacing: 0) {
            ABYVoiceEntryTopBar(
                sessionTime: sessionStartedAt.formatted(date: .omitted, time: .shortened),
                onDismiss: { isPresented = false },
                onDone: handoffToChat
            )
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 16)

            VStack(spacing: 24) {
                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Image(systemName: "text.bubble.fill")
                        .font(ABY.Font.title)
                        .foregroundStyle(ABY.Color.pillPurple)
                        .frame(width: 56, height: 56)
                        .background(ABY.Color.pillPurple.opacity(0.12))
                        .clipShape(Circle())

                    Text("Continue with Chaplain?")
                        .font(ABY.Font.title2)
                        .foregroundStyle(palette.textPrimary)

                    Text("Your Chaplain will respond in text chat. You can keep the conversation going there.")
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 12)
                }

                Text(capturedTranscript)
                    .font(ABY.Font.body)
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
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(palette.textSecondary)
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 48)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Actions

    private func beginSpeechIfNeeded() async {
        guard !speechStarted else { return }
        let authorized = await transcription.requestAuthorization()
        guard authorized else { return }
        speechStarted = true
        do {
            try transcription.start()
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

    private func cancelSession() {
        _ = transcription.stop()
        isPresented = false
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

    private var cardTimerText: String {
        let seconds = Int(elapsed)
        if seconds < 60 {
            return String(format: "0:%02d", seconds)
        }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    RecordingSessionView(isPresented: .constant(true))
}
