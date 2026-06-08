//
//  AIInsightsView.swift
//  test1
//

import InAppKit
import SwiftUI

struct AIInsightsView: View {
    @Environment(\.openVoiceSession) private var openVoiceSession
    @Environment(\.openChaplainChat) private var openChaplainChat
    @Environment(\.openConversation) private var openConversation
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @Environment(\.streakManager) private var streakManager
    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"
    @State private var appeared = false
    @State private var composerDraft = ""
    @State private var showPrayerWall = false
    @State private var showWisdomReflection = false
    @State private var selectedGuidedPrayer: GuidedPrayer?
    @State private var showPassageSearch = false
    @State private var wisdomPrompt = "What is God inviting you to notice today?"
    @State private var insightStore = PersonalInsightStore.shared
    @State private var chaplainSession = ChaplainSessionStore.shared
    @State private var conversationRepository = ConversationRepository.shared
    private var prayerWallStore = PrayerWallStore.shared

    private var focusTags: [FocusTag] {
        TodayFocusStore.tags
    }

    private var focusPrompt: String? {
        FocusTag.chaplainPrompt(for: focusTags)
    }

    private var prayerSuggestion: String {
        FocusTag.prayerWallSuggestion(for: focusTags)
    }

    private var selectedVoice: ChaplainVoice {
        ChaplainVoice.options.first { $0.id == selectedVoiceID } ?? ChaplainVoice.options[0]
    }

    private var todayConversation: Conversation? {
        ConversationMerger.mergedTimeline().first(where: \.isToday)
    }

    private var primaryLocalInsight: PersonalInsight? {
        insightStore.snapshot.headlineInsight
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ABYScreenHeader(
                    title: "Chaplain",
                    showDot: false,
                    subtitle: greetingSubtitle
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 12)
                .padding(.bottom, 20)

                ChaplainHeroCard(
                    voice: selectedVoice,
                    streak: streakManager.currentStreak,
                    onTalk: { openVoiceSession(nil) },
                    onWrite: { openChaplainChat(nil, []) }
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 12)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                if let resumable = chaplainSession.resumableConversation {
                    ContinueConversationChip(conversation: resumable) {
                        chaplainSession.pendingResumeID = resumable.id
                        openChaplainChat(nil, [])
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 12)
                    .opacity(appeared ? 1 : 0)
                }

                ChaplainPromptChips(appeared: appeared) { prompt in
                    openChaplainChat(prompt, [])
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 12)
                .opacity(appeared ? 1 : 0)

                GuidedPrayersSection { prayer in
                    requirePremium { selectedGuidedPrayer = prayer }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 12)
                .opacity(appeared ? 1 : 0)

                PassageBrowseCard {
                    requirePremium { showPassageSearch = true }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 20)
                .opacity(appeared ? 1 : 0)

                if let focusPrompt {
                    FocusTagPromptCard(prompt: focusPrompt) {
                        openChaplainChat(focusPrompt, [])
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 12)
                    .opacity(appeared ? 1 : 0)
                }

                WisdomReflectionEntryCard {
                    requirePremium { showWisdomReflection = true }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 20)
                .opacity(appeared ? 1 : 0)

                ChaplainResourcesSection { prompt in
                    openChaplainChat(prompt, [])
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

                ChaplainPrayerWallSection(store: prayerWallStore, suggestion: prayerSuggestion) {
                    requirePremium { showPrayerWall = true }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

                if let todayConversation {
                    ChaplainRecentExchange(conversation: todayConversation) {
                        openConversation(todayConversation)
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                }

                if let primaryLocalInsight {
                    ABYSectionHeader(title: "Your patterns")
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 10)

                    PersonalInsightCard(insight: primaryLocalInsight)
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 12)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)

                    PersonalInsightThemeRow(themes: insightStore.snapshot.topThemes)
                        .opacity(appeared ? 1 : 0)
                        .padding(.bottom, 16)
                }
            }
            .padding(.bottom, 120)
        }
        .abyTransparentScroll()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChaplainMessageBar(
                text: $composerDraft,
                onSend: {
                    let text = composerDraft
                    composerDraft = ""
                    openChaplainChat(text, [])
                },
                onVoice: { openVoiceSession(nil) }
            )
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 8)
            .padding(.bottom, 88)
            .background(SanctuaryGradientBottomFade())
        }
        .onAppear {
            insightStore.refresh()
            Task { await conversationRepository.refresh() }
            withAnimation(AppTheme.springGentle.delay(0.08)) { appeared = true }
        }
        .sheet(isPresented: $showPrayerWall) {
            PrayerWallView(store: prayerWallStore) { prompt in
                openChaplainChat(prompt, [])
            }
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground {
                ABYCleanGradientBackground()
            }
        }
        .sheet(isPresented: $showPassageSearch) {
            PassageSearchView()
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

    private var greetingSubtitle: String {
        if streakManager.isCompletedToday {
            "You showed up today"
        } else if streakManager.currentStreak > 0 {
            "\(streakManager.currentStreak) day streak"
        } else {
            "A quiet place to begin"
        }
    }

    private func requirePremium(_ action: @escaping () -> Void) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall, action: action)
    }
}

private struct ContinueConversationChip: View {
    let conversation: ResumableChaplainConversation
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "ellipsis.bubble.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ABY.Color.pillPink)
                    .frame(width: 40, height: 40)
                    .background(ABY.Color.pillPink.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Continue conversation")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(ABY.Color.pillPink)
                    Text(conversation.title)
                        .font(ABY.Font.headline)
                        .foregroundStyle(ABY.Color.textPrimary)
                        .lineLimit(1)
                    Text(conversation.preview)
                        .font(ABY.Font.caption)
                        .foregroundStyle(ABY.Color.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(ABY.Font.iconSmall)
                    .foregroundStyle(ABY.Color.textTertiary)
            }
            .padding(14)
            .background(ABY.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                    .stroke(ABY.Color.pillPink.opacity(0.15), lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    ZStack {
        ABYBackground()
        AIInsightsView()
            .environment(\.openVoiceSession) { _ in }
            .environment(\.openChaplainChat) { _, _ in }
            .environment(\.openConversation) { _ in }
            .environment(\.streakManager, .shared)
    }
}
