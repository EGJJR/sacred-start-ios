//
//  JournalEntryViews.swift
//  DevotionLock
//
//  Mobbin refs: Liven Journey composer, Dot chronicle capture, voice-to-text journals
//

import Combine
import SwiftUI

// MARK: - Entry hub

struct JournalEntryHubSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.openGuidedJournal) private var openGuidedJournal

    var onAssisted: () -> Void
    var onVoice: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add to your journal")
                        .font(ABY.Font.title2)
                        .foregroundStyle(palette.textPrimary)
                    Text("Choose how you'd like to capture this moment.")
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                }

                VStack(spacing: 12) {
                    JournalEntryOptionCard(
                        icon: "sun.horizon.fill",
                        tint: ABY.Color.pillTeal,
                        title: "Morning devotion",
                        subtitle: "Guided flow · scripture, gratitude & streak",
                        badge: "~5 min"
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            openGuidedJournal()
                        }
                    }

                    JournalEntryOptionCard(
                        icon: "pencil.and.outline",
                        tint: ABY.Color.pillPurple,
                        title: "Assisted journal",
                        subtitle: "Gentle prompts to help you write freely",
                        badge: "Write"
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onAssisted()
                        }
                    }

                    if FeatureFlags.voiceChatEnabled {
                        JournalEntryOptionCard(
                            icon: "waveform",
                            tint: ABY.Color.pillOrange,
                            title: "Voice note",
                            subtitle: "Speak naturally — we'll transcribe it for you",
                            badge: "Voice"
                        ) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                onVoice()
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(ABY.Spacing.screen)
            .background(palette.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(palette.background)
    }
}

// MARK: - Assisted journal

struct AssistedJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    @State private var text = ""
    @State private var promptIndex = 0
    @State private var appeared = false
    @State private var isDictating = false
    @FocusState private var focused: Bool

    private let prompts = [
        "What's on your heart right now?",
        "Where did you sense God today?",
        "What felt heavy — or surprisingly light?",
        "What are you grateful for in this moment?",
        "What do you need to release before tomorrow?",
    ]

    private let suggestions = [
        "I'm noticing…",
        "I'm grateful for…",
        "I'm asking God for…",
    ]

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ABYCleanGradientBackground()

                VStack(alignment: .leading, spacing: 0) {
                    ABYAssistedJournalHeader(
                        prompt: prompts[promptIndex],
                        onShuffle: shufflePrompt
                    )
                    .padding(.top, 8)
                    .animation(AppTheme.springGentle, value: promptIndex)
                    .blurReveal(appeared, blurRadius: 6, scale: 1.004)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                if isDictating {
                    ABYInlineDictationCapture(text: $text, isActive: $isDictating)
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    VStack(spacing: 12) {
                        if text.isEmpty {
                            ABYStarterPhraseRow(
                                phrases: suggestions,
                                onSelect: appendSuggestion,
                                onShufflePrompt: shufflePrompt
                            )
                            .blurReveal(appeared, blurRadius: 4, scale: 1.002)
                        }

                        ABYAssistedJournalComposer(
                            text: $text,
                            placeholder: "Start writing…",
                            focused: $focused,
                            onDictate: {
                                focused = false
                                withAnimation(AppTheme.springGentle) { isDictating = true }
                            }
                        )
                        .blurReveal(appeared, blurRadius: 4, scale: 1.002)
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(ABY.Font.calloutSemibold)
                            .foregroundStyle(palette.textPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Write")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ABYAssistedJournalFinishButton(isEnabled: canSave, action: save)
                }
            }
        }
        .abyScreen()
        .animation(AppTheme.springGentle, value: isDictating)
        .onAppear {
            withAnimation(AppTheme.springGentle.delay(0.04)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if !isDictating { focused = true }
            }
        }
    }

    private func appendSuggestion(_ phrase: String) {
        if text.isEmpty {
            text = phrase + " "
        } else if !text.hasSuffix(" ") {
            text += " " + phrase + " "
        } else {
            text += phrase + " "
        }
        focused = true
    }

    private func shufflePrompt() {
        withAnimation(AppTheme.springSnappy) {
            promptIndex = (promptIndex + 1) % prompts.count
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        JournalLocalStore.shared.addAssistedEntry(
            body: trimmed,
            title: prompts[promptIndex],
            moodLabel: "Peaceful",
            moodEmoji: MoodCatalog.emoji(for: "Peaceful")
        )
        DevotionHaptics.success()
        dismiss()
    }
}

// MARK: - Voice journal

private enum VoiceJournalPhase {
    case recording
    case revealing
    case editing
}

struct VoiceJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.openChaplainChat) private var openChaplainChat

    @State private var transcription = SpeechTranscriptionService()
    @State private var phase: VoiceJournalPhase = .recording
    @State private var editedText = ""
    @State private var revealProgress: CGFloat = 1
    @State private var elapsed: TimeInterval = 0
    @State private var appeared = false
    @State private var speechStarted = false
    @State private var sessionStartedAt = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var placeholderCaption: String {
        "Your words will appear here as you speak."
    }

    private var liveCaption: String {
        let spoken = transcription.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        return spoken.isEmpty ? placeholderCaption : spoken
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ABYCleanGradientBackground()

            switch phase {
            case .recording:
                recordingLayout
            case .revealing, .editing:
                reviewLayout
            }
        }
        .abyScreen()
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
            Task { await beginRecording() }
        }
        .onDisappear {
            _ = transcription.stop()
        }
        .onReceive(timer) { _ in
            guard phase == .recording, transcription.isListening else { return }
            elapsed += 1
        }
    }

    private var recordingLayout: some View {
        VStack(spacing: 0) {
            ABYVoiceEntryTopBar(
                sessionTime: sessionStartedAt.formatted(date: .omitted, time: .shortened),
                onDismiss: cancelRecording,
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
                isListening: transcription.isListening,
                onCancel: cancelRecording,
                onSubmit: finishRecording
            )
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
        }
    }

    private var reviewLayout: some View {
        VStack(spacing: 0) {
            ABYVoiceEntryTopBar(
                sessionTime: sessionStartedAt.formatted(date: .omitted, time: .shortened),
                onDismiss: { dismiss() },
                onDone: { if phase == .editing { save() } }
            )
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(phase == .revealing ? "Revealing your words" : "Review & save")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textSecondary)
                    Spacer()
                    if phase == .editing {
                        Button("Re-record", action: resetRecording)
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(ABY.Color.pillOrange)
                    }
                }

                if phase == .revealing {
                    ProgressView("Transcribing…")
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    TextEditor(text: $editedText)
                        .font(ABY.Font.body)
                        .foregroundStyle(palette.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(16)
                        .frame(minHeight: 220)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                                .stroke(palette.divider, lineWidth: 1)
                        }
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 28)

            Spacer()

            if phase == .editing {
                VStack(spacing: 12) {
                    ABYPrimaryButton(title: "Save to journal", icon: "checkmark", action: save)
                        .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)

                    Button(action: continueWithChaplain) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("Continue with Chaplain")
                        }
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(ABY.Color.pillPurple)
                    }
                    .buttonStyle(.plain)
                    .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 32)
            }
        }
    }

    private func cancelRecording() {
        _ = transcription.stop()
        dismiss()
    }

    private var cardTimerText: String {
        let seconds = Int(elapsed)
        if seconds < 60 {
            return String(format: "0:%02d", seconds)
        }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func beginRecording() async {
        guard !speechStarted else { return }
        let authorized = await transcription.requestAuthorization()
        guard authorized else { return }
        speechStarted = true
        try? transcription.start()
    }

    private func finishRecording() {
        let transcript = transcription.stop()
        editedText = transcript.isEmpty ? "" : transcript
        phase = .revealing
        revealProgress = 1

        withAnimation(.easeOut(duration: 0.9)) {
            revealProgress = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            phase = .editing
            DevotionHaptics.light()
        }
    }

    private func resetRecording() {
        editedText = ""
        elapsed = 0
        speechStarted = false
        revealProgress = 1
        sessionStartedAt = Date()
        phase = .recording
        Task { await beginRecording() }
    }

    private func save() {
        let trimmed = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        JournalLocalStore.shared.addVoiceNote(transcript: trimmed)
        DevotionHaptics.success()
        dismiss()
    }

    private func continueWithChaplain() {
        let trimmed = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        JournalLocalStore.shared.addVoiceNote(transcript: trimmed)
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            openChaplainChat(
                VoiceChatHandoff.starter(from: trimmed, context: "my voice note"),
                VoiceChatHandoff.seedMessages(for: trimmed)
            )
        }
    }
}
