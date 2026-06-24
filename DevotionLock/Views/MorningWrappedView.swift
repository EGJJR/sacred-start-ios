//
//  MorningWrappedView.swift
//  DevotionLock
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
                stats = await InsightService.shared.fetchWeeklyInsight(fallback: baseStats)
            }
    }
}

struct MorningWrappedView: View {
    @AppStorage(SanctuaryGradientMode.storageKey) private var modeRaw = SanctuaryGradientMode.light.rawValue
    let stats: MorningWrappedStats
    var onDismiss: () -> Void

    @State private var page = 0
    @State private var appeared = false

    private var palette: SanctuaryPalette {
        SanctuaryPalette.forMode(SanctuaryGradientMode(rawValue: modeRaw) ?? .light)
    }

    private var pages: [WrappedPage] {
        var pages: [WrappedPage] = [
            WrappedPage(
                eyebrow: "Your week",
                title: "\(stats.morningsThisWeek) mornings",
                body: "You showed up \(stats.morningsThisWeek) time\(stats.morningsThisWeek == 1 ? "" : "s") this week — before the noise of the day.",
                symbol: "sun.horizon.fill",
                tint: ABY.Color.pillOrange
            ),
            WrappedPage(
                eyebrow: "Your mood",
                title: "\(stats.topMoodEmoji) \(stats.topMood)",
                body: "This was the tone of your mornings most often — a gentle thread through your week.",
                symbol: "heart.text.square.fill",
                tint: ABY.Color.pillPink
            ),
            WrappedPage(
                eyebrow: "Your streak",
                title: "\(stats.currentStreak) days",
                body: "Consistency isn't perfection. It's returning, again and again, to what matters.",
                symbol: "flame.fill",
                tint: StreakPalette.orange
            ),
            WrappedPage(
                eyebrow: "Chaplain's note",
                title: "A word for you",
                body: stats.highlightInsight,
                symbol: "ellipsis.bubble.fill",
                tint: ABY.Color.pillPurple
            ),
        ]

        if let narrative = stats.weeklyNarrative, !narrative.isEmpty {
            pages.append(
                WrappedPage(
                    eyebrow: "Your week",
                    title: "The story so far",
                    body: narrative,
                    symbol: "book.pages.fill",
                    tint: ABY.Color.pillTeal
                )
            )
        }

        pages.append(
            WrappedPage(
                eyebrow: "Sanctuary",
                title: "\(stats.totalDays) days total",
                body: "Every entry is a small act of presence. Keep building your morning sanctuary.",
                symbol: "sparkles",
                tint: ABY.Color.pillTeal
            )
        )

        return pages
    }

    var body: some View {
        ZStack {
            ABYCleanGradientBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(ABY.Font.iconMedium)
                            .foregroundStyle(palette.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(palette.surface.opacity(0.88))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, wrapped in
                        wrappedCard(wrapped)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(AppTheme.springGentle, value: page)

                if page == pages.count - 1 {
                    ABYPrimaryButton(title: "Close", icon: "checkmark") {
                        onDismiss()
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 28)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Text("\(page + 1) / \(pages.count)")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                        .padding(.bottom, 28)
                }
            }
        }
        .abyScreen()
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }

    private func wrappedCard(_ wrapped: WrappedPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(wrapped.tint.opacity(palette.isNight ? 0.22 : 0.16))
                    .frame(width: 110, height: 110)
                Image(systemName: wrapped.symbol)
                    .font(ABY.Font.largeTitle)
                    .foregroundStyle(wrapped.tint)
            }
            .scaleEffect(appeared ? 1 : 0.7)

            VStack(spacing: 10) {
                Text(wrapped.eyebrow.uppercased())
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textTertiary)
                    .tracking(1)
                Text(wrapped.title)
                    .font(ABY.Font.largeTitle)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                Text(wrapped.body)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 24)
            }

            if page == 0 {
                ABYWeeklyStrip(completedDays: stats.weekCompleted)
                    .padding(.horizontal, ABY.Spacing.screen)
            }

            Spacer()
        }
        .padding(.horizontal, ABY.Spacing.screen)
    }
}

private struct WrappedPage {
    let eyebrow: String
    let title: String
    let body: String
    let symbol: String
    let tint: Color
}

#Preview {
    MorningWrappedView(
        stats: MorningWrappedStats(
            morningsThisWeek: 4,
            topMood: "Peaceful",
            topMoodEmoji: "🍃",
            currentStreak: 5,
            totalDays: 12,
            highlightInsight: "You showed up peaceful today — a gentle beginning before the world rushes in.",
            weeklyNarrative: nil,
            weekLabels: [],
            weekCompleted: [true, true, false, true, true, false, false]
        ),
        onDismiss: {}
    )
}
