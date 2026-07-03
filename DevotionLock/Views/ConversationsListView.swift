//
//  ConversationsListView.swift
//  DevotionLock
//
//  Mobbin refs:
//  - ABY Journal timeline: https://mobbin.com/screens/b6769a87-5bd1-4fd3-9309-8f7cdae58991
//  - Stoic Journey: https://mobbin.com/screens/29493be0-df7a-4d60-b094-81761d272482
//  - How We Feel mood cards: https://mobbin.com/screens/da9f1f1a-766f-4746-b45a-20661adb8ef4
//  - Calm mood check-in: https://mobbin.com/screens/40ba5ad3-03c7-4b81-ac40-6a2b447233fa
//

import SwiftUI

struct ConversationsListView: View {
    @Environment(\.openConversation) private var openConversation
    @Environment(\.openStreakScreen) private var openStreakScreen
    @Environment(\.openGuidedJournal) private var openGuidedJournal
    @Environment(\.openAssistedJournal) private var openAssistedJournal
    @Environment(\.openPrayerWall) private var openPrayerWall
    @Environment(\.openDailyVerse) private var openDailyVerse
    @Environment(\.openEveningReflection) private var openEveningReflection
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @Environment(\.streakManager) private var streakManager

    private let repository = ConversationRepository.shared
    private let rhythmStore = DailyRhythmStore.shared
    @State private var appeared = false
    @State private var browseMode: JournalBrowseMode = .timeline

    #if DEBUG
    @Environment(\.designTourTimelineSamples) private var designTourTimelineSamples
    #endif

    /// Tab bar clearance.
    private static let bottomScrollPadding: CGFloat = 100

    private var mergedEntries: [Conversation] {
        #if DEBUG
        if let designTourTimelineSamples {
            return designTourTimelineSamples.filter { ConversationMerger.isJournalTimelineEntry($0) }
        }
        #endif
        return ConversationMerger.journalTimeline()
    }

    private var dayGroups: [JournalDayGroup] {
        mergedEntries.groupedByJournalDay()
    }

    private var hasEntries: Bool { !mergedEntries.isEmpty }

    var body: some View {
        ABYCustomFadingHeaderScrollView(
            compactTitle: "Journal",
            bottomPadding: Self.bottomScrollPadding,
            inlineTopPadding: 8,
            inlineHeader: {
                JournalScreenHeader(
                    streak: streakManager.currentStreak,
                    onStreakTap: openStreakScreen
                )
            },
            compactTrailing: {
                if streakManager.currentStreak > 0 {
                    JournalStreakPill(streak: streakManager.currentStreak, action: openStreakScreen)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 0) {
                ABYWeeklyStrip(completedDays: streakManager.weekCompletionFlags)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 16)
                    .blurReveal(appeared, blurRadius: 4, scale: 1.002)

                JournalBrowseSegment(mode: $browseMode)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)
                    .blurReveal(appeared, blurRadius: 4, scale: 1.002)

                browseContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await repository.refresh()
        }
        .refreshable {
            await repository.refresh()
        }
        .onAppear {
            rhythmStore.syncFromExistingState()
            withAnimation(AppTheme.springGentle.delay(0.04)) { appeared = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .devotionRhythmDidUpdate)) { _ in
            rhythmStore.syncFromExistingState()
        }
    }

    @ViewBuilder
    private var browseContent: some View {
        switch browseMode {
        case .timeline:
            timelineContent
        case .rhythms:
            JournalRhythmsPanel(
                rhythmStore: rhythmStore,
                onRing: handleRhythmTap
            )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 16)
                .blurReveal(appeared, blurRadius: 4, scale: 1.002)
        case .prompts:
            JournalPromptsPanel(
                onFreeWrite: { requirePremium { openAssistedJournal(nil) } },
                onSelect: { template in
                    requirePremium { openAssistedJournal(template.prompt) }
                }
            )
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 16)
            .blurReveal(appeared, blurRadius: 4, scale: 1.002)
        }
    }

    @ViewBuilder
    private var timelineContent: some View {
        if hasEntries {
            ForEach(Array(dayGroups.enumerated()), id: \.element.id) { groupIndex, group in
                JournalDaySectionHeader(title: group.title, entryCount: group.entries.count)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 12)
                    .padding(.top, groupIndex == 0 ? 0 : 8)
                    .blurReveal(appeared, blurRadius: 4, scale: 1.002)

                if let insight = JournalDayInsightBuilder.build(dayTitle: group.title, entries: group.entries) {
                    JournalDayInsightCard(dayTitle: group.title, insight: insight)
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 14)
                        .blurReveal(appeared, blurRadius: 4, scale: 1.002)
                }

                VStack(spacing: 0) {
                    ForEach(Array(group.entries.enumerated()), id: \.element.id) { entryIndex, conversation in
                        JournalTimelineEntry(
                            conversation: conversation,
                            isLastInSection: entryIndex == group.entries.count - 1
                        ) {
                            openConversation(conversation)
                        }
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 20)
            }
        } else if !repository.isLoading {
            JournalEmptyState()
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 4)
                .blurReveal(appeared, blurRadius: 6, scale: 1.004)
        }
    }

    private func handleRhythmTap(_ ring: DailyRhythmRing) {
        switch ring {
        case .morningDevotion:
            requirePremium { openGuidedJournal() }
        case .dailyVerse:
            requirePremium { openDailyVerse() }
        case .eveningReflection:
            requirePremium { openEveningReflection() }
        case .prayerWall:
            requirePremium { openPrayerWall(nil) }
        }
    }

    private func requirePremium(_ action: @escaping () -> Void) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall, action: action)
    }
}

#Preview {
    ZStack {
        ABYBackground()
        ConversationsListView()
            .environment(\.openStreakScreen) {}
            .environment(\.streakManager, .shared)
    }
    .abyScreen()
}
