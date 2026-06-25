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
    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"
    @State private var appeared = false
    @State private var insightsSheet: InsightsSheet?
    @State private var showGuidedPrayerPicker = false
    @State private var showWisdomReflection = false
    @State private var guidedPrayerLaunch: GuidedPrayerLaunch?
    @State private var pendingGuidedPrayerLaunch: GuidedPrayerLaunch?
    @State private var wisdomPrompt = "What is God inviting you to notice today?"
    @AppStorage("intentionMood") private var intentionMood = "Peaceful"
    private let chaplainSession = ChaplainSessionStore.shared
    private let conversationRepository = ConversationRepository.shared

    private var selectedVoice: ChaplainVoice {
        ChaplainVoice.options.first { $0.id == selectedVoiceID } ?? ChaplainVoice.options[0]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hubHeader
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .blurReveal(appeared, blurRadius: 6, scale: 1.004)

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
            .padding(.bottom, 120)
        }
        .abyTransparentScroll()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChaplainComposeLauncher(voiceName: selectedVoice.name) {
                openChaplainChatWithPortal(selectedVoice.name, nil, [])
            }
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
        }
        .onAppear {
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

    private var hubHeader: some View {
        ABYScreenHeader(title: "Chaplain", subtitle: greetingSubtitle) {
            Button(action: { insightsSheet = .chatHistory }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(ABY.Font.bodyMedium)
                    .foregroundStyle(ABY.Color.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                    .contentShape(Circle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Chat history")
        }
    }

    private var greetingSubtitle: String {
        "A quiet place to talk and reflect"
    }

    private func requirePremium(_ action: @escaping () -> Void) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall, action: action)
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

    var body: some View {
        NavigationStack {
            ZStack {
                ABYBackground(style: .tabShell).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        experiencePicker
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
                    Button("Done") { dismiss() }
                }
            }
        }
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
            .background(ABY.Color.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .padding(.horizontal, ABY.Spacing.screen)
        }
    }

    private var prayerList: some View {
        VStack(spacing: 0) {
            ForEach(Array(GuidedPrayerCatalog.all.enumerated()), id: \.element.id) { index, prayer in
                GuidedPrayerPickerRow(prayer: prayer) {
                    DevotionHaptics.light()
                    onSelect(prayer, selectedStyle)
                }

                if index < GuidedPrayerCatalog.all.count - 1 {
                    Divider()
                        .padding(.leading, 56)
                        .allowsHitTesting(false)
                }
            }
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .strokeBorder(palette.divider, lineWidth: 1)
        }
        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 8, y: 2)
        .padding(.horizontal, ABY.Spacing.screen)
    }
}

private struct GuidedPrayerExperienceChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let style: GuidedPrayerExperienceStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(style.title)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textPrimary)
                Text(style.subtitle)
                    .font(ABY.Font.micro)
                    .foregroundStyle(palette.textTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: ABY.Radius.chip + 2, style: .continuous)
                        .fill(palette.surface)
                        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 6, y: 2)
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: ABY.Radius.chip + 2, style: .continuous)
                        .strokeBorder(ABY.Color.pillTeal.opacity(0.35), lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct GuidedPrayerPickerRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let prayer: GuidedPrayer
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: prayer.icon)
                    .font(ABY.Font.bodyMedium)
                    .foregroundStyle(ABY.Color.pillTeal)
                    .frame(width: 36, height: 36)
                    .background(ABY.Color.pillTeal.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(prayer.title)
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textPrimary)
                    Text(prayer.subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(ABY.Font.captionSemibold)
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(.horizontal, ABY.Spacing.card)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
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
