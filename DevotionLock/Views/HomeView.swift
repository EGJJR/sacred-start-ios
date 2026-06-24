//
//  HomeView.swift
//  test1
//

import SwiftUI

private enum HomeRhythmSheet: Identifiable {
    case dailyVerse
    case eveningReflection

    var id: String {
        switch self {
        case .dailyVerse: "daily-verse"
        case .eveningReflection: "evening-reflection"
        }
    }
}

private enum HomeScriptureSheet: Identifiable {
    case bible
    case promises

    var id: String {
        switch self {
        case .bible: "bible"
        case .promises: "promises"
        }
    }
}

struct HomeView: View {
    @Environment(\.openGuidedJournal) private var openGuidedJournal
    @Environment(\.openStreakScreen) private var openStreakScreen
    @Environment(\.openMorningWrapped) private var openMorningWrapped
    @Environment(\.openPrayerWall) private var openPrayerWall
    @Environment(\.openChaplainChat) private var openChaplainChat
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @Environment(\.selectTab) private var selectTab
    @Environment(\.streakManager) private var streakManager

    @AppStorage("intentionMood") private var intentionMood = "Peaceful"
    @AppStorage("shieldEnabled") private var shieldEnabled = true
    private let shieldManager = AppShieldManager.shared
    private let rhythmStore = DailyRhythmStore.shared
    private let journeyStore = JourneyTimelineStore.shared
    private let insightStore = PersonalInsightStore.shared
    private let prayerWallStore = PrayerWallStore.shared
    @State private var appeared = false
    @State private var refreshProgress: CGFloat = 0
    @State private var isRefreshing = false
    @State private var rhythmSheet: HomeRhythmSheet?
    @State private var scriptureSheet: HomeScriptureSheet?

    private var dailyFocus: DailyFocus { DailyFocus.today }
    private var dailyPassage: SpiritualPassage { SpiritualPassageCatalog.todayScripture }

    private var journalEntryCount: Int {
        ConversationMerger.mergedTimeline().count
    }

    private var latestJournalPreview: String? {
        ConversationMerger.mergedTimeline().first?.timelinePreview
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

                HomeScriptureShortcutsRow(
                    onBible: { scriptureSheet = .bible },
                    onPromises: { scriptureSheet = .promises }
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 16)
                .staggeredAppear(appeared, delay: 0.07)

                ChaplainPrayerWallSection(
                    store: prayerWallStore,
                    suggestion: FocusTag.prayerWallSuggestion(for: TodayFocusStore.tags)
                ) {
                    requirePremium { openPrayerWall(nil) }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 20)
                .staggeredAppear(appeared, delay: 0.08)

                if shieldEnabled {
                    ShieldStatusCard(
                        isLocked: !streakManager.isCompletedToday,
                        isCompletedToday: streakManager.isCompletedToday,
                        isShieldActive: shieldManager.isShieldActive,
                        onBegin: openGuidedJournal
                    )
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.09)
                }

                ABYSectionHeader(title: "Today")
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 10)
                    .staggeredAppear(appeared, delay: 0.1)

                if let summary = streakManager.todaySummary, streakManager.isCompletedToday {
                    HomeDaySummaryCard(summary: summary)
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 16)
                        .staggeredAppear(appeared, delay: 0.11)
                }

                if !streakManager.isCompletedToday {
                    if journalEntryCount == 0 {
                        HomeFirstDevotionNudge(onBegin: openGuidedJournal)
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.bottom, 20)
                            .staggeredAppear(appeared, delay: 0.12)
                    } else {
                        HomeTodayCard(
                            focus: dailyFocus,
                            mood: intentionMood,
                            onBegin: openGuidedJournal
                        )
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 20)
                        .staggeredAppear(appeared, delay: 0.12)
                    }
                }

                if journalEntryCount > 0 {
                    HomeJournalPreviewLink(
                        entryCount: journalEntryCount,
                        latestPreview: latestJournalPreview,
                        onSeeAll: { selectTab(.conversations) }
                    )
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)
                    .staggeredAppear(appeared, delay: 0.14)
                }

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
                    .staggeredAppear(appeared, delay: 0.18)
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
        .onChange(of: rhythmSheet) { _, sheet in
            if sheet == nil { refreshHomeState() }
        }
        .sheet(item: $scriptureSheet) { sheet in
            switch sheet {
            case .bible:
                PassageSearchView(
                    initialTab: FeatureFlags.bibleReaderEnabled ? .books : .discover
                )
            case .promises:
                PassageSearchView(initialTopics: [.promises], initialTab: .discover)
            }
        }
        .sheet(item: $rhythmSheet) { sheet in
            switch sheet {
            case .dailyVerse:
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
            case .eveningReflection:
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
                        rhythmSheet = nil
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
    }

    private func handleRingTap(_ ring: DailyRhythmRing) {
        switch ring {
        case .dailyVerse:
            requirePremium { rhythmSheet = .dailyVerse }
        case .morningDevotion:
            openGuidedJournal()
        case .eveningReflection:
            requirePremium { rhythmSheet = .eveningReflection }
        case .prayerWall:
            openPrayerWall(nil)
        }
    }

    private func requirePremium(_ action: @escaping () -> Void) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall, action: action)
    }

    private var timelineHeader: some View {
        ABYScreenHeader(title: "Home", showDot: false, subtitle: greeting) {
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
        .environment(\.openPrayerWall) { _ in }
        .environment(\.openJourneyTimeline) {}
        .environment(\.openChaplainChat) { _, _ in }
        .environment(\.selectTab) { _ in }
        .environment(\.streakManager, .shared)
}
