//
//  AIInsightsView.swift
//  DevotionLock
//
//  Mobbin ChatGPT hub: https://mobbin.com/screens/a99dfac5-4d3c-4c7e-8e50-1db1d9ef9afd
//  Mobbin Copilot recents: https://mobbin.com/screens/40046f7b-1621-4099-a9e9-76910e645eb3
//

import SwiftUI

private enum InsightsSheet: Identifiable {
    case chatHistory
    case passageSearch

    var id: String {
        switch self {
        case .chatHistory: "chat-history"
        case .passageSearch: "passage-search"
        }
    }
}

struct AIInsightsView: View {
    @Environment(\.openChaplainChat) private var openChaplainChat
    @Environment(\.openChaplainChatWithPortal) private var openChaplainChatWithPortal
    @Environment(\.resumeChaplainChat) private var resumeChaplainChat
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @Environment(\.sanctuaryPalette) private var palette
    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"
    @State private var appeared = false
    @State private var insightsSheet: InsightsSheet?
    @State private var showGuidedPrayerPicker = false
    @State private var showWisdomReflection = false
    @State private var guidedPrayerLaunch: GuidedPrayerLaunch?
    @State private var pendingGuidedPrayerLaunch: GuidedPrayerLaunch?
    @State private var wisdomPrompt = "What is God inviting you to notice today?"
    @State private var ambientInsight: PersonalInsight?
    @State private var companionMemory: AmbientEmpathy.CompanionMemory?
    @AppStorage("intentionMood") private var intentionMood = "Peaceful"
    private let chaplainSession = ChaplainSessionStore.shared
    private let conversationRepository = ConversationRepository.shared
    private let insightStore = PersonalInsightStore.shared

    private var selectedVoice: ChaplainVoice {
        ChaplainVoice.options.first { $0.id == selectedVoiceID } ?? ChaplainVoice.options[0]
    }

    var body: some View {
        ABYFadingHeaderScrollView(
            title: "Chaplain",
            subtitle: greetingSubtitle,
            trailing: {
                Button(action: { insightsSheet = .chatHistory }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(ABY.Font.bodyMedium)
                        .foregroundStyle(palette.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(palette.composerFill)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(palette.divider.opacity(0.5), lineWidth: 1))
                        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 6, y: 2)
                        .contentShape(Circle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Chat history")
            }
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 12)

                if let ambientInsight {
                    PersonalInsightCard(insight: ambientInsight) {
                        dismissAmbientInsight()
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 16)
                    .blurReveal(appeared, blurRadius: 4, scale: 1.003)
                }

                if let companionMemory {
                    ChaplainCompanionMemoryCard(
                        memory: companionMemory,
                        onKeepGoing: {
                            let prompt = companionMemory.keepGoingPrompt
                            AmbientEmpathy.dismissCompanionForSession()
                            self.companionMemory = nil
                            openChaplainChat(prompt, [])
                        },
                        onSomethingNew: {
                            dismissCompanionMemory()
                        }
                    )
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 16)
                    .blurReveal(appeared, blurRadius: 4, scale: 1.003)
                }

                GeminiChatGreeting()
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)
                    .blurReveal(appeared, blurRadius: 4, scale: 1.003)

                if let resumable = chaplainSession.resumableConversation {
                    ChaplainResumeBanner(title: resumable.title) {
                        chaplainSession.pendingResumeID = resumable.id
                        openChaplainChat(nil, [])
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 16)
                    .blurReveal(appeared, blurRadius: 4, scale: 1.003)
                }

                GeminiChatSuggestionRail { prompt in
                    openChaplainChat(prompt, [])
                }
                .padding(.bottom, 32)
                .blurReveal(appeared, blurRadius: 4, scale: 1.002)

                ChaplainExploreLinksCard(
                    onGuidedPrayer: { requirePremium { showGuidedPrayerPicker = true } },
                    onPassages: { requirePremium { insightsSheet = .passageSearch } },
                    onWisdom: { requirePremium { showWisdomReflection = true } }
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .blurReveal(appeared, blurRadius: 4, scale: 1.002)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChaplainComposeLauncher(voiceName: selectedVoice.name) {
                openChaplainChatWithPortal(selectedVoice.name, nil, [])
            }
            .ambientAIGlow()
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 88)
        }
        .sheet(item: $insightsSheet) { sheet in
            switch sheet {
            case .chatHistory:
                ChaplainChatHistoryView()
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            case .passageSearch:
                PassageSearchView()
            }
        }
        .task {
            await conversationRepository.refresh()
            refreshAmbientSurfaces()
        }
        .onAppear {
            refreshAmbientSurfaces()
            withAnimation(AppTheme.springGentle.delay(0.05)) { appeared = true }
        }
        .sheet(isPresented: $showGuidedPrayerPicker, onDismiss: {
            if let pending = pendingGuidedPrayerLaunch {
                guidedPrayerLaunch = pending
                pendingGuidedPrayerLaunch = nil
            }
        }) {
            GuidedPrayerPickerSheet { prayer, style in
                pendingGuidedPrayerLaunch = GuidedPrayerLaunch(prayer: prayer, style: style)
                showGuidedPrayerPicker = false
            }
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationDetents([.fraction(0.78), .large])
        }
        .fullScreenCover(item: $guidedPrayerLaunch) { launch in
            GuidedPrayerFlowView(
                prayer: launch.prayer,
                style: launch.style,
                weaveContext: LiturgyWeaveContext(mood: intentionMood, focus: nil, userName: "")
            ) {
                JourneyTimelineStore.shared.add(JourneyTimelineEntry(
                    kind: .reflection,
                    title: launch.prayer.title,
                    body: "Completed guided prayer · \(launch.style.title)"
                ))
            }
        }
        .fullScreenCover(isPresented: $showWisdomReflection) {
            WisdomReflectionView(
                prompt: wisdomPrompt,
                onSave: { text in
                    JourneyTimelineStore.shared.add(JourneyTimelineEntry(
                        kind: .reflection,
                        title: "Wisdom reflection",
                        body: text
                    ))
                },
                onExpandWithAI: { draft in
                    let seed = draft.isEmpty ? wisdomPrompt : draft
                    openChaplainChat("Expand this reflection with me: \"\(seed)\"", [])
                    showWisdomReflection = false
                }
            )
        }
    }

    private var greetingSubtitle: String {
        "A quiet place to talk and reflect"
    }

    private func requirePremium(_ action: @escaping () -> Void) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall, action: action)
    }

    private func refreshAmbientSurfaces() {
        insightStore.refresh()
        let snapshot = insightStore.snapshot
        // One ambient card at a time: insight first, companion memory only when no insight.
        if let insight = AmbientEmpathy.ambientInsight(from: snapshot) {
            ambientInsight = insight
            companionMemory = nil
        } else {
            ambientInsight = nil
            companionMemory = AmbientEmpathy.companionMemory(
                snapshot: snapshot,
                journey: JourneyTimelineStore.shared
            )
        }
    }

    private func dismissAmbientInsight() {
        AmbientEmpathy.dismissInsightForToday()
        withAnimation(AppTheme.springGentle) {
            ambientInsight = nil
            companionMemory = AmbientEmpathy.companionMemory(
                snapshot: insightStore.snapshot,
                journey: JourneyTimelineStore.shared
            )
        }
    }

    private func dismissCompanionMemory() {
        AmbientEmpathy.dismissCompanionForSession()
        withAnimation(AppTheme.springGentle) {
            companionMemory = nil
        }
    }
}

private struct GuidedPrayerLaunch: Identifiable {
    let id = UUID()
    let prayer: GuidedPrayer
    let style: GuidedPrayerExperienceStyle
}

private struct GuidedPrayerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    @State private var selectedStyle: GuidedPrayerExperienceStyle = .threshold
    let onSelect: (GuidedPrayer, GuidedPrayerExperienceStyle) -> Void

    /// Time-appropriate prayer surfaced as the hero card (Calm/Oura "for this moment" pattern).
    private var featuredPrayer: GuidedPrayer {
        let hour = Calendar.current.component(.hour, from: Date())
        let id: String
        switch hour {
        case 5..<11: id = "morning"
        case 11..<17: id = "gratitude"
        default: id = "evening"
        }
        return GuidedPrayerCatalog.all.first { $0.id == id } ?? GuidedPrayerCatalog.all[0]
    }

    private var featuredLabel: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "For this morning"
        case 11..<17: return "For this afternoon"
        default: return "For tonight"
        }
    }

    private var remainingPrayers: [GuidedPrayer] {
        GuidedPrayerCatalog.all.filter { $0.id != featuredPrayer.id }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ABYBackground(style: .tabShell).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        experiencePicker
                        featuredCard
                        prayerList
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Guided prayers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(ABY.Font.captionSemibold)
                            .foregroundStyle(palette.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(palette.composerFill)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(palette.divider.opacity(0.5), lineWidth: 1))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Close")
                }
            }
            .abyScreen()
        }
    }

    private var featuredCard: some View {
        let prayer = featuredPrayer
        let tint = prayer.tintColor

        return Button {
            DevotionHaptics.light()
            onSelect(prayer, selectedStyle)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Text(featuredLabel.uppercased())
                        .font(ABY.Font.section)
                        .tracking(0.8)
                        .foregroundStyle(palette.isNight ? tint.opacity(0.95) : tint)

                    Spacer(minLength: 8)

                    Image(systemName: prayer.icon)
                        .font(ABY.Font.bodyMedium)
                        .foregroundStyle(tint)
                        .frame(width: 36, height: 36)
                        .background(tint.opacity(palette.isNight ? 0.2 : 0.12))
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(prayer.title)
                        .font(ABY.Font.editorialTitle)
                        .foregroundStyle(palette.textPrimary)
                    Text(prayer.subtitle)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                }

                HStack(spacing: 6) {
                    Text("Begin")
                        .font(ABY.Font.captionSemibold)
                    Image(systemName: "arrow.right")
                        .font(ABY.Font.captionSemibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(tint.opacity(palette.isNight ? 0.85 : 1))
                .clipShape(Capsule())
            }
            .padding(ABY.Spacing.card + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .fill(palette.cardFill)
                    .overlay {
                        LinearGradient(
                            colors: [
                                tint.opacity(palette.isNight ? 0.26 : 0.14),
                                tint.opacity(palette.isNight ? 0.08 : 0.04),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .strokeBorder(tint.opacity(palette.isNight ? 0.4 : 0.25), lineWidth: 1)
            }
            .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 8, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, ABY.Spacing.screen)
        .accessibilityLabel("\(featuredLabel): \(prayer.title). \(prayer.subtitle)")
    }

    private var experiencePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Experience")
                .font(ABY.Font.section)
                .tracking(0.6)
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ABY.Spacing.screen + 4)

            HStack(spacing: 6) {
                ForEach(GuidedPrayerExperienceStyle.allCases) { style in
                    GuidedPrayerExperienceChip(
                        style: style,
                        isSelected: selectedStyle == style
                    ) {
                        withAnimation(AppTheme.springSnappy) { selectedStyle = style }
                        DevotionHaptics.light()
                    }
                }
            }
            .padding(4)
            .background(palette.isNight ? palette.surfaceMuted : ABY.Color.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .padding(.horizontal, ABY.Spacing.screen)
        }
    }

    private var prayerList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("More prayers")
                .font(ABY.Font.section)
                .tracking(0.6)
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ABY.Spacing.screen + 4)

            VStack(spacing: 0) {
                ForEach(Array(remainingPrayers.enumerated()), id: \.element.id) { index, prayer in
                    GuidedPrayerPickerRow(prayer: prayer) {
                        DevotionHaptics.light()
                        onSelect(prayer, selectedStyle)
                    }

                    if index < remainingPrayers.count - 1 {
                        Divider()
                            .padding(.leading, 64)
                            .allowsHitTesting(false)
                    }
                }
            }
            .background(palette.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .strokeBorder(palette.divider, lineWidth: 1)
            }
            .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 8, y: 2)
            .padding(.horizontal, ABY.Spacing.screen)
        }
    }
}

private struct GuidedPrayerExperienceChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let style: GuidedPrayerExperienceStyle
    let isSelected: Bool
    let action: () -> Void

    private var subtitleColor: Color {
        isSelected && palette.isNight ? palette.textSecondary : palette.textTertiary
    }

    private var selectedFill: Color {
        palette.isNight ? palette.cardFill : Color.white
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(style.title)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textPrimary)
                Text(style.subtitle)
                    .font(ABY.Font.micro)
                    .foregroundStyle(subtitleColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: ABY.Radius.chip + 2, style: .continuous)
                        .fill(selectedFill)
                        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 6, y: 2)
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: ABY.Radius.chip + 2, style: .continuous)
                        .strokeBorder(ABY.Color.pillTeal.opacity(palette.isNight ? 0.5 : 0.35), lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct GuidedPrayerPickerRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let prayer: GuidedPrayer
    let action: () -> Void

    var body: some View {
        let tint = prayer.tintColor

        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: prayer.icon)
                    .font(ABY.Font.bodyMedium)
                    .foregroundStyle(palette.isNight ? tint.opacity(0.95) : tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(palette.isNight ? 0.18 : 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(prayer.title)
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textPrimary)
                    Text(prayer.subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("\(prayer.steps.count) moments")
                    .font(ABY.Font.micro)
                    .foregroundStyle(palette.textTertiary)

                Image(systemName: "chevron.right")
                    .font(ABY.Font.captionSemibold)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(.horizontal, ABY.Spacing.card)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        ABYBackground()
        AIInsightsView()
            .environment(\.openChaplainChat) { _, _ in }
            .environment(\.openChaplainChatWithPortal) { _, _, _ in }
            .environment(\.resumeChaplainChat) { _ in }
            .environment(\.presentDevotionPaywall) {}
    }
}
