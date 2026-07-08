//
//  JournalEntryViews.swift
//  DevotionLock
//
//  Mobbin refs: ABY guided entry, Alan Mind voice journal, 5 Minute Journal prompts
//

import Combine
import SwiftUI
import UIKit

// MARK: - Guided Entry (Mobbin ABY / Alan Mind / 5 Minute Journal)

/// Shared prompt-led write surface — journal entry, morning reflection, wisdom prompts.
struct GuidedJournalEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    var navigationTitle: String = "Guided Entry"
    let seedPrompt: String
    @Binding var text: String
    var alternatePrompts: [String] = []
    var starterPhrases: [String] = [
        "I'm noticing…",
        "I'm grateful for…",
        "I'm asking God for…",
    ]
    var showsShuffle: Bool = true
    var allowsEmptyFinish: Bool = false
    var finishButtonTitle: String = "Finish"
    var onExpandWithAI: ((String) -> Void)? = nil
    var onSave: (String) -> Void

    @State private var appeared = false
    @State private var promptIndex = 0
    @State private var usingSeedPrompt = true
    @State private var isDictating = false
    @State private var keyboardOverlap: CGFloat = 0
    @FocusState private var focused: Bool

    private var displayPrompt: String {
        if usingSeedPrompt || alternatePrompts.isEmpty { return seedPrompt }
        return alternatePrompts[promptIndex % alternatePrompts.count]
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var finishEnabled: Bool {
        !trimmedText.isEmpty || allowsEmptyFinish
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ABYGuidedJournalBackground()
                guidedEntryContent(bottomPadding: keyboardBottomPadding(in: geometry))
            }
        }
        .abyScreen()
        .animation(AppTheme.springGentle, value: isDictating)
        .animation(.easeOut(duration: 0.25), value: keyboardOverlap)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            updateKeyboardOverlap(from: note)
        }
        .onAppear {
            withAnimation(AppTheme.springGentle.delay(0.04)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if !isDictating { focused = true }
            }
        }
    }

    private var shuffleAction: (() -> Void)? {
        guard showsShuffle, !alternatePrompts.isEmpty else { return nil }
        return shufflePrompt
    }

    @ViewBuilder
    private func guidedEntryContent(bottomPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            guidedEntryHeader

            VStack(alignment: .leading, spacing: 0) {
                ABYAssistedJournalHeader(
                    prompt: displayPrompt,
                    onShuffle: shuffleAction
                )
                .padding(.top, 4)
                .padding(.bottom, 20)
                .animation(AppTheme.springGentle, value: displayPrompt)
                .blurReveal(appeared, blurRadius: 6, scale: 1.004)

                Spacer(minLength: 12)
                guidedEntryComposer
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 8)
            .padding(.bottom, bottomPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private var guidedEntryComposer: some View {
        if isDictating {
            ABYInlineDictationCapture(
                text: $text,
                isActive: $isDictating,
                offersPolishChoice: true
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            VStack(alignment: .leading, spacing: 14) {
                ABYGuidedJournalWriteSurface(
                    text: $text,
                    phrases: starterPhrases,
                    showStarters: text.isEmpty,
                    onSelectPhrase: appendSuggestion,
                    focused: $focused,
                    onDictate: startDictation
                )
                .blurReveal(appeared, blurRadius: 4, scale: 1.002)

                if let onExpandWithAI {
                    GuidedEntryChaplainHandoffCard(
                        seed: trimmedText.isEmpty ? displayPrompt : trimmedText,
                        action: onExpandWithAI
                    )
                    .blurReveal(appeared, blurRadius: 4, scale: 1.002)
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var guidedEntryHeader: some View {
        HStack(alignment: .center) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(palette.textPrimary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(navigationTitle)
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)

            Spacer()

            ABYAssistedJournalFinishButton(finishButtonTitle, isEnabled: finishEnabled, action: save)
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func startDictation() {
        focused = false
        withAnimation(AppTheme.springGentle) { isDictating = true }
    }

    private func keyboardBottomPadding(in geometry: GeometryProxy) -> CGFloat {
        guard keyboardOverlap > 0 else { return max(12, geometry.safeAreaInsets.bottom + 8) }
        return max(10, keyboardOverlap - geometry.safeAreaInsets.bottom + 6)
    }

    private func updateKeyboardOverlap(from note: Notification) {
        guard
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
        else { return }

        let keyboardTop = frame.origin.y
        let windowBottom = window.bounds.maxY
        let overlap = max(0, windowBottom - keyboardTop)
        let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25

        withAnimation(.easeOut(duration: duration)) {
            keyboardOverlap = overlap
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
            usingSeedPrompt = false
            promptIndex = (promptIndex + 1) % max(alternatePrompts.count, 1)
        }
        DevotionHaptics.light()
    }

    private func save() {
        guard finishEnabled else { return }
        onSave(trimmedText)
        DevotionHaptics.success()
        dismiss()
    }
}

private struct GuidedEntryChaplainHandoffCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let seed: String
    let action: (String) -> Void

    var body: some View {
        Button {
            action(seed)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(ABY.Color.pillPurple)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Explore with Chaplain")
                        .font(ABY.Font.calloutMedium)
                        .foregroundStyle(palette.textPrimary)
                    Text("Continue this reflection in conversation")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(ABY.Font.iconSmall)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(palette.isNight ? 0.12 : 0.98))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ABY.Color.pillPurple.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityHint("Opens Chaplain chat with your reflection as a starting point")
    }
}

// MARK: - Entry hub
//
//  Mobbin refs:
//  Fabric action sheet — https://mobbin.com/screens/f2902335-d4e8-4f10-a540-8764198d023f
//  ChatGPT attach sheet — https://mobbin.com/screens/cf94f6ed-ad32-48c1-ad40-e8ee75e9615a
//  Obsidian action groups — https://mobbin.com/screens/09dec6de-5d1b-4020-922b-ad238e77263c

struct JournalEntryHubSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.openGuidedJournal) private var openGuidedJournal
    @Environment(\.openChaplainChat) private var openChaplainChat
    @Environment(\.openChaplainChatWithPortal) private var openChaplainChatWithPortal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"

    var onAssisted: () -> Void
    var onVoice: () -> Void

    @State private var revealed = false

    private var selectedVoice: ChaplainVoice {
        ChaplainVoice.options.first { $0.id == selectedVoiceID } ?? ChaplainVoice.options[0]
    }

    private struct HubOption: Identifiable {
        let id: String
        let icon: String
        let tint: Color
        let title: String
        let subtitle: String
        let meta: String?
        let perform: () -> Void
    }

    private var options: [HubOption] {
        var items: [HubOption] = [
            HubOption(
                id: "devotion",
                icon: "sun.horizon",
                tint: ABY.Color.pillTeal,
                title: "Morning devotion",
                subtitle: "Scripture, gratitude, and a quiet start",
                meta: "~5 min",
                perform: { openGuidedJournal() }
            ),
            HubOption(
                id: "guided",
                icon: "text.quote",
                tint: ABY.Color.pillPurple,
                title: "Guided entry",
                subtitle: "One prompt, type or speak your reflection",
                meta: nil,
                perform: onAssisted
            ),
        ]
        if FeatureFlags.voiceChatEnabled {
            items.append(
                HubOption(
                    id: "voice",
                    icon: "waveform",
                    tint: ABY.Color.pillOrange,
                    title: "Voice note",
                    subtitle: "Speak freely, then read it back",
                    meta: nil,
                    perform: onVoice
                )
            )
        }
        return items
    }

    /// Separate cards + footer pill need more vertical room than a stacked list.
    private var sheetHeight: CGFloat {
        let header: CGFloat = 86
        let card: CGFloat = 78
        let cardGap: CGFloat = 10
        let cards = CGFloat(options.count) * card + CGFloat(max(options.count - 1, 0)) * cardGap
        let chaplainPill: CGFloat = 88
        let padding: CGFloat = 28
        return header + cards + chaplainPill + padding
    }

    private var sheetBackground: Color {
        palette.isNight ? ABY.Color.eveningReflectionMid : ABY.Color.background
    }

    private var momentSubtitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Capture this morning" }
        if hour < 17 { return "Capture this afternoon" }
        return "Capture this evening"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add to your journal")
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)
                Text(momentSubtitle)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 8)

            optionCards
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 10)

            ChaplainGlowPill {
                openChaplainFromHub()
            }
            .padding(.top, 22)
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 12)
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(min(sheetHeight, 520))])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(sheetBackground)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(named: "Dismiss") {
            dismiss()
        }
        .onAppear(perform: reveal)
    }

    /// Each option is its own elevated card with real margins — not a cramped list.
    private var optionCards: some View {
        VStack(spacing: 10) {
            ForEach(options) { option in
                JournalHubSheetRow(
                    icon: option.icon,
                    tint: option.tint,
                    title: option.title,
                    subtitle: option.subtitle,
                    meta: option.meta
                ) {
                    select(option)
                }
            }
        }
    }

    private func reveal() {
        guard !reduceMotion else {
            revealed = true
            return
        }
        withAnimation(AppTheme.springGentle.delay(0.02)) {
            revealed = true
        }
    }

    private func select(_ option: HubOption) {
        DevotionHaptics.light()
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            option.perform()
        }
    }

    private func openChaplainFromHub() {
        DevotionHaptics.soft()

        if reduceMotion {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                openChaplainChat(nil, [])
            }
            return
        }

        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            openChaplainChatWithPortal(selectedVoice.name, nil, [])
        }
    }
}

private struct JournalHubSheetRow: View {
    @Environment(\.sanctuaryPalette) private var palette

    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let meta: String?
    var onTap: () -> Void

    private var iconForeground: Color {
        palette.isNight ? ABY.Color.starlight : tint
    }

    private var iconFill: Color {
        palette.isNight ? Color.white.opacity(0.12) : tint.opacity(0.14)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(iconForeground)
                    .frame(width: 44, height: 44)
                    .background(iconFill)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                if let meta {
                    Text(meta)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.isNight ? ABY.Color.starlight.opacity(0.7) : tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (palette.isNight ? Color.white.opacity(0.08) : tint.opacity(0.12))
                        )
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.textTertiary.opacity(palette.isNight ? 0.65 : 0.75))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(palette.isNight ? 0.16 : 0.05), radius: 12, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(JournalHubSheetRowStyle())
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

private struct JournalHubSheetRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(AppTheme.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Guided entry (journal)

/// Edit an existing single-block journal capture — same surface as create.
struct EditJournalEntryView: View {
    let conversation: Conversation
    var onSaved: (Conversation) -> Void

    @State private var text = ""

    var body: some View {
        GuidedJournalEntryView(
            navigationTitle: "Edit entry",
            seedPrompt: conversation.journalReadPrompt,
            text: $text,
            showsShuffle: false,
            finishButtonTitle: "Save",
            onSave: { saved in
                if JournalLocalStore.shared.updateEntry(id: conversation.id, body: saved) != nil,
                   let updated = JournalLocalStore.shared.entry(id: conversation.id)?.asConversation() {
                    DevotionHaptics.success()
                    onSaved(updated)
                }
            }
        )
        .onAppear {
            text = conversation.journalReadBody
        }
    }
}

struct AssistedJournalView: View {
    @State private var text = ""

    var initialPrompt: String? = nil

    private let prompts = [
        "What's on your heart right now?",
        "Where did you sense God today?",
        "What felt heavy, or surprisingly light?",
        "What are you grateful for in this moment?",
        "What do you need to release before tomorrow?",
    ]

    var body: some View {
        GuidedJournalEntryView(
            navigationTitle: "Guided Entry",
            seedPrompt: initialPrompt ?? prompts[0],
            text: $text,
            alternatePrompts: prompts,
            onSave: save
        )
    }

    private func save(_ body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        JournalLocalStore.shared.addAssistedEntry(
            body: trimmed,
            title: initialPrompt ?? prompts[0],
            moodLabel: "Peaceful",
            moodEmoji: MoodCatalog.emoji(for: "Peaceful")
        )
    }
}

// MARK: - Voice journal

private enum VoiceJournalPhase {
    case recording
    case polishChoice
    case editing
}

struct VoiceJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.openChaplainChat) private var openChaplainChat

    @State private var transcription = SpeechTranscriptionService()
    @State private var phase: VoiceJournalPhase = .recording
    @State private var editedText = ""
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
            case .polishChoice, .editing:
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

            if phase == .polishChoice {
                ABYSpeechPolishReview(
                    rawTranscript: editedText,
                    onKeepRaw: {
                        phase = .editing
                        DevotionHaptics.light()
                    },
                    onTidyComplete: { polished in
                        editedText = polished
                        phase = .editing
                    },
                    onCancel: resetRecording
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 20)
            } else {
                editingReviewBody
            }

            Spacer()
        }
    }

    private var editingReviewBody: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Review & save")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textSecondary)
                    Spacer()
                    Button("Re-record", action: resetRecording)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(ABY.Color.pillOrange)
                }

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
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 28)

            Spacer()

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
        let transcript = transcription.stop().trimmingCharacters(in: .whitespacesAndNewlines)
        editedText = transcript
        if JournalTranscriptOrganizer.worthPolishChoice(transcript) {
            phase = .polishChoice
            DevotionHaptics.light()
        } else {
            phase = .editing
            DevotionHaptics.success()
        }
    }

    private func resetRecording() {
        editedText = ""
        elapsed = 0
        speechStarted = false
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
