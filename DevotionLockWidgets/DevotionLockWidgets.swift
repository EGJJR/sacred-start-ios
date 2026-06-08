//
//  DevotionLockWidgets.swift
//  DevotionLockWidgets
//

import AppIntents
import SwiftUI
import WidgetKit

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: Date(), snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry(date: Date(), snapshot: WidgetSnapshotStore.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

// MARK: - Streak Widget

struct StreakWidgetView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        default:
            mediumView
        }
    }

    private var encouragement: String {
        if entry.snapshot.isCompletedToday {
            return "Sanctuary kept ✦"
        }
        if entry.snapshot.currentStreak >= 3 {
            return "Look at you go!"
        }
        return "Your sanctuary is open"
    }

    private var smallView: some View {
        ZStack(alignment: .bottomTrailing) {
            WidgetStreakGradient(completed: entry.snapshot.isCompletedToday)

            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: entry.snapshot.isCompletedToday ? "checkmark.seal.fill" : "flame.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.bottom, 10)

                Text("\(entry.snapshot.currentStreak)")
                    .font(WidgetTypography.streakNumber(38))
                    .foregroundStyle(.white)

                Text(entry.snapshot.currentStreak == 1 ? "day streak" : "day streak")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))

                Text(encouragement)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.top, 4)

                Spacer(minLength: 8)

                WidgetWeekRingRow(flags: entry.snapshot.weekCompletionFlags, compact: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(14)

            Image(systemName: "flame.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.18))
                .padding(12)
        }
        .widgetURL(DevotionDeepLink.url(host: entry.snapshot.isCompletedToday ? .home : .journal))
    }

    private var mediumView: some View {
        ZStack {
            WidgetStreakGradient(completed: entry.snapshot.isCompletedToday)

            HStack(spacing: 16) {
                WidgetStreakRing(
                    streak: entry.snapshot.currentStreak,
                    weekFlags: entry.snapshot.weekCompletionFlags,
                    diameter: 84
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(encouragement)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .textCase(.uppercase)
                        .tracking(0.4)

                    Text(entry.snapshot.isCompletedToday ? "You showed up today" : "Begin your devotion")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    WidgetWeekRingRow(flags: entry.snapshot.weekCompletionFlags)
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .widgetURL(DevotionDeepLink.url(host: .journal))
    }
}

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetStreakGradient(completed: entry.snapshot.isCompletedToday)
                }
        }
        .configurationDisplayName("Streak")
        .description("Your devotion streak and weekly rhythm.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Verse Widget

struct VerseWidgetView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    private var quoteSize: CGFloat {
        family == .systemLarge ? 24 : 17
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            WidgetSanctuaryBackground()

            VStack(alignment: .leading, spacing: 0) {
                WidgetBrandMark()
                    .padding(.bottom, 12)

                WidgetQuoteMark()

                Text(entry.snapshot.quoteText)
                    .font(WidgetTypography.quote(quoteSize))
                    .foregroundStyle(WidgetPalette.textPrimary)
                    .lineSpacing(family == .systemLarge ? 6 : 4)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 12)

                HStack {
                    Text(entry.snapshot.quoteReference)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.pillPurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(WidgetPalette.pillPurple.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetPalette.textSecondary)
                }
            }
            .padding(16)
        }
        .widgetURL(DevotionDeepLink.url(host: .chaplain, query: ["prompt": entry.snapshot.quoteText]))
    }
}

struct VerseWidget: Widget {
    let kind = "VerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            VerseWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetSanctuaryBackground() }
        }
        .configurationDisplayName("Verse of the Day")
        .description("A daily promise or passage for reflection.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Prayer Wall Widget

struct PrayerWallWidgetView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack {
            WidgetSanctuaryBackground()
            if family == .systemSmall {
                smallView
            } else {
                mediumView
            }
        }
        .widgetURL(DevotionDeepLink.url(host: .prayerWall))
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Prayer wall", systemImage: "hands.sparkles.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.pillPurple)
                Spacer()
                Text("\(entry.snapshot.prayerRequestCount)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.pillPurple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(WidgetPalette.pillPurple.opacity(0.12))
                    .clipShape(Capsule())
            }

            if let note = entry.snapshot.prayerNotes.first {
                WidgetPaperNote(
                    text: note.text,
                    kind: note.kind,
                    tintIndex: note.tintIndex,
                    rotation: note.rotation * 0.6,
                    compact: true
                )
            } else {
                Text("Pin your first prayer")
                    .font(WidgetTypography.quote(13))
                    .foregroundStyle(WidgetPalette.textSecondary)
            }

            Spacer(minLength: 0)

            Link(destination: DevotionDeepLink.url(host: .addPrayer, query: ["kind": "request"])!) {
                WidgetActionChip(title: "Add", icon: "plus", tint: WidgetPalette.pillPurple)
            }
        }
        .padding(14)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Prayer wall")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("\(entry.snapshot.prayerRequestCount) active · \(entry.snapshot.prayerAnsweredCount) answered")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetPalette.textSecondary)
                }
                Spacer()
                Image(systemName: "hands.sparkles.fill")
                    .font(.title3)
                    .foregroundStyle(WidgetPalette.pillPurple.opacity(0.55))
            }

            HStack(alignment: .top, spacing: 8) {
                ForEach(entry.snapshot.prayerNotes.prefix(3)) { note in
                    WidgetPaperNote(
                        text: note.text,
                        kind: note.kind,
                        tintIndex: note.tintIndex,
                        rotation: note.rotation,
                        compact: true
                    )
                }
            }

            HStack(spacing: 8) {
                Button(intent: AddPrayerRequestIntent()) {
                    WidgetActionChip(title: "Request", icon: "plus", tint: WidgetPalette.pillPurple)
                }
                .buttonStyle(.plain)

                Button(intent: AddPrayerReminderIntent()) {
                    WidgetActionChip(title: "Reminder", icon: "bell", tint: WidgetPalette.pillOrange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
    }
}

struct PrayerWallWidget: Widget {
    let kind = "PrayerWallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            PrayerWallWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetSanctuaryBackground() }
        }
        .configurationDisplayName("Prayer Wall")
        .description("Sticky notes for requests, reminders, and answered prayers.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Answered Prayer Widget

struct AnsweredPrayerWidgetView: View {
    var entry: StreakEntry

    var body: some View {
        ZStack {
            if entry.snapshot.answeredCelebrationActive {
                WidgetAnsweredGlow()
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(WidgetPalette.orbSage)
                        .symbolEffect(.bounce, value: entry.snapshot.updatedAt)

                    Text("Answered!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.orbSage)

                    if let text = entry.snapshot.answeredCelebrationText {
                        Text(text)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(WidgetPalette.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                .padding(14)
            } else {
                WidgetSanctuaryBackground()
                VStack(alignment: .leading, spacing: 10) {
                    Label("Prayer wall", systemImage: "hands.sparkles.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.pillPurple)

                    Text("\(entry.snapshot.prayerAnsweredCount) answered")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.textPrimary)

                    Text("Mark a prayer done to celebrate here.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetPalette.textSecondary)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    if let note = entry.snapshot.prayerNotes.first(where: { $0.kind == "request" }) ?? entry.snapshot.prayerNotes.first {
                        WidgetPaperNote(
                            text: note.text,
                            kind: note.kind,
                            tintIndex: note.tintIndex,
                            rotation: note.rotation * 0.5,
                            compact: true
                        )
                    }
                }
                .padding(14)
            }
        }
        .widgetURL(DevotionDeepLink.url(host: .prayerWall))
    }
}

private struct WidgetAnsweredGlow: View {
    var body: some View {
        RadialGradient(
            colors: [
                WidgetPalette.orbSage.opacity(0.35),
                WidgetPalette.orbSage.opacity(0.08),
                Color.white,
            ],
            center: .center,
            startRadius: 8,
            endRadius: 120
        )
    }
}

struct AnsweredPrayerWidget: Widget {
    let kind = "AnsweredPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            AnsweredPrayerWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    if entry.snapshot.answeredCelebrationActive {
                        WidgetAnsweredGlow()
                    } else {
                        WidgetSanctuaryBackground()
                    }
                }
        }
        .configurationDisplayName("Answered Prayer")
        .description("Flips to a green celebration when you mark a prayer answered.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Lock Screen Widgets

struct SanctuaryLockCircularView: View {
    var entry: StreakEntry

    var body: some View {
        WidgetStreakRing(
            streak: entry.snapshot.currentStreak,
            weekFlags: entry.snapshot.weekCompletionFlags,
            diameter: 52,
            onDark: false
        )
        .widgetURL(DevotionDeepLink.url(host: .journal))
    }
}

struct VerseLockRectangularView: View {
    var entry: StreakEntry

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(WidgetPalette.pillPurple.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "text.quote")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WidgetPalette.pillPurple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.snapshot.quoteText)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .lineLimit(2)
                Text(entry.snapshot.quoteReference)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(DevotionDeepLink.url(host: .chaplain))
    }
}

struct SanctuaryLockInlineView: View {
    var entry: StreakEntry

    var body: some View {
        if entry.snapshot.isCompletedToday {
            Label(entry.snapshot.quoteReference, systemImage: "checkmark.seal.fill")
        } else {
            Label("\(entry.snapshot.currentStreak)d streak · begin devotion", systemImage: "flame.fill")
        }
    }
}

struct SanctuaryLockWidgetView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                SanctuaryLockCircularView(entry: entry)
            case .accessoryRectangular:
                VerseLockRectangularView(entry: entry)
            case .accessoryInline:
                SanctuaryLockInlineView(entry: entry)
            default:
                SanctuaryLockCircularView(entry: entry)
            }
        }
    }
}

struct SanctuaryLockWidgets: Widget {
    let kind = "SanctuaryLockWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            SanctuaryLockWidgetView(entry: entry)
                .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        }
        .configurationDisplayName("Sanctuary")
        .description("Streak ring, daily verse, or inline status.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct DevotionLockWidgetsBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        VerseWidget()
        PrayerWallWidget()
        AnsweredPrayerWidget()
        SanctuaryLockWidgets()
        JournalLiveActivityWidget()
        if #available(iOS 18.0, *) {
            BeginDevotionControl()
            AddPrayerControl()
            TodaysVerseControl()
        }
    }
}
