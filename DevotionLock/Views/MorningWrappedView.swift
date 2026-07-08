//
//  MorningWrappedView.swift
//  DevotionLock
//
//  Mobbin refs:
//  - How We Feel week story: https://mobbin.com/screens/f07c9b43-464b-4056-a5c1-80a13ee5002f
//  - Opal recap story: https://mobbin.com/screens/403d27ac-0a46-4cdd-9e8e-a7521bbc8aee
//  - Apple Music Replay: https://mobbin.com/screens/a9ad905f-120e-4ead-b895-8f1d63fb40ad
//

import SwiftUI

struct MorningWrappedContainerView: View {
    let baseStats: MorningWrappedStats
    var onDismiss: () -> Void

    @State private var stats: MorningWrappedStats

    init(baseStats: MorningWrappedStats, onDismiss: @escaping () -> Void) {
        self.baseStats = baseStats
        self.onDismiss = onDismiss
        _stats = State(initialValue: baseStats)
    }

    var body: some View {
        MorningWrappedView(stats: stats, onDismiss: onDismiss)
            .task {
                let refreshed = await InsightService.shared.fetchWeeklyInsight(fallback: baseStats)
                stats = refreshed
                if let narrative = refreshed.weeklyNarrative {
                    AmbientEmpathy.cacheWeeklyNarrative(narrative)
                }
            }
    }
}

struct MorningWrappedView: View {
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue
    let stats: MorningWrappedStats
    var onDismiss: () -> Void

    @State private var currentPage = 0
    @State private var pageAppeared = false

    private var palette: SanctuaryPalette {
        SanctuaryPalette.forMode(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    private var storyBeats: [WrappedStoryBeat] {
        var beats: [WrappedStoryBeat] = [.intro, .mornings, .rhythm, .mood, .streak, .chaplain]
        if let narrative = stats.weeklyNarrative, !narrative.isEmpty {
            beats.append(.narrative)
        }
        beats.append(.closing)
        return beats
    }

    private var activeBeat: WrappedStoryBeat {
        storyBeats[min(currentPage, storyBeats.count - 1)]
    }

    var body: some View {
        ZStack {
            ABYFlatTabWashBackground()

            VStack(spacing: 0) {
                WrappedStoryChrome(
                    current: currentPage,
                    total: storyBeats.count,
                    onClose: onDismiss
                )

                TabView(selection: $currentPage) {
                    ForEach(Array(storyBeats.enumerated()), id: \.offset) { index, beat in
                        storyPage(beat, isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppTheme.springGentle, value: currentPage)
                .onChange(of: currentPage) { _, _ in
                    pageAppeared = false
                    withAnimation(AppTheme.springGentle.delay(0.05)) { pageAppeared = true }
                    DevotionHaptics.soft()
                }

                storyFooter
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 28)
            }
        }
        .abyScreen()
        .onAppear {
            withAnimation(AppTheme.springGentle) { pageAppeared = true }
        }
    }

    @ViewBuilder
    private func storyPage(_ beat: WrappedStoryBeat, isActive: Bool) -> some View {
        let appeared = pageAppeared && isActive

        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer(minLength: 12)

                switch beat {
                case .intro:
                    WrappedStoryHeadline(
                        text: "Let's look back",
                        subtitle: "A quiet recap of your mornings this week.",
                        appeared: appeared
                    )

                    WrappedStoryStatCard(
                        value: "\(stats.totalDays)",
                        label: "days in your sanctuary so far",
                        badge: stats.morningsThisWeek >= 5 ? "Strong week" : nil,
                        tint: ABY.Color.pillOrange
                    )
                    .padding(.horizontal, ABY.Spacing.screen)
                    .blurReveal(appeared, blurRadius: 8)

                case .mornings:
                    WrappedStoryHeadline(
                        text: morningsHeadline,
                        subtitle: "Before notifications, before the rush.",
                        appeared: appeared
                    )

                    WrappedHeroCounter(
                        value: stats.morningsThisWeek,
                        label: "mornings with intention",
                        tint: ABY.Color.pillOrange,
                        appeared: appeared
                    )

                case .rhythm:
                    WrappedStoryHeadline(
                        text: rhythmHeadline,
                        subtitle: rhythmSubtitle,
                        appeared: appeared
                    )

                    WrappedWeekRhythmPanel(
                        completedDays: stats.weekCompleted,
                        appeared: appeared
                    )
                    .padding(.horizontal, ABY.Spacing.screen)

                case .mood:
                    WrappedStoryHeadline(
                        text: "Mostly feeling \(stats.topMood.lowercased())",
                        subtitle: "The mood that kept returning this week.",
                        appeared: appeared
                    )

                    WrappedMoodStoryOrb(
                        emoji: stats.topMoodEmoji,
                        mood: stats.topMood,
                        appeared: appeared
                    )

                case .streak:
                    WrappedStoryHeadline(
                        text: streakHeadline,
                        subtitle: "Consistency is a form of devotion.",
                        appeared: appeared
                    )

                    WrappedStreakFlame(streak: stats.currentStreak, appeared: appeared)

                case .chaplain:
                    WrappedStoryHeadline(
                        text: "A note from your Chaplain",
                        subtitle: "Something we noticed in your rhythm.",
                        appeared: appeared
                    )

                    WrappedChaplainNote(insight: stats.highlightInsight, appeared: appeared)
                        .padding(.horizontal, ABY.Spacing.screen)

                case .narrative:
                    WrappedStoryHeadline(
                        text: "The story so far",
                        subtitle: "How your week unfolded in the sanctuary.",
                        appeared: appeared
                    )

                    WrappedNarrativeChapter(narrative: stats.weeklyNarrative ?? "", appeared: appeared)
                        .padding(.horizontal, ABY.Spacing.screen)

                case .closing:
                    WrappedStoryHeadline(
                        text: "See you tomorrow morning",
                        subtitle: "Every small return to stillness matters.",
                        appeared: appeared
                    )

                    closingCard
                        .padding(.horizontal, ABY.Spacing.screen)
                        .blurReveal(appeared, blurRadius: 8)
                }

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var storyFooter: some View {
        VStack(spacing: 12) {
            Button(action: advanceStory) {
                Text(currentPage >= storyBeats.count - 1 ? "Done" : "Continue")
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(palette.buttonForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(palette.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())

            if currentPage < storyBeats.count - 1 {
                Button("Skip for now", action: onDismiss)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.isNight ? palette.textSecondary : palette.textTertiary)
            }
        }
    }

    private var closingCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(ABY.Font.title2)
                .foregroundStyle(ABY.Color.pillTeal)

            Text("\(stats.morningsThisWeek) of 7 mornings")
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)

            Text("Keep building the rhythm, one gentle morning at a time.")
                .font(ABY.Font.body)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .fill(palette.surface.opacity(0.94))
        )
    }

    private var morningsHeadline: String {
        switch stats.morningsThisWeek {
        case 0: "A soft reset awaits"
        case 1: "You began once this week"
        case 7: "You showed up every morning"
        default: "You showed up \(stats.morningsThisWeek) mornings"
        }
    }

    private var rhythmHeadline: String {
        let completed = stats.weekCompleted.filter { $0 }.count
        if completed == 7 { return "A perfect week. You checked in every day" }
        if completed >= 5 { return "Your rhythm held steady" }
        let morningWord = completed == 1 ? "morning" : "mornings"
        return "Your week had \(completed) devoted \(morningWord)"
    }

    private var rhythmSubtitle: String? {
        let completed = stats.weekCompleted.filter { $0 }.count
        if completed == 0 { return "Tomorrow is a fresh beginning." }
        return nil
    }

    private var streakHeadline: String {
        if stats.currentStreak <= 1 { return "Day one is sacred too" }
        return "\(stats.currentStreak) day streak"
    }

    private func advanceStory() {
        if currentPage < storyBeats.count - 1 {
            withAnimation(AppTheme.springSnappy) {
                currentPage += 1
            }
            DevotionHaptics.light()
        } else {
            DevotionHaptics.success()
            onDismiss()
        }
    }
}

#Preview {
    MorningWrappedView(
        stats: MorningWrappedStats(
            morningsThisWeek: 5,
            topMood: "Peaceful",
            topMoodEmoji: "🍃",
            currentStreak: 5,
            totalDays: 12,
            highlightInsight: "You showed up peaceful today, a gentle beginning before the world rushes in.",
            weeklyNarrative: "This week you returned to stillness even when mornings felt heavy. Your journal named gratitude more than once, a sign your heart is learning to notice mercy in small places.",
            weekLabels: [],
            weekCompleted: [true, true, false, true, true, true, false]
        ),
        onDismiss: {}
    )
}
