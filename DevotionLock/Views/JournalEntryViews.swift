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
    @State private var moodLabel = "Peaceful"
    @State private var promptIndex = 0
    @State private var appeared = false
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
        "Today I felt…",
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                assistedBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Assisted journal")
                                .font(ABY.Font.captionMedium)
                                .foregroundStyle(ABY.Color.pillPurple)
                            Text(prompts[promptIndex])
                                .font(ABY.Font.title2)
                                .foregroundStyle(palette.textPrimary)
                                .contentTransition(.opacity)
                                .animation(AppTheme.springGentle, value: promptIndex)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                        moodRow

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                                .fill(palette.surface.opacity(0.82))
                                .background {
                                    RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                                        .stroke(palette.divider, lineWidth: 1)
                                }

                            TextEditor(text: $text)
                                .font(.system(size: 17, weight: .regular, design: .serif))
                                .foregroundStyle(palette.textPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(16)
                                .frame(minHeight: 180)
                                .focused($focused)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { phrase in
                                    Button {
                                        appendSuggestion(phrase)
                                    } label: {
                                        Text(phrase)
                                            .font(ABY.Font.captionMedium)
                                            .foregroundStyle(ABY.Color.pillPurple)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(ABY.Color.pillPurple.opacity(0.08))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button {
                                    withAnimation(AppTheme.springSnappy) {
                                        promptIndex = (promptIndex + 1) % prompts.count
                                    }
                                } label: {
                                    Label("New prompt", systemImage: "arrow.triangle.2.circlepath")
                                        .font(ABY.Font.captionMedium)
                                        .foregroundStyle(palette.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(palette.surfaceMuted)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(ABY.Spacing.screen)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Text("Your words stay private on this device until you choose to share.")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.vertical, 10)
                    .background(SanctuaryGradientBottomFade())
            }
        }
        .abyScreen()
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                focused = true
            }
        }
    }

    private var assistedBackground: some View {
        ABYCleanGradientBackground()
    }

    private var moodRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MoodCatalog.options.prefix(6), id: \.label) { mood in
                    Button {
                        moodLabel = mood.label
                    } label: {
                        HStack(spacing: 6) {
                            Text(mood.emoji)
                            Text(mood.label)
                                .font(ABY.Font.captionMedium)
                        }
                        .foregroundStyle(moodLabel == mood.label ? .white : palette.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(moodLabel == mood.label ? ABY.Color.pillPurple : palette.surfaceMuted)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
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

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        JournalLocalStore.shared.addAssistedEntry(
            body: trimmed,
            title: "Journal entry",
            moodLabel: moodLabel,
            moodEmoji: MoodCatalog.emoji(for: moodLabel)
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

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                ABYCleanGradientBackground()

                VStack(spacing: 24) {
                    phaseHeader

                    Spacer(minLength: 0)

                    centerContent

                    Spacer(minLength: 0)

                    bottomControls
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.vertical, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        _ = transcription.stop()
                        dismiss()
                    }
                }
                if phase == .editing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") { save() }
                            .fontWeight(.semibold)
                            .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
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

    @ViewBuilder
    private var phaseHeader: some View {
        VStack(spacing: 8) {
            Text(phaseTitle)
                .font(ABY.Font.title2)
                .foregroundStyle(palette.textPrimary)
            Text(phaseSubtitle)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .opacity(appeared ? 1 : 0)
    }

    @ViewBuilder
    private var centerContent: some View {
        switch phase {
        case .recording:
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(ABY.Color.pillOrange.opacity(0.12))
                        .frame(width: 120, height: 120)
                        .scaleEffect(transcription.isListening ? 1.08 : 1)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: transcription.isListening)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(ABY.Color.pillOrange)
                }

                Text(formattedTime)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(palette.textTertiary)

                liveTranscriptPreview
            }

        case .revealing, .editing:
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Transcript", systemImage: "text.quote")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textSecondary)
                    Spacer()
                    if phase == .editing {
                        Button("Re-record") {
                            resetRecording()
                        }
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(ABY.Color.pillOrange)
                    }
                }

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                        .fill(palette.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                                .stroke(palette.divider, lineWidth: 1)
                        }

                    if phase == .editing {
                        TextEditor(text: $editedText)
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .foregroundStyle(palette.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(16)
                            .frame(minHeight: 200)
                    } else {
                        Text(editedText)
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .foregroundStyle(palette.textPrimary)
                            .lineSpacing(5)
                            .padding(16)
                            .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
                            .blur(radius: 16 * revealProgress)
                            .opacity(Double(1.1 - revealProgress * 0.35))
                    }
                }
            }
        }
    }

    private var liveTranscriptPreview: some View {
        let spoken = transcription.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        return Text(spoken.isEmpty ? "Your words will appear here as you speak…" : spoken)
            .font(.system(size: 16, weight: .regular, design: .serif))
            .foregroundStyle(spoken.isEmpty ? palette.textTertiary : palette.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 12)
            .blur(radius: spoken.isEmpty ? 0 : (transcription.isListening ? 2 : 0))
            .animation(AppTheme.springGentle, value: spoken)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var bottomControls: some View {
        switch phase {
        case .recording:
            Button(action: finishRecording) {
                HStack(spacing: 8) {
                    VoiceWaveformIcon(active: transcription.isListening)
                    Text("Done speaking")
                        .font(ABY.Font.button)
                }
                .foregroundStyle(palette.buttonForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(palette.buttonFill)
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())

        case .revealing:
            ProgressView("Transcribing…")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)

        case .editing:
            VStack(spacing: 12) {
                Button(action: save) {
                    Text("Save to journal")
                        .font(ABY.Font.button)
                        .foregroundStyle(palette.buttonForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(palette.buttonFill)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    continueWithChaplain()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Continue with Chaplain")
                    }
                    .font(ABY.Font.callout.weight(.semibold))
                    .foregroundStyle(ABY.Color.pillPurple)
                }
                .buttonStyle(.plain)
                .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var phaseTitle: String {
        switch phase {
        case .recording: "Voice note"
        case .revealing: "Revealing your words"
        case .editing: "Review & save"
        }
    }

    private var phaseSubtitle: String {
        switch phase {
        case .recording: "Speak freely — no perfect words needed."
        case .revealing: "Taking a breath while your note settles in."
        case .editing: "Edit anything before saving to your journal."
        }
    }

    private var formattedTime: String {
        String(format: "%d:%02d", Int(elapsed) / 60, Int(elapsed) % 60)
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
