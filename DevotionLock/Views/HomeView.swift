//
//  HomeView.swift
//  test1
//

import SwiftUI

struct HomeView: View {
    @Environment(\.openConversation) private var openConversation
    @Environment(\.openGuidedJournal) private var openGuidedJournal
    @Environment(\.openStreakScreen) private var openStreakScreen
    @Environment(\.openMorningWrapped) private var openMorningWrapped
    @Environment(\.openPrayerWall) private var openPrayerWall
    @Environment(\.openJourneyTimeline) private var openJourneyTimeline
    @Environment(\.openChaplainChat) private var openChaplainChat
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @Environment(\.streakManager) private var streakManager

    @AppStorage("intentionMood") private var intentionMood = "Peaceful"
    @AppStorage("shieldEnabled") private var shieldEnabled = true
    @State private var shieldManager = AppShieldManager.shared

    @State private var rhythmStore = DailyRhythmStore.shared
    @State private var journeyStore = JourneyTimelineStore.shared
    @State private var insightStore = PersonalInsightStore.shared
    @State private var conversationRepository = ConversationRepository.shared
    @State private var journalStore = JournalLocalStore.shared
    @State private var appeared = false
    @State private var refreshProgress: CGFloat = 0
    @State private var isRefreshing = false
    @State private var showDailyVerse = false
    @State private var showEveningReflection = false

    private var dailyFocus: DailyFocus { DailyFocus.today }
    private var dailyPassage: SpiritualPassage { SpiritualPassageCatalog.todayScripture }

    private var mergedEntries: [Conversation] {
        ConversationMerger.mergedTimeline()
    }

    private var todayEntries: [Conversation] {
        mergedEntries.filter(\.isToday)
    }

    private var earlierEntries: [Conversation] {
        mergedEntries.filter { !$0.isToday }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if isRefreshing {
                    ShepherdRefreshIndicator(progress: refreshProgress)
                        .padding(.bottom, 12)
                        .transition(.opacity)
                }

                timelineHeader
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .staggeredAppear(appeared, delay: 0)

                ABYWeeklyStrip(completedDays: streakManager.weekCompletionFlags)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 16)
                    .staggeredAppear(appeared, delay: 0.04)

                PersonalInsightsSection(insights: insightStore.topInsights)
                    .staggeredAppear(appeared, delay: 0.05)

                PersonalInsightThemeRow(themes: insightStore.snapshot.topThemes)
                    .staggeredAppear(appeared, delay: 0.055)

                DailyStoryRingsRow(rhythmStore: rhythmStore, onRing: handleRingTap)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.06)
                    .id(rhythmStore.revision)

                if shieldEnabled {
                    ShieldStatusCard(
                        isLocked: !streakManager.isCompletedToday,
                        isCompletedToday: streakManager.isCompletedToday,
                        isShieldActive: shieldManager.isShieldActive,
                        onBegin: openGuidedJournal
                    )
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.08)
                }

                ABYSectionHeader(title: "Today")
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 10)
                    .staggeredAppear(appeared, delay: 0.1)

                if let summary = streakManager.todaySummary, streakManager.isCompletedToday {
                    HomeDaySummaryCard(summary: summary)
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 16)
                        .staggeredAppear(appeared, delay: 0.12)
                }

                if !streakManager.isCompletedToday {
                    if mergedEntries.isEmpty {
                        HomeFirstDevotionNudge(onBegin: openGuidedJournal)
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.bottom, 20)
                            .staggeredAppear(appeared, delay: 0.14)
                    } else {
                        HomeTodayCard(
                            focus: dailyFocus,
                            mood: intentionMood,
                            onBegin: openGuidedJournal
                        )
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 20)
                        .staggeredAppear(appeared, delay: 0.14)
                    }
                }

                todaySection
                earlierSection

                JourneyTimelinePreviewSection(store: journeyStore, onSeeAll: openJourneyTimeline)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .staggeredAppear(appeared, delay: 0.18)
                    .id(journeyStore.revision)

                if streakManager.daysJournaled > 0 {
                    Button(action: openMorningWrapped) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Your week in review")
                                .font(ABY.Font.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(ABY.Font.iconSmall)
                        }
                        .foregroundStyle(ABY.Color.textPrimary)
                        .padding(ABY.Spacing.card)
                        .background(ABY.Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 8)
                    .staggeredAppear(appeared, delay: 0.2)
                }
            }
            .padding(.bottom, 120)
        }
        .abyTransparentScroll()
        .refreshable {
            await performRefresh()
        }
        .onAppear {
            refreshHomeState()
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .devotionRhythmDidUpdate)) { _ in
            refreshHomeState()
        }
        .onChange(of: showDailyVerse) { _, isShowing in
            if !isShowing { refreshHomeState() }
        }
        .onChange(of: showEveningReflection) { _, isShowing in
            if !isShowing { refreshHomeState() }
        }
        .sheet(isPresented: $showDailyVerse) {
            DailyVerseSheet(
                passage: dailyPassage,
                onReflect: {
                    openChaplainChat(
                        "Help me reflect on today's passage: \"\(dailyPassage.text)\" — \(dailyPassage.attribution)",
                        []
                    )
                },
                onComplete: {
                    rhythmStore.markComplete(.dailyVerse)
                    journeyStore.logVerseViewed(reference: dailyPassage.reference, text: dailyPassage.text)
                }
            )
        }
        .sheet(isPresented: $showEveningReflection) {
            EveningReflectionSheet(
                onComplete: { highlight in
                    rhythmStore.markComplete(.eveningReflection)
                    journeyStore.logEvening(highlight: highlight)
                },
                onVoiceHandoff: { transcript in
                    let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    let saved = text.isEmpty ? "Quiet gratitude for today." : text
                    rhythmStore.markComplete(.eveningReflection)
                    journeyStore.logEvening(highlight: saved)
                    showEveningReflection = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        openChaplainChat(
                            VoiceChatHandoff.starter(from: saved, context: "my evening reflection"),
                            VoiceChatHandoff.seedMessages(for: saved)
                        )
                    }
                }
            )
        }
    }

    private func handleRingTap(_ ring: DailyRhythmRing) {
        switch ring {
        case .dailyVerse:
            requirePremium { showDailyVerse = true }
        case .morningDevotion:
            openGuidedJournal()
        case .eveningReflection:
            requirePremium { showEveningReflection = true }
        case .prayerWall:
            openPrayerWall(nil)
        }
    }

    private func requirePremium(_ action: @escaping () -> Void) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall, action: action)
    }

    private var timelineHeader: some View {
        HStack(alignment: .top) {
            ABYScreenHeader(title: "Home", showDot: false, subtitle: greeting)
            Spacer()
            if streakManager.currentStreak > 0 {
                ABYFlameBadge(streak: streakManager.currentStreak, action: openStreakScreen)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    @ViewBuilder
    private var todaySection: some View {
        if streakManager.isCompletedToday, !todayEntries.isEmpty {
            VStack(spacing: 12) {
                ForEach(Array(todayEntries.enumerated()), id: \.element.id) { index, conversation in
                    TimelineEntryRow(
                        time: conversation.timelineTime,
                        conversation: conversation
                    ) {
                        openConversation(conversation)
                    }
                    .staggeredAppear(appeared, delay: 0.16 + Double(index) * 0.04)
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var earlierSection: some View {
        if !earlierEntries.isEmpty {
            ABYSectionHeader(title: "Earlier")
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 10)

            VStack(spacing: 12) {
                ForEach(earlierEntries) { conversation in
                    TimelineEntryRow(
                        time: conversation.timelineTime,
                        conversation: conversation
                    ) {
                        openConversation(conversation)
                    }
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
        }
    }

    @MainActor
    private func refreshHomeState() {
        rhythmStore.syncFromExistingState()
        shieldManager.syncShieldState()
        insightStore.refresh()
    }

    @MainActor
    private func performRefresh() async {
        isRefreshing = true
        refreshProgress = 0
        withAnimation(.easeInOut(duration: 0.9)) { refreshProgress = 1 }
        await SyncCoordinator.shared.flushAll(force: true)
        refreshHomeState()
        DevotionHaptics.light()
        isRefreshing = false
        refreshProgress = 0
    }
}

private struct HomeFirstDevotionNudge: View {
    var onBegin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start your first morning devotion")
                .font(ABY.Font.headline)
                .foregroundStyle(ABY.Color.textPrimary)
            Text("Begin with scripture, reflection, and a few quiet minutes before the day starts.")
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onBegin) {
                Text("Begin devotion")
                    .font(ABY.Font.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ABY.Color.pillTeal)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Begin your first morning devotion")
        }
        .padding(ABY.Spacing.card)
        .background(ABY.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
    }
}

struct RecordingDot: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 7, height: 7)
            .overlay {
                Circle()
                    .stroke(Color.red.opacity(pulse ? 0 : 0.6), lineWidth: 2)
                    .frame(width: pulse ? 18 : 7, height: pulse ? 18 : 7)
                    .opacity(pulse ? 0 : 1)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
    }
}

#Preview {
    HomeView()
        .environment(\.openGuidedJournal) {}
        .environment(\.openStreakScreen) {}
        .environment(\.openMorningWrapped) {}
        .environment(\.openConversation) { _ in }
        .environment(\.openPrayerWall) { _ in }
        .environment(\.openJourneyTimeline) {}
        .environment(\.openChaplainChat) { _, _ in }
        .environment(\.streakManager, .shared)
}
