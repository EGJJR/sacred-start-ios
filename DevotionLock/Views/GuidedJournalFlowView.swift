//
//  GuidedJournalFlowView.swift
//  DevotionLock
//
//  Mobbin ABY refs:
//  - Mad-libs flow: https://mobbin.com/screens/5c0e4735-be8c-426b-9e69-83c2c7ca148e
//  - Field sheet: https://mobbin.com/screens/639a07c0-20f4-427f-9421-913a03694448
//  - Guided entry + voice: https://mobbin.com/screens/652fd5c2-e81e-4fd8-ad5a-10f650b04f12
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

    var inlinePlaceholder: String {
        switch self {
        case .emotion: "emotion"
        case .reason: "reason for emotion"
        case .onMind: "something on your mind"
        case .plans: "future plans"
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

    var sheetTitle: String {
        switch self {
        case .emotion: "Current emotional state"
        case .reason: "What's behind the feeling"
        case .onMind: "On your mind"
        case .plans: "Future plans"
        }
    }

    var sheetPlaceholder: String {
        switch self {
        case .emotion: "Add something personal to you"
        case .reason: "Name what's shaping today"
        case .onMind: "What's been circling"
        case .plans: "One thing ahead"
        }
    }
}

extension GuidedJournalStep {
    var stepTitle: String {
        switch self {
        case .mood: "Check in"
        case .focusTags: "Focus"
        case .madLibs: "This moment"
        case .gratitude: "Gratitude"
        case .affirmation: "Intention"
        case .scripture: "Scripture"
        case .voice: "Reflection"
        case .complete: "Complete"
        }
    }
}

struct GuidedJournalFlowView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var isPresented: Bool
    var streakManager: StreakManager
    var userName: String
    var initialStep: GuidedJournalStep = .mood
    var onDevotionFinished: ((DevotionFinishResult) -> Void)? = nil
    var onOpenChaplainChat: ((String) -> Void)? = nil

    @AppStorage("intentionMood") private var intentionMood = "Peaceful"

    @State private var step: GuidedJournalStep
    @State private var draft = JournalDraft()
    @State private var stepRevealed = false
    @State private var completedStreak = 0
    @State private var finishResult: DevotionFinishResult?
    @State private var shouldCelebrate = false
    @State private var journalStartedAt = Date()
    @State private var editingMadLibField: MadLibField?

    private var journalElapsedSeconds: Int {
        Int(Date().timeIntervalSince(journalStartedAt))
    }

    private var dailyFocus: DailyFocus { DailyFocus.today }
    private let totalSteps = GuidedJournalStep.allCases.count

    private var flowProgress: CGFloat {
        CGFloat(step.progressIndex + 1) / CGFloat(totalSteps)
    }

    init(
        isPresented: Binding<Bool>,
        streakManager: StreakManager,
        userName: String,
        initialStep: GuidedJournalStep = .mood,
        onDevotionFinished: ((DevotionFinishResult) -> Void)? = nil,
        onOpenChaplainChat: ((String) -> Void)? = nil
    ) {
        _isPresented = isPresented
        self.streakManager = streakManager
        self.userName = userName
        self.initialStep = initialStep
        self.onDevotionFinished = onDevotionFinished
        self.onOpenChaplainChat = onOpenChaplainChat
        _step = State(initialValue: initialStep)
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
                    ABYGuidedJournalBackground()
                    DevotionCompletionView(
                        streak: completedStreak,
                        mood: draft.mood,
                        insight: draft.completionInsight,
                        onContinue: dismissFlow
                    )
                }
                .abyScreen()
                .transition(.opacity)
            } else {
                journalChrome
            }
        }
        .animation(AppTheme.springGentle, value: step)
        .onAppear {
            draft.mood = intentionMood
            draft.applyMoodDefaults()
            journalStartedAt = Date()
            withAnimation(AppTheme.onboardingStepIn) { stepRevealed = true }
            JournalLiveActivityManager.startDevotionIfAvailable()
            JournalLiveActivityManager.updateDevotion(step: step, elapsedSeconds: 0)
        }
        .onDisappear {
            JournalLiveActivityManager.end()
        }
        .onChange(of: step) { _, newStep in
            editingMadLibField = nil
            JournalLiveActivityManager.updateDevotion(
                step: newStep,
                elapsedSeconds: journalElapsedSeconds
            )
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
            ABYCleanGradientBackground()

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

                        ABYLightOnboardingPrimaryButton(
                            title: "Finished!",
                            isEnabled: draft.isMadLibsComplete,
                            action: advance
                        )
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 32)
                    }
                    .onboardingStepReveal(stepRevealed)
                } else if step == .gratitude || step == .affirmation {
                    VStack(spacing: 0) {
                        ScrollView(showsIndicators: false) {
                            stepContent
                                .padding(.horizontal, ABY.Spacing.screen)
                                .padding(.bottom, 16)
                                .onboardingStepReveal(stepRevealed)
                        }
                        .scrollDismissesKeyboard(.interactively)

                        flowBottomCTA
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.bottom, 32)
                            .onboardingStepReveal(stepRevealed)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        stepContent
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.bottom, 24)
                            .onboardingStepReveal(stepRevealed)
                    }

                    flowBottomCTA
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 32)
                        .onboardingStepReveal(stepRevealed)
                }
            }
        }
        .environment(\.onboardingSurface, .light)
        .environment(\.abyJournalOnboardingStyle, .warmSunset)
        .abyScreen()
        .sheet(item: $editingMadLibField) { field in
            ABYMadLibEditSheet(
                field: field,
                text: binding(for: field),
                onDone: { editingMadLibField = nil }
            )
        }
    }

    private var flowTopBar: some View {
        VStack(spacing: 14) {
            ABYThinProgressBar(progress: flowProgress)
            ABYGuidedJournalStepLabel(
                stepTitle: step.stepTitle,
                stepIndex: step.progressIndex + 1,
                totalSteps: totalSteps
            )
            HStack {
                if step != .mood {
                    ABYIconButton(icon: "chevron.left") { goBack() }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
                Spacer()
                Button(action: dismissFlow) {
                    Image(systemName: "xmark")
                        .font(ABY.Font.calloutSemibold)
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
            FocusTagsStepView(selectedTags: $draft.focusTags, appeared: stepRevealed)
        case .madLibs:
            madLibsStep
        case .gratitude:
            GratitudeStepView(items: $draft.gratitudeItems, appeared: stepRevealed)
        case .affirmation:
            AffirmationStepView(affirmation: $draft.affirmation, appeared: stepRevealed)
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
                subtitle: "No perfect words needed. Just what's true right now."
            )

            ABYGuidedMoodGrid(selectedMood: $draft.mood) { label in
                withAnimation(AppTheme.springSnappy) {
                    draft.mood = label
                    draft.emotion = label.lowercased()
                    intentionMood = label
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
            .padding(.bottom, 28)

            MadLibInlineSentence(draft: $draft) { field in
                editingMadLibField = field
            }
        }
    }

    private var scriptureStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            ABYHeadline(
                title: "Pause with Scripture",
                subtitle: "Tap the words that speak to you, then share a short reflection."
            )

            BlackoutVerseView(
                verse: dailyFocus.verse,
                reference: dailyFocus.reference,
                savedPhrase: $draft.savedVersePhrase
            )

            ABYGuidedVoiceHandoffCard(
                savedPhrase: draft.savedVersePhrase,
                mood: draft.mood
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
            ABYPrimaryButton(
                title: "Speak your reflection",
                icon: "mic.fill",
                action: advance
            )
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

    private func goBack() {
        OnboardingStepTransition.animateChange(revealed: $stepRevealed) {
            if let previous = GuidedJournalStep(rawValue: step.rawValue - 1) {
                step = previous
            }
        }
    }

    private func advance() {
        editingMadLibField = nil
        OnboardingStepTransition.animateChange(revealed: $stepRevealed) {
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

/// ABY mad-libs: inline sentence with solid / dashed pills (Mobbin ref).
struct MadLibInlineSentence: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var draft: JournalDraft
    var onEditField: (MadLibField) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            inlineLine(field: .emotion, value: draft.emotion)
            inlineLine(field: .reason, value: draft.reason)
            inlineLine(field: .onMind, value: draft.onMind)
            inlineLine(field: .plans, value: draft.plans)
        }
        .font(ABY.Font.body)
        .foregroundStyle(palette.textPrimary)
        .lineSpacing(8)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func inlineLine(field: MadLibField, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(field.prefix)
                .foregroundStyle(palette.textPrimary)

            MadLibInlinePill(field: field, value: value, onTap: { onEditField(field) })

            if field != .plans {
                Text(".")
                    .foregroundStyle(palette.textPrimary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct MadLibInlinePill: View {
    let field: MadLibField
    let value: String
    let onTap: () -> Void

    private var trimmed: String { value.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isFilled: Bool { !trimmed.isEmpty }

    var body: some View {
        Button(action: onTap) {
            Text(isFilled ? trimmed : field.inlinePlaceholder)
                .font(ABY.Font.bodyMedium)
                .foregroundStyle(isFilled ? field.color : field.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(isFilled ? field.color.opacity(0.14) : field.color.opacity(0.08))
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            field.color.opacity(isFilled ? 0.9 : 0.75),
                            style: isFilled
                                ? StrokeStyle(lineWidth: 1.5)
                                : StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GuidedJournalFlowView(
        isPresented: .constant(true),
        streakManager: .shared,
        userName: "Alex"
    )
}
