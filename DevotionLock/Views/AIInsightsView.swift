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
    @Environment(\.resumeChaplainChat) private var resumeChaplainChat
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"
    @State private var appeared = false
    @State private var insightsSheet: InsightsSheet?
    @State private var showGuidedPrayerPicker = false
    @State private var showWisdomReflection = false
    @State private var selectedGuidedPrayer: GuidedPrayer?
    @State private var wisdomPrompt = "What is God inviting you to notice today?"
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
                openChaplainChat(nil, [])
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
        .sheet(isPresented: $showGuidedPrayerPicker) {
            GuidedPrayerPickerSheet { prayer in
                showGuidedPrayerPicker = false
                selectedGuidedPrayer = prayer
            }
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .fullScreenCover(item: $selectedGuidedPrayer) { prayer in
            GuidedPrayerFlowView(prayer: prayer) {
                JourneyTimelineStore.shared.add(JourneyTimelineEntry(
                    kind: .reflection,
                    title: prayer.title,
                    body: "Completed guided prayer"
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

private struct GuidedPrayerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    let onSelect: (GuidedPrayer) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ABYCleanGradientBackground().ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(GuidedPrayerCatalog.all.enumerated()), id: \.element.id) { index, prayer in
                            Button {
                                onSelect(prayer)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: prayer.icon)
                                        .font(ABY.Font.bodyMedium)
                                        .foregroundStyle(ABY.Color.pillTeal)
                                        .frame(width: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(prayer.title)
                                            .font(ABY.Font.calloutSemibold)
                                            .foregroundStyle(palette.textPrimary)
                                        Text(prayer.subtitle)
                                            .font(ABY.Font.caption)
                                            .foregroundStyle(palette.textSecondary)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(ABY.Font.emojiSmall)
                                        .foregroundStyle(palette.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)

                            if index < GuidedPrayerCatalog.all.count - 1 {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 8)
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
}

#Preview {
    ZStack {
        ABYBackground()
        AIInsightsView()
            .environment(\.openChaplainChat) { _, _ in }
            .environment(\.resumeChaplainChat) { _ in }
            .environment(\.presentDevotionPaywall) {}
    }
}
