//
//  GuidedJournalFlowView.swift
//  DevotionLock
//

import SwiftUI

enum GuidedJournalStep: Int, CaseIterable {
    case mood
    case focusTags
    case madLibs
    case gratitude
    case affirmation
    case scripture
    case voice
    case complete

    var progressIndex: Int { rawValue }
}

enum MadLibField: String, Identifiable, CaseIterable {
    case emotion
    case reason
    case onMind
    case plans

    var id: String { rawValue }

    var prefix: String {
        switch self {
        case .emotion: "Right now, I'm feeling "
        case .reason: "because I "
        case .onMind: "I've also been thinking about "
        case .plans: "One thing I have planned for the next few days is "
        }
    }

    var placeholder: String {
        switch self {
        case .emotion: "e.g. peaceful, tired, hopeful"
        case .reason: "e.g. work is heavy"
        case .onMind: "e.g. a conversation ahead"
        case .plans: "e.g. quiet prayer tonight"
        }
    }

    var cardTitle: String {
        switch self {
        case .emotion: "Right now, I'm feeling…"
        case .reason: "Because I…"
        case .onMind: "I've also been thinking about…"
        case .plans: "One thing I have planned is…"
        }
    }

    var color: Color {
        switch self {
        case .emotion: ABY.Color.pillPink
        case .reason: ABY.Color.pillOrange
        case .onMind: ABY.Color.pillTeal
        case .plans: ABY.Color.pillPurple
        }
    }

    var suggestions: [String] {
        switch self {
        case .emotion:
            MoodCatalog.options.map(\.label)
        case .reason:
            ["work is heavy", "family needs me", "I'm tired", "something good happened", "I'm uncertain"]
        case .onMind:
            ["what matters today", "a conversation ahead", "rest I need", "gratitude", "a decision"]
        case .plans:
            ["time with family", "a walk outside", "quiet prayer", "finishing a task", "rest tonight"]
        }
    }
}

struct GuidedJournalFlowView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var isPresented: Bool
    var streakManager: StreakManager
    var userName: String
    var onDevotionFinished: ((DevotionFinishResult) -> Void)? = nil
    var onOpenChaplainChat: ((String) -> Void)? = nil

    @AppStorage("intentionMood") private var intentionMood = "Peaceful"

    @State private var step: GuidedJournalStep = .mood
    @State private var draft = JournalDraft()
    @State private var contentAppeared = false
    @State private var completedStreak = 0
    @State private var finishResult: DevotionFinishResult?
    @State private var shouldCelebrate = false
    @State private var journalStartedAt = Date()
    @FocusState private var focusedField: MadLibField?

    private var journalElapsedSeconds: Int {
        Int(Date().timeIntervalSince(journalStartedAt))
    }

    private var dailyFocus: DailyFocus { DailyFocus.today }
    private let totalSteps = GuidedJournalStep.allCases.count

    private var flowProgress: CGFloat {
        CGFloat(step.progressIndex + 1) / CGFloat(totalSteps)
    }

    var body: some View {
        ZStack {
            if step == .voice {
                RecordingSessionView(
                    isPresented: voiceBinding,
                    onComplete: finishVoiceStep,
                    onSwitchToChat: switchVoiceToChat,
                    voiceTranscript: voiceTranscriptSeed
                )
            } else if step == .complete {
                ZStack {
                    ABYOnboardingMeshBackground()
                    DevotionCompletionView(
                        streak: completedStreak,
                        mood: draft.mood,
                        onContinue: dismissFlow
                    )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                journalChrome
            }
        }
        .animation(AppTheme.springGentle, value: step)
        .onAppear {
            draft.mood = intentionMood
            draft.applyMoodDefaults()
            animateIn()
            // Lock screen Live Activity disabled for now — re-enable when layout is finalized.
            // JournalLiveActivityManager.startIfAvailable()
        }
        .onDisappear {
            // JournalLiveActivityManager.end()
        }
        .onChange(of: step) { _, newStep in
            focusedField = nil
            animateIn()
            // JournalLiveActivityManager.update(step: newStep, elapsedSeconds: journalElapsedSeconds)
        }
    }

    private var voiceBinding: Binding<Bool> {
        Binding(
            get: { step == .voice },
            set: { if !$0 { step = .scripture } }
        )
    }

    private var journalChrome: some View {
        ZStack {
            if step == .madLibs {
                ABYJournalGradientBackground()
            } else {
                ABYBackground()
            }

            VStack(spacing: 0) {
                flowTopBar
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                if step == .madLibs {
                    VStack(spacing: 0) {
                        ScrollView(showsIndicators: false) {
                            madLibsStep
                                .padding(.horizontal, ABY.Spacing.screen)
                                .padding(.bottom, 16)
                        }
                        .scrollDismissesKeyboard(.interactively)

                        ABYPrimaryButton(title: "Finished!", action: advance)
                            .opacity(draft.isMadLibsComplete ? 1 : 0.4)
                            .disabled(!draft.isMadLibsComplete)
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.bottom, 32)
                    }
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 12)
                } else if step == .gratitude || step == .affirmation {
                    VStack(spacing: 0) {
                        ScrollView(showsIndicators: false) {
                            stepContent
                                .padding(.horizontal, ABY.Spacing.screen)
                                .padding(.bottom, 16)
                                .opacity(contentAppeared ? 1 : 0)
                                .offset(y: contentAppeared ? 0 : 14)
                        }
                        .scrollDismissesKeyboard(.interactively)

                        flowBottomCTA
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.bottom, 32)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        stepContent
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.bottom, 24)
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 14)
                    }

                    flowBottomCTA
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 32)
                }
            }
        }
        .abyScreen()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .font(ABY.Font.body.weight(.medium))
            }
        }
    }

    private var flowTopBar: some View {
        VStack(spacing: 14) {
            ABYThinProgressBar(progress: flowProgress)
            HStack {
                if step != .mood {
                    ABYIconButton(icon: "chevron.left") { goBack() }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
                Spacer()
                Button(action: dismissFlow) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .mood:
            moodStep
        case .focusTags:
            FocusTagsStepView(selectedTags: $draft.focusTags, appeared: contentAppeared)
        case .madLibs:
            madLibsStep
        case .gratitude:
            GratitudeStepView(items: $draft.gratitudeItems, appeared: contentAppeared)
        case .affirmation:
            AffirmationStepView(affirmation: $draft.affirmation, appeared: contentAppeared)
        case .scripture:
            scriptureStep
        case .voice, .complete:
            EmptyView()
        }
    }

    private var moodStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            ABYHeadline(
                title: "How are you this morning?",
                subtitle: "About 5 minutes · scripture, gratitude, and optional voice with your Chaplain."
            )
            VStack(spacing: 8) {
                ForEach(Array(MoodCatalog.options.enumerated()), id: \.offset) { index, mood in
                    JournalMoodChip(
                        label: mood.label,
                        icon: mood.icon,
                        isSelected: draft.mood == mood.label
                    ) {
                        withAnimation(AppTheme.springSnappy) {
                            draft.mood = mood.label
                            draft.emotion = mood.label.lowercased()
                            intentionMood = mood.label
                        }
                    }
                    .animation(AppTheme.springGentle.delay(0.04 + Double(index) * 0.03), value: contentAppeared)
                }
            }
        }
        .padding(.top, 8)
    }

    private var madLibsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(userName.isEmpty
                     ? "Let's begin with this moment!"
                     : "Let's begin with this moment, \(userName)!")
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("No perfect words needed. Just what's true right now...")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.top, 8)
            .padding(.bottom, 20)

            MadLibLivePreview(draft: draft)
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(MadLibField.allCases) { field in
                    MadLibFieldCard(
                        field: field,
                        text: binding(for: field),
                        focusedField: $focusedField
                    )
                }
            }
            .padding(.bottom, 8)
        }
    }

    private var scriptureStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            ABYHeadline(
                title: "Pause with Scripture",
                subtitle: "Tap the words that speak to you, then breathe before you speak."
            )

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Today's focus")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(ABY.Color.textSecondary)
                    Spacer()
                    MoodPill(label: draft.mood)
                }
            }
            .abyCard()

            BlackoutVerseView(
                verse: dailyFocus.verse,
                reference: dailyFocus.reference,
                savedPhrase: $draft.savedVersePhrase
            )
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var flowBottomCTA: some View {
        switch step {
        case .mood:
            ABYPrimaryButton(title: "Continue", icon: "arrow.right", action: advance)
        case .focusTags:
            ABYPrimaryButton(title: "Continue", icon: "arrow.right", action: advanceFromFocusTags)
        case .madLibs:
            EmptyView()
        case .gratitude:
            ABYPrimaryButton(title: "Continue", icon: "arrow.right", action: advance)
                .opacity(draft.isGratitudeComplete ? 1 : 0.4)
                .disabled(!draft.isGratitudeComplete)
        case .affirmation:
            ABYPrimaryButton(title: "Continue", icon: "arrow.right", action: advance)
                .opacity(draft.isAffirmationComplete ? 1 : 0.4)
                .disabled(!draft.isAffirmationComplete)
        case .scripture:
            ABYPrimaryButton(title: "Talk with Chaplain", icon: "waveform", action: advance)
        case .voice, .complete:
            EmptyView()
        }
    }

    private func advanceFromFocusTags() {
        TodayFocusStore.save(draft.focusTags)
        JourneyTimelineStore.shared.logMood(draft.mood, tags: draft.selectedFocusTags)
        advance()
    }

    private func recordDevotionCompletion() {
        let summary = DaySummary.from(draft: draft, verseReference: dailyFocus.reference)
        finishResult = streakManager.recordDevotion(mood: draft.mood, summary: summary)
        DailyRhythmStore.shared.markComplete(.morningDevotion)
        JourneyTimelineStore.shared.logDevotion(summary: summary, draft: draft)
        TodayFocusStore.save(draft.focusTags)
        Task {
            await DevotionSessionRepository.shared.syncCompletion(
                draft: draft,
                verseReference: dailyFocus.reference,
                summary: summary
            )
        }
        AppShieldManager.shared.unlockForCompletedDevotion()
        PersonalInsightStore.shared.refresh()
    }

    private func binding(for field: MadLibField) -> Binding<String> {
        switch field {
        case .emotion:
            Binding(
                get: { draft.emotion },
                set: { newValue in
                    draft.emotion = newValue
                    if let match = MoodCatalog.options.first(where: {
                        $0.label.lowercased() == newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    }) {
                        draft.mood = match.label
                        intentionMood = match.label
                    }
                }
            )
        case .reason: $draft.reason
        case .onMind: $draft.onMind
        case .plans: $draft.plans
        }
    }

    private func animateIn() {
        contentAppeared = false
        withAnimation(AppTheme.springGentle) { contentAppeared = true }
    }

    private func goBack() {
        withAnimation(AppTheme.springSnappy) {
            if let previous = GuidedJournalStep(rawValue: step.rawValue - 1) {
                step = previous
            }
        }
    }

    private func advance() {
        focusedField = nil
        withAnimation(AppTheme.springSnappy) {
            if let next = GuidedJournalStep(rawValue: step.rawValue + 1) {
                step = next
            }
        }
    }

    private var voiceTranscriptSeed: String {
        "Right now I'm feeling \(draft.emotion) because I \(draft.reason)."
    }

    private func finishVoiceStep(_ transcript: String) {
        let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !spoken.isEmpty {
            draft.reflectionText = spoken
        }
        let wasAlreadyComplete = streakManager.isCompletedToday
        recordDevotionCompletion()
        shouldCelebrate = !wasAlreadyComplete
        completedStreak = finishResult?.streak ?? streakManager.currentStreak
        withAnimation(AppTheme.springGentle) {
            step = .complete
        }
    }

    private func switchVoiceToChat(_ transcript: String) {
        let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !spoken.isEmpty {
            draft.reflectionText = spoken
        }
        let wasAlreadyComplete = streakManager.isCompletedToday
        recordDevotionCompletion()
        shouldCelebrate = !wasAlreadyComplete
        isPresented = false
        if shouldCelebrate, let finishResult {
            onDevotionFinished?(finishResult)
        }
        onOpenChaplainChat?(transcript)
    }

    private func dismissFlow() {
        if shouldCelebrate, let finishResult {
            onDevotionFinished?(finishResult)
        }
        withAnimation(AppTheme.springSnappy) {
            isPresented = false
        }
    }
}

// MARK: - Subviews

struct JournalMoodChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(isSelected ? palette.textPrimary : palette.textSecondary)
                    .frame(width: 28)
                Text(label)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.textPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? palette.surfaceElevated : palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.card)
                    .stroke(isSelected ? palette.textSecondary : palette.divider, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct MadLibLivePreview: View {
    @Environment(\.sanctuaryPalette) private var palette
    let draft: JournalDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            previewLine(prefix: "Right now, I'm feeling ", value: draft.emotion, color: MadLibField.emotion.color)
            previewLine(prefix: "because I ", value: draft.reason, color: MadLibField.reason.color)
            previewLine(prefix: "I've also been thinking about ", value: draft.onMind, color: MadLibField.onMind.color)
            previewLine(prefix: "One thing I have planned is ", value: draft.plans, color: MadLibField.plans.color)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface.opacity(palette.isNight ? 0.88 : 0.72))
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .overlay(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge).stroke(palette.divider, lineWidth: 1))
    }

    private func previewLine(prefix: String, value: String, color: Color) -> some View {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(prefix)
                .foregroundStyle(palette.textSecondary)
            Text(trimmed.isEmpty ? "…" : value)
                .foregroundStyle(trimmed.isEmpty ? palette.textTertiary : color)
                .fontWeight(.medium)
                .contentTransition(.opacity)
                .animation(AppTheme.springSnappy, value: value)
            Text(".")
                .foregroundStyle(palette.textSecondary)
        }
        .font(ABY.Font.callout)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct MadLibFieldCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let field: MadLibField
    @Binding var text: String
    var focusedField: FocusState<MadLibField?>.Binding

    private var isFocused: Bool { focusedField.wrappedValue == field }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(field.cardTitle)
                .font(ABY.Font.body.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            TextField(field.placeholder, text: $text, axis: .vertical)
                .lineLimit(1...4)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .tint(field.color)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(palette.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: ABY.Radius.card)
                        .stroke(isFocused ? field.color.opacity(0.85) : palette.divider, lineWidth: isFocused ? 2 : 1)
                }
                .focused(focusedField, equals: field)
                .contentShape(RoundedRectangle(cornerRadius: ABY.Radius.card))

            if !field.suggestions.isEmpty {
                MadLibQuickPicks(field: field, text: $text)
            }
        }
    }
}

struct MadLibQuickPicks: View {
    @Environment(\.sanctuaryPalette) private var palette
    let field: MadLibField
    @Binding var text: String

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick picks")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textSecondary)
                .tracking(0.4)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(field.suggestions, id: \.self) { suggestion in
                    Button {
                        text = field == .emotion ? suggestion.lowercased() : suggestion
                    } label: {
                        Text(suggestion)
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(field.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(field.color.opacity(text == suggestion || (field == .emotion && text == suggestion.lowercased()) ? 0.2 : 0.1))
                            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.chip))
                            .overlay {
                                RoundedRectangle(cornerRadius: ABY.Radius.chip)
                                    .stroke(field.color.opacity(0.35), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    GuidedJournalFlowView(
        isPresented: .constant(true),
        streakManager: .shared,
        userName: "Alex"
    )
}
