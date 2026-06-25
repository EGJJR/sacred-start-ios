//
//  JourneyTimelineViews.swift
//  DevotionLock
//
//  Mobbin ABY timeline: https://mobbin.com/screens/a79d0a61-c35f-4ab7-bf44-9100c457fb53
//

import SwiftUI

struct JourneyTimelineView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.openStreakScreen) private var openStreakScreen
    var store: JourneyTimelineStore

    @State private var appeared = false

    private var grouped: [(String, [JourneyTimelineEntry])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let groups = Dictionary(grouping: store.recentEntries) { entry in
            formatter.string(from: entry.createdAt)
        }
        return groups.sorted { $0.key > $1.key }.map { ($0.key, $0.value.sorted { $0.createdAt > $1.createdAt }) }
    }

    private var sectionTitle: String {
        if store.todayEntries.isEmpty { "Your path" } else { "Today" }
    }

    var body: some View {
        ZStack {
            ABYCleanGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ABYTimelineScreenHeader(
                        sectionTitle: sectionTitle,
                        streak: StreakManager.shared.currentStreak,
                        onStreakTap: openStreakScreen
                    )
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .opacity(appeared ? 1 : 0)

                    if store.recentEntries.isEmpty {
                        emptyState
                            .padding(.horizontal, ABY.Spacing.screen)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 22) {
                            ForEach(Array(grouped.enumerated()), id: \.offset) { sectionIndex, group in
                                VStack(alignment: .leading, spacing: 14) {
                                    Text(group.0)
                                        .font(ABY.Font.captionMedium)
                                        .foregroundStyle(palette.textSecondary)
                                        .padding(.horizontal, ABY.Spacing.screen)

                                    ForEach(Array(group.1.enumerated()), id: \.element.id) { index, entry in
                                        ABYJourneyTimelineRow(entry: entry)
                                            .padding(.horizontal, ABY.Spacing.screen)
                                            .blurRevealOnAppear(
                                                index: sectionIndex * 10 + index,
                                                stagger: 0.04,
                                                delay: 0.05
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .abyScrollEdgeFades()
        }
        .abySettingsBackNavigation()
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your journey begins with one quiet moment.")
                .font(ABY.Font.editorialAccent)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(5)
            Text("Moods, verses, prayers, and reflections will gather here as you move through your day.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(4)
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

struct JourneyTimelineRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let entry: JourneyTimelineEntry
    var compact = false

    private var timeLabel: String {
        entry.createdAt.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        if compact {
            ABYJourneyTimelineRow(entry: entry)
        } else {
            HStack(alignment: .top, spacing: compact ? 10 : 14) {
                Text(timeLabel)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
                    .frame(width: 52, alignment: .trailing)
                    .padding(.top, 4)

                entryCard
            }
        }
    }

    private var entryCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(palette.background)
                    .frame(width: 36, height: 36)
                if let emoji = entry.moodEmoji {
                    Text(emoji)
                        .font(ABY.Font.body)
                } else {
                    Image(systemName: entry.kind.icon)
                        .font(ABY.Font.calloutMedium)
                        .foregroundStyle(ABY.Color.pillPurple)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)

                if let body = entry.body, !body.isEmpty {
                    Text(body)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(4)
                }

                HStack(spacing: 6) {
                    Text(entry.kind.label.uppercased())
                        .font(ABY.Font.microBold)
                        .foregroundStyle(palette.textTertiary)
                        .tracking(0.4)

                    if let reference = entry.verseReference {
                        Text(reference)
                            .font(ABY.Font.microBold)
                            .foregroundStyle(ABY.Color.pillPurple)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                .stroke(palette.divider, lineWidth: 1)
        }
    }
}

struct DevotionTimelineSection: View {
    @Environment(\.sanctuaryPalette) private var palette
    var streakManager: StreakManager
    var journeyStore: JourneyTimelineStore
    var onOpenJourney: () -> Void

    var body: some View {
        ABYDevotionJourneySection(
            streakManager: streakManager,
            journeyStore: journeyStore,
            journalEntryCount: JournalLocalStore.shared.entries.count,
            onSeeAll: onOpenJourney
        )
    }
}
