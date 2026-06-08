//
//  JourneyTimelineViews.swift
//  DevotionLock
//

import SwiftUI

struct JourneyTimelineView: View {
    @Environment(\.sanctuaryPalette) private var palette
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

    var body: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                ABYDetailHeader(
                    title: "Journey",
                    subtitle: "Moods, verses, prayers, and reflections over time."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(Array(grouped.enumerated()), id: \.offset) { sectionIndex, group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.0)
                                    .font(ABY.Font.captionMedium)
                                    .foregroundStyle(palette.textSecondary)
                                    .padding(.horizontal, ABY.Spacing.screen)

                                ForEach(Array(group.1.enumerated()), id: \.element.id) { index, entry in
                                    JourneyTimelineRow(entry: entry)
                                        .padding(.horizontal, ABY.Spacing.screen)
                                        .staggeredAppear(appeared, delay: Double(sectionIndex) * 0.05 + Double(index) * 0.04)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar { ABYBackToolbar() }
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }
}

struct JourneyTimelineRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let entry: JourneyTimelineEntry
    var compact = false

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.createdAt)
    }

    var body: some View {
        HStack(alignment: .top, spacing: compact ? 10 : 14) {
            if compact {
                JournalTimeRail(date: entry.createdAt, timeLabel: timeLabel)
                    .frame(width: 44)
            } else {
                Text(timeLabel)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
                    .frame(width: 52, alignment: .trailing)
                    .padding(.top, 4)
            }

            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(palette.background)
                        .frame(width: compact ? 32 : 36, height: compact ? 32 : 36)
                    if let emoji = entry.moodEmoji {
                        Text(emoji)
                            .font(.system(size: compact ? 14 : 16))
                    } else {
                        Image(systemName: entry.kind.icon)
                            .font(.system(size: compact ? 12 : 14, weight: .medium))
                            .foregroundStyle(ABY.Color.pillPurple)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.title)
                            .font(compact ? ABY.Font.callout.weight(.semibold) : ABY.Font.headline)
                            .foregroundStyle(palette.textPrimary)
                        Spacer(minLength: 0)
                    }

                    if let body = entry.body, !body.isEmpty {
                        Text(body)
                            .font(ABY.Font.callout)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(compact ? 2 : 4)
                    }

                    HStack(spacing: 6) {
                        Text(entry.kind.label.uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(palette.textTertiary)
                            .tracking(0.4)

                        if let reference = entry.verseReference {
                            Text(reference)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(ABY.Color.pillPurple)
                        }

                        ForEach(entry.focusTags.prefix(2), id: \.self) { tag in
                            if let focus = FocusTag(rawValue: tag) {
                                Text(focus.label)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(palette.textSecondary)
                            }
                        }
                    }
                }
            }
            .padding(compact ? 12 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
    }
}

struct DevotionTimelineSection: View {
    @Environment(\.sanctuaryPalette) private var palette
    var streakManager: StreakManager
    var journeyStore: JourneyTimelineStore
    var onOpenJourney: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Devotion timeline")
                    .font(ABY.Font.section)
                    .foregroundStyle(palette.textSecondary)
                    .tracking(0.5)
                Spacer()
                Button("Journey", action: onOpenJourney)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.pillPurple)
            }

            if journeyStore.recentEntries.isEmpty && streakManager.daySummaries.isEmpty {
                Text("Complete a devotion to begin your timeline.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .abyCard()
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(timelineCards.prefix(5))) { card in
                        DevotionTimelineCard(card: card)
                    }
                }
            }
        }
    }

    private var timelineCards: [DevotionTimelineCardModel] {
        var cards: [DevotionTimelineCardModel] = journeyStore.recentEntries.prefix(8).map { entry in
            DevotionTimelineCardModel(
                id: entry.id.uuidString,
                time: entry.createdAt,
                mood: entry.title,
                moodEmoji: entry.moodEmoji ?? "🙏",
                preview: entry.body ?? entry.kind.label,
                reference: entry.verseReference
            )
        }

        if cards.isEmpty {
            cards = streakManager.daySummaries.values.sorted { $0.dateKey > $1.dateKey }.prefix(5).map { summary in
                DevotionTimelineCardModel(
                    id: summary.dateKey,
                    time: Date(),
                    mood: summary.mood,
                    moodEmoji: summary.moodEmoji,
                    preview: summary.journalPreview,
                    reference: summary.verseReference
                )
            }
        }
        return cards
    }
}

private struct DevotionTimelineCardModel: Identifiable {
    let id: String
    let time: Date
    let mood: String
    let moodEmoji: String
    let preview: String
    let reference: String?
}

private struct DevotionTimelineCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let card: DevotionTimelineCardModel

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: card.time)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(timeLabel)
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textTertiary)
                .frame(width: 52, alignment: .trailing)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    DevotionMoodPill(label: card.mood, emoji: card.moodEmoji)
                    Spacer()
                    if let reference = card.reference {
                        Text(reference)
                            .font(ABY.Font.caption)
                            .foregroundStyle(ABY.Color.pillPurple)
                    }
                }
                Text(card.preview)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(3)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        }
    }
}

private struct DevotionMoodPill: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String
    var emoji: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let emoji {
                Text(emoji)
            }
            Text(label)
                .font(ABY.Font.captionMedium)
        }
        .foregroundStyle(ABY.Color.moodPeachText)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(ABY.Color.moodPeach)
        .clipShape(Capsule())
    }
}
