//
//  MorningFlowView.swift
//  DevotionLock
//
//  Adaptive morning devotion — tier-aware choreography, mood check-in,
//  guided prayer or reflection, then a word to carry into the day.
//

import SwiftUI

struct MorningFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    var streakManager: StreakManager
    var userName: String
    var initialMorningPath: MorningPath = .reflect
    var initialStep: MorningStep? = nil
    var onDevotionFinished: ((DevotionFinishResult) -> Void)? = nil
    var onOpenChaplainChat: ((String) -> Void)? = nil

    @State private var profile = MorningProfile.shared
    @AppStorage("intentionMood") private var intentionMood = "Peaceful"

    @State private var stepIndex = 0
    @State private var tier: MorningTier = .standard
    @State private var mood = "Peaceful"
    @State private var selectedTag: FocusTag?
    @State private var promptResponse = ""
    @State private var gratitudeLine = ""
    @State private var passage: SpiritualPassage = SpiritualPassageCatalog.today

    @State private var voiceMode: VoiceMode?
    @State private var showPassageSearch = false

    @State private var finishResult: DevotionFinishResult?
    @State private var completedStreak = 0
    @State private var shouldCelebrate = false
    @State private var appeared = false
    @State private var stepRevealed = false
    @State private var morningPath: MorningPath = .pray
    @State private var committedPath: MorningPath?
    @State private var showGuidedPrayer = false
    @State private var showReflection = false
    @State private var passageRevealed = false

    private var morningGuidedPrayer: GuidedPrayer {
        GuidedPrayerCatalog.all.first { $0.id == "morning" } ?? GuidedPrayerCatalog.all[0]
    }

    private enum VoiceMode: Identifiable {
        case depth
        var id: Int { hashValue }
    }

    private var flowPlan: MorningFlowPlan {
        MorningFlowPlan(tier: tier, path: committedPath ?? morningPath)
    }

    private var steps: [MorningStep] { flowPlan.steps }

    private var liturgyContext: LiturgyWeaveContext {
        LiturgyWeaveContext(mood: mood, focus: selectedTag, userName: userName, passage: passage)
    }

    private var currentStep: MorningStep {
        guard stepIndex < steps.count else { return .complete }
        return steps[stepIndex]
    }

    private var progress: CGFloat {
        if currentStep == .pulse, committedPath == nil {
            let maxSteps = MorningFlowPlan.maxStepCount(tier: tier)
            return CGFloat(stepIndex + 1) / CGFloat(maxSteps)
        }
        return flowPlan.progress(stepIndex: stepIndex)
    }

    private var stepCaptionParts: (current: Int, total: Int, title: String) {
        if currentStep == .pulse, committedPath == nil {
            return (stepIndex + 1, MorningFlowPlan.maxStepCount(tier: tier), "Check in")
        }
        let (current, total) = flowPlan.displayIndex(stepIndex: stepIndex)
        return (current, total, flowPlan.phaseLabel(for: currentStep))
    }

    private var tags: [FocusTag] { selectedTag.map { [$0] } ?? [] }

    var body: some View {
        Group {
            if currentStep == .complete {
                ZStack {
                    ABYBackground()
                    DevotionCompletionView(
                        streak: completedStreak,
                        mood: mood,
                        onContinue: dismissFlow
                    )
                }
                .abyScreen()
                .transition(.opacity)
            } else {
                ZStack {
                    ABYGuidedJournalBackground().ignoresSafeArea()

                    VStack(spacing: 0) {
                        topBar
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                        cardContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .id(currentStep)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 16)),
                                removal: .opacity.combined(with: .offset(y: -16))
                            ))

                        bottomBar
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.bottom, 32)
                    }
                }
                .environment(\.onboardingSurface, .light)
                .environment(\.abyJournalOnboardingStyle, .warmSunset)
                .abyScreen()
            }
        }
        .animation(AppTheme.springGentle, value: stepIndex)
        .fullScreenCover(item: $voiceMode) { _ in
            RecordingSessionView(
                isPresented: Binding(get: { voiceMode != nil }, set: { if !$0 { voiceMode = nil } }),
                initialPrompt: "What else is on your heart?",
                onComplete: { transcript in
                    handleVoiceComplete(transcript: transcript)
                },
                onSwitchToChat: { transcript in
                    voiceMode = nil
                    finalizeAndOpenChat(transcript.trimmingCharacters(in: .whitespacesAndNewlines))
                },
                voiceTranscript: nil,
                saveOnlyLabel: "Save without chat"
            )
        }
        .sheet(isPresented: $showPassageSearch) {
            PassageSearchView(initialTopics: SpiritualPassageCatalog.matchingTopics(mood: mood, focusTags: tags)) { chosen in
                passage = chosen
                showPassageSearch = false
            }
        }
        .fullScreenCover(isPresented: $showGuidedPrayer, onDismiss: {
            if currentStep == .pulse {
                committedPath = nil
            }
        }) {
            ThresholdPrayerFlowView(
                prayer: morningGuidedPrayer,
                prayerBeats: LiturgyWeaveBuilder.repeatablePrayerBeats(
                    prayer: morningGuidedPrayer,
                    context: liturgyContext
                ),
                onComplete: handleGuidedPrayerComplete
            )
        }
        .fullScreenCover(isPresented: $showReflection) {
            GuidedJournalEntryView(
                navigationTitle: "Morning devotion",
                seedPrompt: currentPrompt,
                text: $promptResponse,
                starterPhrases: [
                    "This morning I'm…",
                    "I'm grateful for…",
                    "I'm asking God for…",
                ],
                showsShuffle: false,
                allowsEmptyFinish: true,
                onSave: { saved in
                    promptResponse = saved
                    profile.noteInputChoice(saved.isEmpty ? .unset : .type)
                    handleReflectionComplete()
                }
            )
        }
        .onAppear {
            mood = intentionMood
            tier = profile.preferredTier
            selectedTag = profile.dominantTags.first
            morningPath = initialMorningPath == .reflect ? .reflect : profile.preferredPath
            committedPath = nil
            if initialMorningPath == .pray {
                passage = SpiritualPassageCatalog.recommended(
                    mood: mood,
                    focusTags: tags,
                    excludingIDs: profile.recentlySeen
                )
            }
            if let initialStep, let index = steps.firstIndex(of: initialStep) {
                stepIndex = index
            }
            withAnimation(AppTheme.springGentle) { appeared = true }
            revealStep()
        }
        .onChange(of: currentStep) { _, step in
            revealStep()
            if step == .reveal {
                passageRevealed = false
                withAnimation(AppTheme.springGentle.delay(0.12)) {
                    passageRevealed = true
                }
            }
            if step == .prompt {
                showReflection = true
            }
        }
    }

    private func revealStep() {
        stepRevealed = false
        withAnimation(AppTheme.onboardingStepIn) { stepRevealed = true }
    }

    // MARK: - Chrome

    private var topBar: some View {
        VStack(spacing: 14) {
            ABYThinProgressBar(progress: progress)
            ABYGuidedJournalStepLabel(
                stepTitle: stepCaptionParts.title,
                stepIndex: stepCaptionParts.current,
                totalSteps: stepCaptionParts.total
            )
            HStack {
                if stepIndex > 0 {
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
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var cardContent: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                switch currentStep {
                case .arrival: arrivalCard
                case .pulse: pulseCard
                case .prompt:
                    Color.clear.frame(height: 1)
                case .reveal: revealCard
                case .depth: depthCard
                case .complete: EmptyView()
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .onboardingStepReveal(stepRevealed)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var bottomBar: some View {
        switch currentStep {
        case .arrival:
            ABYLightOnboardingPrimaryButton(title: "Step in", action: advance)
        case .pulse:
            EmptyView()
        case .prompt:
            EmptyView()
        case .reveal:
            ABYLightOnboardingPrimaryButton(
                title: tier.includesDepth ? "Carry this forward" : "Finish morning",
                action: advance
            )
        case .depth:
            VStack(spacing: 10) {
                ABYLightOnboardingPrimaryButton(title: "Finish morning", action: advance)
                Button(action: advance) {
                    Text("Skip for now")
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        case .complete:
            EmptyView()
        }
    }

    // MARK: - Arrival

    private var arrivalCard: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 12) {
                Text(profile.greeting(name: userName))
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(arrivalSubtitle)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(5)
            }

            if streakManager.currentStreak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(ABY.Font.captionSemibold)
                        .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.22))
                    Text("\(streakManager.currentStreak) mornings in a row")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Pace for today")
                    .font(ABY.Font.section)
                    .tracking(0.8)
                    .foregroundStyle(palette.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: 8) {
                    ForEach(MorningTier.allCases) { option in
                        MorningTierChip(tier: option, isSelected: tier == option) {
                            withAnimation(AppTheme.springSnappy) { tier = option }
                            DevotionHaptics.light()
                        }
                    }
                }
            }

            Text(tier.subtitle)
                .font(ABY.Font.caption)
                .foregroundStyle(palette.isNight ? palette.textSecondary : palette.textTertiary)

            Spacer(minLength: 12)
        }
    }

    private var arrivalSubtitle: String {
        if profile.isReturning, let mood = profile.dominantMood {
            return "You've been showing up \(mood.lowercased()) lately. Let's meet today as it is."
        }
        return "Let's take a few quiet minutes before the day begins."
    }

    // MARK: - Pulse (mood + one focus)

    private var pulseCard: some View {
        VStack(alignment: .leading, spacing: 28) {
            ABYHeadline(
                title: "How are you?",
                subtitle: "No perfect words — just what's true before the day begins."
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Your heart")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)

                ABYGuidedMoodGrid(selectedMood: $mood) { label in
                    withAnimation(AppTheme.springSnappy) {
                        mood = label
                        intentionMood = label
                    }
                    Task { await UserPreferencesSync.shared.pushPreferences(intentionMood: label) }
                    DevotionHaptics.light()
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("In focus today")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
                Text("Optional — one thing to hold gently")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.isNight ? palette.textSecondary : palette.textTertiary)

                FlowChips(items: FocusTag.allCases.map(\.rawValue)) { raw in
                    let tag = FocusTag(rawValue: raw)!
                    MorningChip(
                        label: tag.label,
                        icon: tag.icon,
                        isSelected: selectedTag == tag
                    ) {
                        withAnimation(AppTheme.springSnappy) {
                            selectedTag = (selectedTag == tag) ? nil : tag
                        }
                        DevotionHaptics.light()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Meet God through")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)

                VStack(spacing: 10) {
                    MorningPathCard(
                        path: .pray,
                        isRecommended: profile.preferredPath == .pray,
                        action: { chooseMorningPath(.pray) }
                    )
                    MorningPathCard(
                        path: .reflect,
                        isRecommended: profile.preferredPath == .reflect,
                        action: { chooseMorningPath(.reflect) }
                    )
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Prompt (GuidedJournalEntryView full-screen)

    private var currentPrompt: String {
        profile.openPrompt(mood: mood, tags: tags)
    }

    // MARK: - Reveal

    private var revealCard: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 16)

            VStack(spacing: 10) {
                MoodPill(label: mood)
                Text(passage.source == .scripture ? "For you today" : "A word for today")
                    .font(ABY.Font.section)
                    .tracking(1.4)
                    .foregroundStyle(palette.textSecondary)
                    .textCase(.uppercase)
            }

            Text(passage.text)
                .font(ABY.Font.editorialTitle)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .fixedSize(horizontal: false, vertical: true)
                .blurReveal(passageRevealed, blurRadius: 8, scale: 1.01)
                .padding(.horizontal, 8)

            Text(passage.attribution)
                .font(ABY.Font.calloutMedium)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Text("Carry with you")
                    .font(ABY.Font.section)
                    .tracking(1.2)
                    .foregroundStyle(palette.textTertiary)
                    .textCase(.uppercase)

                Text(profile.affirmation(mood: mood, tags: tags))
                    .font(ABY.Font.bodyMedium)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(palette.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .blurReveal(passageRevealed, blurRadius: 6, scale: 1.005)

            Button {
                showPassageSearch = true
            } label: {
                Text("Find another passage")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textTertiary)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 16)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Depth

    private var depthCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            ABYHeadline(
                title: "Stay a little longer",
                subtitle: "Only if you have capacity — there's no extra credit here."
            )

            DepthOptionRow(icon: "waveform", title: "Speak it out", subtitle: "Pray aloud with your Chaplain") {
                voiceMode = .depth
            }
            DepthOptionRow(icon: "bubble.left.and.bubble.right.fill", title: "Talk it through", subtitle: "Open a chat from where you are") {
                finalizeAndOpenChat(promptResponse.isEmpty ? currentPrompt : promptResponse)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Or name one thing you're grateful for")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
                TextField("This morning I'm grateful for…", text: $gratitudeLine, axis: .vertical)
                    .lineLimit(1...3)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textPrimary)
                    .tint(palette.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(palette.cardFill)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
                    .overlay(RoundedRectangle(cornerRadius: ABY.Radius.card).stroke(palette.divider, lineWidth: 1))
            }
        }
    }

    // MARK: - Navigation

    private func chooseMorningPath(_ path: MorningPath) {
        DevotionHaptics.medium()
        committedPath = path
        morningPath = path
        profile.notePathChoice(path)
        passage = SpiritualPassageCatalog.recommended(
            mood: mood,
            focusTags: tags,
            excludingIDs: profile.recentlySeen
        )
        if path == .pray {
            showGuidedPrayer = true
        } else {
            advance()
        }
    }

    private func handleReflectionComplete() {
        profile.notePathChoice(.reflect)
        TodayFocusStore.save(tags.map(\.rawValue))
        JourneyTimelineStore.shared.logMood(mood, tags: tags)
        if !promptResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            JourneyTimelineStore.shared.add(JourneyTimelineEntry(
                kind: .reflection,
                title: "Morning reflection",
                body: promptResponse
            ))
        }
        showReflection = false
        advance()
    }

    private func handleGuidedPrayerComplete() {
        let beats = LiturgyWeaveBuilder.repeatablePrayerBeats(
            prayer: morningGuidedPrayer,
            context: liturgyContext
        )
        JourneyTimelineStore.shared.add(JourneyTimelineEntry(
            kind: .reflection,
            title: "Morning prayer",
            body: beats.map(\.fullText).joined(separator: " ")
        ))
        advance()
        showGuidedPrayer = false
    }

    private func goBack() {
        withAnimation(AppTheme.springSnappy) {
            if currentStep == .prompt {
                showReflection = false
            }
            if currentStep == .reveal, committedPath == .pray {
                committedPath = nil
            }
            if stepIndex > 0 { stepIndex -= 1 }
        }
    }

    private func advance() {
        let nextIndex = stepIndex + 1
        guard nextIndex < steps.count else { return }

        if steps[stepIndex] == .pulse {
            // Choose the passage as we leave the pulse → prompt boundary so reveal is ready.
            passage = SpiritualPassageCatalog.recommended(
                mood: mood,
                focusTags: tags,
                excludingIDs: profile.recentlySeen
            )
        }

        if steps[nextIndex] == .complete {
            finalize()
            return
        }
        withAnimation(AppTheme.springSnappy) { stepIndex = nextIndex }
    }

    // MARK: - Voice handling

    private func handleVoiceComplete(transcript: String) {
        let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        voiceMode = nil
        if !spoken.isEmpty {
            gratitudeLine = gratitudeLine.isEmpty ? spoken : gratitudeLine
        }
        finalize()
    }

    // MARK: - Completion

    private func buildDraft() -> JournalDraft {
        var draft = JournalDraft()
        draft.mood = mood
        draft.emotion = mood.lowercased()
        draft.focusTags = tags.map(\.rawValue)
        draft.onMind = promptResponse
        draft.affirmation = profile.affirmation(mood: mood, tags: tags)
        draft.savedVersePhrase = passage.text
        if !gratitudeLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft.gratitudeItems = [gratitudeLine, "", ""]
        }
        draft.reflectionText = promptResponse
        return draft
    }

    private func recordCompletion() {
        let draft = buildDraft()
        let summary = DaySummary.from(draft: draft, verseReference: passage.reference)
        let wasAlreadyComplete = streakManager.isCompletedToday
        finishResult = streakManager.recordDevotion(mood: mood, summary: summary)
        shouldCelebrate = !wasAlreadyComplete
        completedStreak = finishResult?.streak ?? streakManager.currentStreak

        DailyRhythmStore.shared.markComplete(.morningDevotion)
        JourneyTimelineStore.shared.logDevotion(summary: summary, draft: draft)
        TodayFocusStore.save(draft.focusTags)
        profile.recordCompletion(mood: mood, tags: tags, passageID: passage.id, tier: tier)
        Task {
            await DevotionSessionRepository.shared.syncCompletion(
                draft: draft,
                verseReference: passage.reference,
                summary: summary
            )
        }
        AppShieldManager.shared.unlockForCompletedDevotion()
        PersonalInsightStore.shared.refresh()
    }

    private func finalize() {
        recordCompletion()
        withAnimation(AppTheme.springGentle) {
            stepIndex = steps.count - 1
        }
    }

    private func finalizeAndOpenChat(_ seed: String) {
        recordCompletion()
        dismiss()
        if shouldCelebrate, let finishResult {
            onDevotionFinished?(finishResult)
        }
        onOpenChaplainChat?(seed)
    }

    private func dismissFlow() {
        if shouldCelebrate, let finishResult {
            onDevotionFinished?(finishResult)
        }
        withAnimation(AppTheme.springSnappy) { dismiss() }
    }
}

// MARK: - Components

private struct MorningTierChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let tier: MorningTier
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tier.icon)
                    .font(ABY.Font.captionSemibold)
                Text(tier.title)
                    .font(ABY.Font.captionMedium)
                Text(tier.minutesLabel)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? palette.buttonForeground.opacity(0.75) : palette.textTertiary)
            }
            .foregroundStyle(isSelected ? palette.buttonForeground : palette.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? palette.buttonFill : (palette.isNight ? palette.cardFill : palette.surface))
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.card, style: .continuous)
                    .stroke(isSelected ? Color.clear : palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct MorningPathCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let path: MorningPath
    var isRecommended: Bool = false
    let action: () -> Void

    private var title: String {
        switch path {
        case .pray: "Guided prayer"
        case .reflect: "Journal reflection"
        }
    }

    private var subtitle: String {
        switch path {
        case .pray: "Breath, orb, and words woven to your morning"
        case .reflect: "Type or speak — saved with today's devotion"
        }
    }

    private var icon: String {
        switch path {
        case .pray: "hands.sparkles"
        case .reflect: "square.and.pencil"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(ABY.Color.pillTeal)
                    .frame(width: 40, height: 40)
                    .background(ABY.Color.pillTeal.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(ABY.Font.bodySemibold)
                            .foregroundStyle(palette.textPrimary)
                        if isRecommended {
                            Text("Usual")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(palette.isNight ? .white : ABY.Color.pillTeal)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    palette.isNight
                                        ? ABY.Color.pillTeal.opacity(0.72)
                                        : ABY.Color.pillTeal.opacity(0.12)
                                )
                                .clipShape(Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.right")
                    .font(ABY.Font.footnoteSemibold)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(16)
            .background(palette.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(isRecommended ? ABY.Color.pillTeal.opacity(0.35) : palette.divider, lineWidth: isRecommended ? 1.5 : 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct MorningChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(ABY.Font.captionSemibold)
                Text(label)
                    .font(ABY.Font.captionMedium)
            }
            .foregroundStyle(isSelected ? palette.buttonForeground : palette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? palette.buttonFill : (palette.isNight ? palette.cardFill : palette.surface))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : palette.divider, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct DepthOptionRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(palette.textPrimary)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ABY.Font.bodySemibold)
                        .foregroundStyle(palette.textPrimary)
                    Text(subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(ABY.Font.footnoteSemibold)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(palette.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: ABY.Radius.card).stroke(palette.divider, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Simple wrapping chip layout.
struct FlowChips<Chip: View>: View {
    let items: [String]
    @ViewBuilder let chip: (String) -> Chip

    var body: some View {
        FlexibleWrap(items: items, spacing: 8, lineSpacing: 8) { item in
            chip(item)
        }
    }
}

struct FlexibleWrap<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let spacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geo in
            generate(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generate(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geo.size.width {
                            width = 0
                            height -= dimension.height + lineSpacing
                        }
                        let result = width
                        if item == items.reversed().first {
                            width = 0
                        } else {
                            width -= dimension.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.reversed().first {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(heightReader)
    }

    private var heightReader: some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async {
                totalHeight = geo.size.height
            }
            return Color.clear
        }
    }
}

#Preview {
    MorningFlowView(
        streakManager: .shared,
        userName: "Alex"
    )
}
