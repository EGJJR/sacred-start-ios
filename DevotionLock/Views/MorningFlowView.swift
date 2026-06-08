//
//  MorningFlowView.swift
//  DevotionLock
//
//  Adaptive, card-based morning devotion. Replaces the fixed multi-step
//  GuidedJournalFlowView. Content branches on the chosen tier, mood, and
//  focus, and personalizes over time via MorningProfile.
//

import SwiftUI

enum MorningStep: Equatable {
    case arrival
    case pulse
    case prompt
    case reveal
    case depth
    case complete
}

struct MorningFlowView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var isPresented: Bool
    var streakManager: StreakManager
    var userName: String
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
    @FocusState private var promptFocused: Bool

    @State private var finishResult: DevotionFinishResult?
    @State private var completedStreak = 0
    @State private var shouldCelebrate = false
    @State private var appeared = false

    private enum VoiceMode: Identifiable {
        case prompt
        case depth
        var id: Int { hashValue }
    }

    private var steps: [MorningStep] {
        var result: [MorningStep] = [.arrival, .pulse, .prompt, .reveal]
        if tier.includesDepth { result.append(.depth) }
        result.append(.complete)
        return result
    }

    private var currentStep: MorningStep {
        guard stepIndex < steps.count else { return .complete }
        return steps[stepIndex]
    }

    private var progress: CGFloat {
        CGFloat(stepIndex + 1) / CGFloat(steps.count)
    }

    private var tags: [FocusTag] { selectedTag.map { [$0] } ?? [] }

    var body: some View {
        ZStack {
            ABYCleanGradientBackground().ignoresSafeArea()

            if currentStep == .complete {
                DevotionCompletionView(
                    streak: completedStreak,
                    mood: mood,
                    onContinue: dismissFlow
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.top, 8)

                    cardContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id(currentStep)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 16)),
                            removal: .opacity.combined(with: .offset(y: -16))
                        ))

                    bottomBar
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 28)
                }
            }
        }
        .animation(AppTheme.springGentle, value: stepIndex)
        .fullScreenCover(item: $voiceMode) { mode in
            RecordingSessionView(
                isPresented: Binding(get: { voiceMode != nil }, set: { if !$0 { voiceMode = nil } }),
                initialPrompt: mode == .prompt ? currentPrompt : "What else is on your heart?",
                onComplete: { transcript in
                    handleVoiceComplete(mode: mode, transcript: transcript)
                },
                onSwitchToChat: { transcript in
                    voiceMode = nil
                    let seed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    if mode == .prompt, !seed.isEmpty { promptResponse = seed }
                    finalizeAndOpenChat(seed)
                },
                voiceTranscript: nil,
                saveOnlyLabel: mode == .prompt ? "Use in my answer only" : "Save without chat"
            )
        }
        .sheet(isPresented: $showPassageSearch) {
            PassageSearchView(initialTopics: SpiritualPassageCatalog.matchingTopics(mood: mood, focusTags: tags)) { chosen in
                passage = chosen
                showPassageSearch = false
            }
        }
        .onAppear {
            mood = intentionMood
            tier = profile.preferredTier
            selectedTag = profile.dominantTags.first
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { promptFocused = false }
                    .font(ABY.Font.body.weight(.medium))
            }
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        VStack(spacing: 14) {
            ABYThinProgressBar(progress: progress)
            HStack {
                if stepIndex > 0 {
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
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var cardContent: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                switch currentStep {
                case .arrival: arrivalCard
                case .pulse: pulseCard
                case .prompt: promptCard
                case .reveal: revealCard
                case .depth: depthCard
                case .complete: EmptyView()
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var bottomBar: some View {
        switch currentStep {
        case .arrival:
            ABYPrimaryButton(title: "Begin", icon: "arrow.right", action: advance)
        case .pulse:
            ABYPrimaryButton(title: "Continue", icon: "arrow.right", action: advance)
        case .prompt:
            VStack(spacing: 12) {
                ABYPrimaryButton(title: promptResponse.isEmpty ? "Skip for now" : "Continue", icon: "arrow.right", action: advanceFromPrompt)
            }
        case .reveal:
            ABYPrimaryButton(
                title: tier.includesDepth ? "Go deeper" : "Finish",
                icon: tier.includesDepth ? "arrow.down" : "checkmark",
                action: advance
            )
        case .depth:
            ABYPrimaryButton(title: "Finish", icon: "checkmark", action: advance)
        case .complete:
            EmptyView()
        }
    }

    // MARK: - Arrival

    private var arrivalCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 10) {
                Text(profile.greeting(name: userName))
                    .font(ABY.Font.onboardingTitle)
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(arrivalSubtitle)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(4)
            }

            if streakManager.currentStreak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.22))
                    Text("\(streakManager.currentStreak) day streak")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(palette.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("How much time this morning?")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)

                VStack(spacing: 10) {
                    ForEach(MorningTier.allCases) { option in
                        MorningTierRow(tier: option, isSelected: tier == option) {
                            withAnimation(AppTheme.springSnappy) { tier = option }
                            DevotionHaptics.light()
                        }
                    }
                }
            }
            .padding(.top, 4)

            Spacer(minLength: 8)
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
        VStack(alignment: .leading, spacing: 24) {
            ABYHeadline(title: "How are you arriving?", subtitle: "One word for your heart, and one thing in focus.")

            VStack(alignment: .leading, spacing: 12) {
                Text("Mood")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
                FlowChips(items: MoodCatalog.options.map(\.label)) { label in
                    MorningChip(
                        label: label,
                        icon: MoodCatalog.icon(for: label),
                        isSelected: mood == label
                    ) {
                        withAnimation(AppTheme.springSnappy) {
                            mood = label
                            intentionMood = label
                        }
                        Task { await UserPreferencesSync.shared.pushPreferences(intentionMood: label) }
                        DevotionHaptics.light()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("In focus today")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
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
        }
    }

    // MARK: - Prompt

    private var currentPrompt: String {
        profile.openPrompt(mood: mood, tags: tags)
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("A question to sit with")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
                Text(currentPrompt)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.textPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button {
                    profile.noteInputChoice(.type)
                    promptFocused = true
                } label: {
                    inputModeLabel(icon: "keyboard", title: "Type")
                }
                .buttonStyle(.plain)

                Button {
                    profile.noteInputChoice(.speak)
                    promptFocused = false
                    voiceMode = .prompt
                } label: {
                    inputModeLabel(icon: "waveform", title: "Speak")
                }
                .buttonStyle(.plain)
            }

            ZStack(alignment: .topLeading) {
                if promptResponse.isEmpty {
                    Text("Let your honest answer land here…")
                        .font(ABY.Font.body)
                        .foregroundStyle(palette.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }
                TextEditor(text: $promptResponse)
                    .focused($promptFocused)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 150)
            }
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(promptFocused ? palette.textSecondary : palette.divider, lineWidth: promptFocused ? 1.5 : 1)
            }
        }
    }

    private func inputModeLabel(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(ABY.Font.captionMedium)
        .foregroundStyle(palette.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(palette.surfaceMuted)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
    }

    // MARK: - Reveal

    private var revealCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: passage.source == .scripture ? "book.closed.fill" : "quote.opening")
                        .font(.system(size: 11, weight: .semibold))
                    Text(passage.source == .scripture ? "For you today" : "A word for today")
                        .font(ABY.Font.section)
                        .tracking(0.6)
                }
                .foregroundStyle(palette.textSecondary)
            }

            Text(passage.text)
                .font(.system(size: 26, weight: .regular, design: .serif))
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)

            Text(passage.attribution)
                .font(ABY.Font.callout.weight(.medium))
                .foregroundStyle(palette.textSecondary)

            Divider().overlay(palette.divider)

            VStack(alignment: .leading, spacing: 8) {
                Text("Carry this with you")
                    .font(ABY.Font.section)
                    .tracking(0.6)
                    .foregroundStyle(palette.textSecondary)
                Text(profile.affirmation(mood: mood, tags: tags))
                    .font(ABY.Font.body.weight(.medium))
                    .foregroundStyle(palette.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))

            Button {
                showPassageSearch = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                    Text("Find another passage")
                }
                .font(ABY.Font.captionMedium)
                .foregroundStyle(palette.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)
        }
    }

    // MARK: - Depth

    private var depthCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            ABYHeadline(title: "Stay a little longer", subtitle: "Optional — go as deep as you'd like this morning.")

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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
                    .overlay(RoundedRectangle(cornerRadius: ABY.Radius.card).stroke(palette.divider, lineWidth: 1))
            }
        }
    }

    // MARK: - Navigation

    private func goBack() {
        promptFocused = false
        withAnimation(AppTheme.springSnappy) {
            if stepIndex > 0 { stepIndex -= 1 }
        }
    }

    private func advance() {
        promptFocused = false
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

    private func advanceFromPrompt() {
        TodayFocusStore.save(tags.map(\.rawValue))
        JourneyTimelineStore.shared.logMood(mood, tags: tags)
        advance()
    }

    // MARK: - Voice handling

    private func handleVoiceComplete(mode: VoiceMode, transcript: String) {
        let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        voiceMode = nil
        switch mode {
        case .prompt:
            if !spoken.isEmpty { promptResponse = spoken }
            advanceFromPrompt()
        case .depth:
            if !spoken.isEmpty {
                gratitudeLine = gratitudeLine.isEmpty ? spoken : gratitudeLine
            }
            finalize()
        }
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
        isPresented = false
        if shouldCelebrate, let finishResult {
            onDevotionFinished?(finishResult)
        }
        onOpenChaplainChat?(seed)
    }

    private func dismissFlow() {
        if shouldCelebrate, let finishResult {
            onDevotionFinished?(finishResult)
        }
        withAnimation(AppTheme.springSnappy) { isPresented = false }
    }
}

// MARK: - Components

private struct MorningTierRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let tier: MorningTier
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: tier.icon)
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(isSelected ? palette.textPrimary : palette.textSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(tier.title)
                            .font(ABY.Font.body.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)
                        Text(tier.minutesLabel)
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textTertiary)
                    }
                    Text(tier.subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
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
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(ABY.Font.captionMedium)
            }
            .foregroundStyle(isSelected ? palette.buttonForeground : palette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? palette.buttonFill : palette.surface)
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
                        .font(ABY.Font.body.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)
                    Text(subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(palette.surface)
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
        isPresented: .constant(true),
        streakManager: .shared,
        userName: "Alex"
    )
}
