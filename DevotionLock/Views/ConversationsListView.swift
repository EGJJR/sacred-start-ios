//
//  ConversationsListView.swift
//  test1
//

import SwiftUI

struct ConversationsListView: View {
    @Environment(\.openConversation) private var openConversation
    @Environment(\.openGuidedJournal) private var openGuidedJournal
    @Environment(\.openStreakScreen) private var openStreakScreen
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @Environment(\.streakManager) private var streakManager

    @State private var repository = ConversationRepository.shared
    @State private var journalStore = JournalLocalStore.shared
    @State private var journalPresentation = JournalPresentationStore.shared
    @State private var appeared = false
    @State private var showEntryHub = false
    @State private var showAssistedJournal = false
    @State private var showVoiceJournal = false

    private var mergedEntries: [Conversation] {
        ConversationMerger.mergedTimeline()
    }

    private var todayEntries: [Conversation] { mergedEntries.filter(\.isToday) }
    private var earlierEntries: [Conversation] { mergedEntries.filter { !$0.isToday } }
    private var hasEntries: Bool { !mergedEntries.isEmpty }

    var body: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    JournalTimelineHeader(
                        streak: streakManager.currentStreak,
                        entryCount: mergedEntries.count
                    )
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 12)

                    if streakManager.currentStreak > 0 {
                        ABYFlameBadge(streak: streakManager.currentStreak, action: openStreakScreen)
                            .opacity(appeared ? 1 : 0)
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 12)
                .padding(.bottom, 20)

                JournalEntryHub(
                    onDevotion: openGuidedJournal,
                    onAssisted: { requirePremium { showAssistedJournal = true } },
                    onVoice: { requirePremium { showVoiceJournal = true } },
                    onOpenHub: { requirePremium { showEntryHub = true } }
                )
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                if hasEntries {
                    journalSection(
                        title: "Today",
                        entries: todayEntries,
                        animationOffset: 0.04
                    )

                    if !earlierEntries.isEmpty {
                        journalSection(
                            title: "Earlier",
                            entries: earlierEntries,
                            animationOffset: 0.08
                        )
                    }
                } else if !repository.isLoading {
                    JournalEmptyState(onAdd: { requirePremium { showEntryHub = true } })
                        .padding(.horizontal, ABY.Spacing.screen)
                        .opacity(appeared ? 1 : 0)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            JournalComposerBar(onAdd: { requirePremium { showEntryHub = true } })
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 88)
                .background(SanctuaryGradientBottomFade())
        }
        .refreshable {
            await repository.refresh()
        }
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
            Task { await repository.refresh() }
        }
        .onChange(of: journalPresentation.presentEntryHub) { _, shouldPresent in
            guard shouldPresent else { return }
            showEntryHub = true
            journalPresentation.presentEntryHub = false
        }
        .sheet(isPresented: $showEntryHub) {
            JournalEntryHubSheet(
                onAssisted: { requirePremium { showAssistedJournal = true } },
                onVoice: { requirePremium { showVoiceJournal = true } }
            )
        }
        .fullScreenCover(isPresented: $showAssistedJournal) {
            AssistedJournalView()
        }
        .fullScreenCover(isPresented: $showVoiceJournal) {
            VoiceJournalView()
        }
    }

    private func requirePremium(_ action: @escaping () -> Void) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall, action: action)
    }

    @ViewBuilder
    private func journalSection(
        title: String,
        entries: [Conversation],
        animationOffset: Double
    ) -> some View {
        if !entries.isEmpty {
            JournalDayHeader(title: title)
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 14)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 16) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, conversation in
                    JournalTimelineEntry(
                        conversation: conversation,
                        isLastInSection: index == entries.count - 1
                    ) {
                        openConversation(conversation)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(
                        AppTheme.springGentle.delay(animationOffset + Double(index) * 0.04),
                        value: appeared
                    )
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 28)
        }
    }
}

#Preview {
    ZStack {
        ABYBackground()
        ConversationsListView()
            .environment(\.openStreakScreen) {}
            .environment(\.openGuidedJournal) {}
            .environment(\.streakManager, .shared)
    }
}
