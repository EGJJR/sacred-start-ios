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

    private var completed: Bool { entry.snapshot.isCompletedToday }

    private var headline: String {
        if completed { return "You showed up today" }
        if entry.snapshot.currentStreak >= 3 { return "Keep the rhythm" }
        return "Begin your devotion"
    }

    private var subtitle: String {
        if completed { return "Sanctuary kept" }
        return "A few quiet minutes"
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        ZStack {
            WidgetAdaptiveBackground(completed: completed)

            WidgetPaperCard(cornerRadius: 18, peachAccent: !completed) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        WidgetStreakRing(
                            streak: entry.snapshot.currentStreak,
                            weekFlags: entry.snapshot.weekCompletionFlags,
                            diameter: 56,
                            accent: completed ? WidgetPalette.orbSage : WidgetPalette.pillOrange
                        )
                        Spacer(minLength: 0)
                        if completed {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(WidgetPalette.orbSage)
                        }
                    }

                    Text(subtitle.uppercased())
                        .font(WidgetTypography.micro(8))
                        .tracking(0.6)
                        .foregroundStyle(WidgetPalette.textTertiary)
                        .padding(.top, 10)

                    Text(headline)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .padding(.top, 3)

                    Spacer(minLength: 8)

                    WidgetWeekRingRow(flags: entry.snapshot.weekCompletionFlags, compact: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .padding(10)
        }
        .widgetURL(DevotionDeepLink.url(host: completed ? .home : .journal))
    }

    private var mediumView: some View {
        ZStack {
            WidgetAdaptiveBackground(completed: completed)

            HStack(spacing: 0) {
                WidgetPaperCard(cornerRadius: 22, peachAccent: !completed) {
                    HStack(spacing: 14) {
                        WidgetStreakRing(
                            streak: entry.snapshot.currentStreak,
                            weekFlags: entry.snapshot.weekCompletionFlags,
                            diameter: 78,
                            accent: completed ? WidgetPalette.orbSage : WidgetPalette.pillOrange
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(subtitle.uppercased())
                                .font(WidgetTypography.micro(9))
                                .tracking(0.7)
                                .foregroundStyle(WidgetPalette.moodPeachText.opacity(completed ? 0.7 : 1))

                            Text(headline)
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundStyle(WidgetPalette.textPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)

                            WidgetWeekRingRow(flags: entry.snapshot.weekCompletionFlags)
                                .padding(.top, 4)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(14)
                }
                .padding(12)
            }
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
                    WidgetAdaptiveBackground(completed: entry.snapshot.isCompletedToday)
                }
        }
        .configurationDisplayName("Morning Streak")
        .description("Your devotion streak and weekly rhythm at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Verse Widget

struct VerseWidgetView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    private var quoteSize: CGFloat {
        switch family {
        case .systemLarge: 26
        case .systemMedium: 17
        default: 15
        }
    }

    private var dateLabel: String {
        Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        ZStack {
            WidgetSanctuaryBackground()

            WidgetPaperCard(cornerRadius: family == .systemLarge ? 24 : 20, peachAccent: true) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        WidgetBrandMark(compact: true)
                        Spacer()
                        Text(dateLabel.uppercased())
                            .font(WidgetTypography.micro(8))
                            .tracking(0.6)
                            .foregroundStyle(WidgetPalette.textTertiary)
                    }
                    .padding(.bottom, family == .systemLarge ? 14 : 10)

                    WidgetQuoteMark(size: family == .systemLarge ? 44 : 32)
                        .padding(.bottom, family == .systemLarge ? 6 : 2)

                    Text(entry.snapshot.quoteText)
                        .font(WidgetTypography.quote(quoteSize))
                        .foregroundStyle(WidgetPalette.textPrimary)
                        .lineSpacing(family == .systemLarge ? 8 : 5)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: family == .systemLarge ? 16 : 10)

                    HStack {
                        WidgetVerseReferencePill(reference: entry.snapshot.quoteReference)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WidgetPalette.textTertiary)
                            .padding(8)
                            .background(WidgetPalette.textPrimary.opacity(0.05))
                            .clipShape(Circle())
                    }
                }
                .padding(family == .systemLarge ? 18 : 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(family == .systemLarge ? 14 : 12)
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Label("Prayer wall", systemImage: "hands.sparkles.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.pillPurple)
                Spacer()
                Text("\(entry.snapshot.prayerRequestCount)")
                    .font(WidgetTypography.label(10))
                    .foregroundStyle(WidgetPalette.pillPurple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WidgetPalette.pillPurple.opacity(0.10))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 10)

            if let note = entry.snapshot.prayerNotes.first {
                WidgetPaperNote(
                    text: note.text,
                    kind: note.kind,
                    tintIndex: note.tintIndex,
                    rotation: note.rotation * 0.5,
                    compact: true
                )
            } else {
                WidgetPaperCard(cornerRadius: 12, peachAccent: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pin your first prayer")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(WidgetPalette.textPrimary)
                        Text("Requests & reminders stay close.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(WidgetPalette.textSecondary)
                    }
                    .padding(10)
                }
            }

            Spacer(minLength: 8)

            Link(destination: DevotionDeepLink.url(host: .addPrayer, query: ["kind": "request"])!) {
                WidgetActionChip(title: "Add prayer", icon: "plus", tint: WidgetPalette.pillPurple)
            }
        }
        .padding(12)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Prayer wall")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.textPrimary)
                    Text("\(entry.snapshot.prayerRequestCount) active · \(entry.snapshot.prayerAnsweredCount) answered")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetPalette.textSecondary)
                }
                Spacer()
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(WidgetPalette.pillPurple.opacity(0.55))
            }
            .padding(.bottom, 12)

            HStack(alignment: .top, spacing: 6) {
                ForEach(entry.snapshot.prayerNotes.prefix(3)) { note in
                    WidgetPaperNote(
                        text: note.text,
                        kind: note.kind,
                        tintIndex: note.tintIndex,
                        rotation: note.rotation * 0.7,
                        compact: true
                    )
                }
            }

            Spacer(minLength: 10)

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
                WidgetPaperCard(cornerRadius: 18, peachAccent: false) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(WidgetPalette.orbSage)
                            .symbolEffect(.bounce, value: entry.snapshot.updatedAt)

                        Text("Answered!")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetPalette.orbSage)

                        if let text = entry.snapshot.answeredCelebrationText {
                            Text(text)
                                .font(WidgetTypography.quote(12))
                                .foregroundStyle(WidgetPalette.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                }
                .padding(10)
            } else {
                WidgetSanctuaryBackground()
                WidgetPaperCard(cornerRadius: 18, peachAccent: true) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Prayer wall", systemImage: "hands.sparkles.fill")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(WidgetPalette.pillPurple)

                        Text("\(entry.snapshot.prayerAnsweredCount) answered")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetPalette.textPrimary)

                        Text("Mark a prayer done to celebrate here.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(WidgetPalette.textSecondary)
                            .lineLimit(2)

                        if let note = entry.snapshot.prayerNotes.first(where: { $0.kind == "request" }) ?? entry.snapshot.prayerNotes.first {
                            WidgetPaperNote(
                                text: note.text,
                                kind: note.kind,
                                tintIndex: note.tintIndex,
                                rotation: note.rotation * 0.4,
                                compact: true
                            )
                            .padding(.top, 2)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(10)
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
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(WidgetPalette.moodPeach.opacity(0.85))
                    .frame(width: 34, height: 34)
                Image(systemName: "text.quote")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WidgetPalette.moodPeachText)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.snapshot.quoteText)
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .lineLimit(2)
                Text(entry.snapshot.quoteReference)
                    .font(WidgetTypography.micro(9))
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
