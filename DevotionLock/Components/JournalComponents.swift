//
//  JournalComponents.swift
//  DevotionLock
//
//  Mobbin refs: ABY Journal timeline, Liven journal feed, Dot chronicle cards
//

import SwiftUI

extension Conversation {
    /// User-facing snippet for timeline cards — prefer the person's words over Chaplain replies.
    var timelinePreview: String {
        if let userLine = transcript.first(where: { $0.speaker == "You" })?.text {
            let trimmed = userLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        if ConversationMerger.isChaplainChat(self),
           !title.isEmpty,
           title != "Chaplain Conversation" {
            return title
        }
        return preview
    }

    var timelineDateLabel: String {
        if let recordedAt {
            if Calendar.current.isDateInToday(recordedAt) { return "Today" }
            if Calendar.current.isDateInYesterday(recordedAt) { return "Yesterday" }
            return recordedAt.formatted(.dateTime.weekday(.wide).day())
        }
        return isToday ? "Today" : timeAgo
    }

    var timelineEmojiSuffix: String {
        switch tag.lowercased() {
        case "voice": "🎙️"
        case "scripture": "📖"
        case "gratitude": "🙏"
        case "prayer": "✨"
        default: ""
        }
    }

    /// Leading emoji on ABY timeline cards — entry type when tagged, else mood.
    var journalEntryEmoji: String {
        if !timelineEmojiSuffix.isEmpty { return timelineEmojiSuffix }
        if !moodEmoji.isEmpty { return moodEmoji }
        return "📝"
    }

    var journalIcon: String {
        switch tag.lowercased() {
        case "scripture": "book.closed.fill"
        case "gratitude": "heart.fill"
        case "prayer": "hands.sparkles.fill"
        case "reflection": "sparkles"
        case "chaplain": "ellipsis.bubble.fill"
        case "voice": "waveform"
        default: "ellipsis.bubble.fill"
        }
    }

    var journalAccent: Color {
        switch tag.lowercased() {
        case "scripture": ABY.Color.pillPurple
        case "gratitude": ABY.Color.pillOrange
        case "prayer": ABY.Color.pillTeal
        case "reflection": ABY.Color.pillPink
        case "chaplain": ABY.Color.pillPurple
        case "voice": ABY.Color.pillOrange
        default: ABY.Color.pillPurple.opacity(0.85)
        }
    }
}

// MARK: - Screen chrome

struct JournalTimelineHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let streak: Int
    let entryCount: Int
    var onStreakTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Timeline")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
                Text("Today")
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)
                if entryCount > 0 {
                    Text(entryCount == 1 ? "1 entry" : "\(entryCount) entries")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }
            }

            Spacer(minLength: 0)

            if streak > 0, let onStreakTap {
                Button(action: onStreakTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(ABY.Font.captionSemibold)
                        Text("\(streak)")
                            .font(ABY.Font.captionSemibold)
                    }
                    .foregroundStyle(ABY.Color.pillOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(ABY.Color.pillOrange.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct JournalStatChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let icon: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(ABY.Font.emojiSmall)
            Text(label)
                .font(ABY.Font.captionMedium)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(tint.opacity(palette.isNight ? 0.18 : 0.12))
        .clipShape(Capsule())
    }
}

struct JournalDayHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String

    var body: some View {
        Text(title)
            .font(ABY.Font.title2)
            .foregroundStyle(palette.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Entry hub cards

/// Liven-style prompt card — Mobbin: https://mobbin.com/screens/8d10063c-ceff-4668-a314-0714cded6d09
struct JournalTodayCaptureCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onWrite: () -> Void
    var onDevotion: () -> Void
    var onVoice: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(ABY.Font.captionSemibold)
                Text("Capture today")
                    .font(ABY.Font.captionMedium)
            }
            .foregroundStyle(ABY.Color.pillTeal)

            Text("What's on your mind?")
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)

            Text("Write out your thoughts, start a devotion, or leave a voice note.")
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                JournalQuickEntryChip(icon: "pencil.and.outline", label: "Write", tint: ABY.Color.pillPurple, action: onWrite)
                JournalQuickEntryChip(icon: "sun.horizon.fill", label: "Devotion", tint: ABY.Color.pillTeal, action: onDevotion)
                if let onVoice, FeatureFlags.voiceChatEnabled {
                    JournalQuickEntryChip(icon: "waveform", label: "Voice", tint: ABY.Color.pillOrange, action: onVoice)
                }
            }
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous)
                .fill(Color.white)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [ABY.Color.pillTeal.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 160, height: 160)
                        .offset(x: 30, y: -30)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 4)
    }
}

struct JournalEntryHub: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onDevotion: () -> Void
    var onAssisted: () -> Void
    var onVoice: () -> Void
    var onOpenHub: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capture today")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("Devotion, writing, or a voice note")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
                Button(action: onOpenHub) {
                    Image(systemName: "plus.circle.fill")
                        .font(ABY.Font.title)
                        .foregroundStyle(ABY.Color.pillPurple)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                JournalQuickEntryChip(icon: "sun.horizon.fill", label: "Devotion", tint: ABY.Color.pillTeal, action: onDevotion)
                JournalQuickEntryChip(icon: "pencil.and.outline", label: "Write", tint: ABY.Color.pillPurple, action: onAssisted)
                if FeatureFlags.voiceChatEnabled {
                    JournalQuickEntryChip(icon: "waveform", label: "Voice", tint: ABY.Color.pillOrange, action: onVoice)
                }
            }
        }
        .padding(ABY.Spacing.card)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
    }
}

struct JournalQuickEntryChip: View {
    let icon: String
    let label: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(ABY.Font.bodySemibold)
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12))
                    .clipShape(Circle())
                Text(label)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(tint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(tint.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct JournalEntryOptionCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let badge: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(ABY.Font.headline)
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text(subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Text(badge)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tint.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Prompt card (legacy devotion CTA)

struct JournalPromptCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onBegin: () -> Void

    var body: some View {
        Button(action: onBegin) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(ABY.Font.captionSemibold)
                    Text("Begin devotion")
                        .font(ABY.Font.captionMedium)
                }
                .foregroundStyle(ABY.Color.pillTeal)

                Text("What's on your heart?")
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Capture a morning reflection, prayer, or quiet moment with your Chaplain.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Text("Start today's entry")
                        .font(ABY.Font.captionMedium)
                    Image(systemName: "arrow.right")
                        .font(ABY.Font.emojiSmall)
                }
                .foregroundStyle(palette.buttonForeground)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(palette.buttonFill)
                .clipShape(Capsule())
            }
            .padding(ABY.Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous)
                    .fill(palette.surface)
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [ABY.Color.pillTeal.opacity(0.22), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 140, height: 140)
                            .offset(x: 24, y: -24)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
            .shadow(color: .black.opacity(palette.isNight ? 0.2 : 0.05), radius: 12, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Timeline entry (ABY Journal + Liven rail)

struct JournalTimelineEntry: View {
    let conversation: Conversation
    var isEarlier: Bool = false
    var isLastInSection: Bool = false
    var onTap: () -> Void

    private var isVoiceEntry: Bool {
        conversation.tag.lowercased() == "voice"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ABYTimelineRail(
                time: conversation.timelineTime,
                showsConnector: !isLastInSection
            )

            ABYTimelineEntryCard(
                dateLabel: isEarlier ? conversation.timelineDateLabel : "",
                moodEmoji: conversation.moodEmoji,
                moodLabel: conversation.moodLabel,
                bodyText: conversation.timelinePreview,
                entryEmoji: conversation.journalEntryEmoji,
                secondaryEmojis: conversation.timelineEmojiSuffix,
                voiceDuration: isVoiceEntry ? conversation.duration : nil,
                showsMetadata: false,
                onTap: onTap
            )
        }
    }
}

struct JournalTimeRail: View {
    @Environment(\.sanctuaryPalette) private var palette
    let date: Date?
    let timeLabel: String

    private var hourMinute: (hour: String, period: String) {
        if let date {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm"
            let hour = formatter.string(from: date)
            formatter.dateFormat = "a"
            let period = formatter.string(from: date)
            return (hour, period)
        }

        let parts = timeLabel.split(separator: " ")
        if parts.count >= 2 {
            return (String(parts[0]), String(parts[1]))
        }
        return (timeLabel, "")
    }

    var body: some View {
        VStack(spacing: 3) {
            Circle()
                .fill(ABY.Color.pillPurple.opacity(0.85))
                .frame(width: 7, height: 7)

            Text(hourMinute.hour)
                .font(ABY.Font.footnoteSemibold)
                .foregroundStyle(palette.textPrimary)
                .monospacedDigit()

            if !hourMinute.period.isEmpty {
                Text(hourMinute.period.uppercased())
                    .font(ABY.Font.microBold)
                    .foregroundStyle(palette.textTertiary)
                    .tracking(0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

struct JournalTimeBubble: View {
    @Environment(\.sanctuaryPalette) private var palette
    let time: String

    var body: some View {
        Text(time)
            .font(ABY.Font.captionMedium)
            .foregroundStyle(palette.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}

struct JournalEntryCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        Text(conversation.moodEmoji)
                            .font(ABY.Font.title2)
                        ZStack {
                            Circle()
                                .fill(conversation.journalAccent.opacity(0.14))
                                .frame(width: 28, height: 28)
                            Image(systemName: conversation.journalIcon)
                                .font(ABY.Font.emojiSmall)
                                .foregroundStyle(conversation.journalAccent)
                        }
                    }

                    Spacer(minLength: 8)

                    MoodPill(label: conversation.moodLabel)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(conversation.title)
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(conversation.preview)
                        .font(ABY.Font.editorialCallout)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(3)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 8) {
                    JournalTagChip(label: conversation.tag, tint: conversation.journalAccent)
                    JournalTagChip(label: conversation.duration, icon: "clock", tint: palette.textTertiary)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(ABY.Font.captionSemibold)
                        .foregroundStyle(palette.textTertiary)
                }
            }
            .padding(ABY.Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 2, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 2, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
            .shadow(color: .black.opacity(palette.isNight ? 0.25 : 0.05), radius: 10, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct JournalTagChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String
    var icon: String? = nil
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(ABY.Font.microBold)
            }
            Text(label)
                .font(ABY.Font.captionMedium)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(palette.isNight ? 0.16 : 0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Empty state & composer

struct JournalEmptyState: View {
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        VStack(spacing: 20) {
            DevotionLockBrandMark(size: 72, showsShadow: true)

            VStack(spacing: 8) {
                Text("Your timeline is quiet")
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Text("Tap below to capture your first reflection.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

struct JournalComposerBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            Text("Add for today")
                .font(ABY.Font.body)
                .foregroundStyle(palette.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.07), radius: 14, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Entry detail (Pi / pillowtalk transcript refs)

struct ABYEntryMessageView: View {
    @Environment(\.sanctuaryPalette) private var palette
    let segment: TranscriptSegment

    private var isUser: Bool { segment.speaker == "You" }

    var body: some View {
        if isUser {
            HStack {
                Spacer(minLength: 48)
                Text(segment.text)
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textPrimary)
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(ABY.Color.moodPeach.opacity(0.38))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        } else {
            Text(segment.text)
                .font(ABY.Font.editorialCallout)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Journal screen (Stoic / How We Feel / Calm-inspired)

enum JournalBrowseMode: String, CaseIterable, Identifiable {
    case timeline
    case rhythms
    case prompts

    var id: String { rawValue }

    var label: String {
        switch self {
        case .timeline: "Timeline"
        case .rhythms: "Rhythms"
        case .prompts: "Prompts"
        }
    }
}

struct JournalDayGroup: Identifiable {
    let id: String
    let title: String
    let entries: [Conversation]
}

enum JournalPromptLibrary {
    static let prompts: [(icon: String, tint: Color, text: String)] = [
        ("heart.fill", ABY.Color.pillPink, "What's on your heart right now?"),
        ("sparkles", ABY.Color.pillPurple, "Where did you sense God today?"),
        ("cloud.rain.fill", ABY.Color.pillTeal, "What felt heavy — or surprisingly light?"),
        ("hands.sparkles.fill", ABY.Color.pillOrange, "What are you grateful for in this moment?"),
        ("moon.stars.fill", ABY.Color.meshPeriwinkle, "What do you need to release before tomorrow?"),
        ("book.closed.fill", ABY.Color.journalPromptAccent, "What scripture is speaking to you?"),
    ]
}

extension Array where Element == Conversation {
    func groupedByJournalDay() -> [JournalDayGroup] {
        let calendar = Calendar.current
        var buckets: [Date: [Conversation]] = [:]

        for entry in self {
            let day = calendar.startOfDay(for: entry.recordedAt ?? Date())
            buckets[day, default: []].append(entry)
        }

        return buckets.keys.sorted(by: >).map { day in
            JournalDayGroup(
                id: day.ISO8601Format(),
                title: journalDayTitle(for: day),
                entries: buckets[day] ?? []
            )
        }
    }
}

private func journalDayTitle(for date: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) { return "Today" }
    if calendar.isDateInYesterday(date) { return "Yesterday" }
    return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
}

struct JournalScreenHeader: View {
    let streak: Int
    var onStreakTap: (() -> Void)? = nil

    var body: some View {
        ABYScreenHeader(title: "Journal", subtitle: "Your reflection history") {
            if streak > 0, let onStreakTap {
                Button(action: onStreakTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(ABY.Font.footnoteSemibold)
                        Text("\(streak)")
                            .font(ABY.Font.captionSemibold)
                    }
                    .foregroundStyle(ABY.Color.pillOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(ABY.Color.pillOrange.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct JournalBrowseSegment: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var mode: JournalBrowseMode

    var body: some View {
        HStack(spacing: 6) {
            ForEach(JournalBrowseMode.allCases) { option in
                Button {
                    withAnimation(AppTheme.springSnappy) { mode = option }
                } label: {
                    Text(option.label)
                        .font(mode == option ? ABY.Font.captionSemibold : ABY.Font.captionMedium)
                        .foregroundStyle(mode == option ? palette.textPrimary : palette.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if mode == option {
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(palette.track.opacity(0.55))
        .clipShape(Capsule())
    }
}

/// Hero card for the most recent reflection — How We Feel / Calm mood card pattern.
struct JournalFeaturedReflectionCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    JournalEntryTypeBadge(conversation: conversation)
                    Spacer(minLength: 0)
                    Text(conversation.timelineTime)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("I'm feeling")
                        .font(ABY.Font.editorialAccent)
                        .foregroundStyle(palette.textSecondary)
                    HStack(spacing: 8) {
                        Text(conversation.moodEmoji)
                            .font(ABY.Font.title)
                        Text(conversation.moodLabel.lowercased())
                            .font(ABY.Font.editorialTitle)
                            .foregroundStyle(conversation.journalAccent)
                    }
                }

                Text(conversation.timelinePreview)
                    .font(ABY.Font.editorialBody)
                    .foregroundStyle(palette.textPrimary)
                    .lineSpacing(5)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(ABY.Spacing.card + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                conversation.journalAccent.opacity(0.14),
                                Color.white,
                                ABY.Color.sanctuaryGradientBottom.opacity(0.35),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 6, style: .continuous)
                    .stroke(conversation.journalAccent.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: conversation.journalAccent.opacity(0.12), radius: 16, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Compact Stoic-style card — type badge, time, preview snippet.
struct JournalCompactReflectionCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(conversation.journalAccent.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Text(conversation.journalEntryEmoji)
                        .font(ABY.Font.title2)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        JournalEntryTypeBadge(conversation: conversation)
                        Spacer(minLength: 8)
                        Text(conversation.timelineTime)
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textTertiary)
                    }

                    Text(conversation.timelinePreview)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !conversation.moodLabel.isEmpty {
                        ABYMoodChip(emoji: conversation.moodEmoji, label: conversation.moodLabel)
                    }
                }
            }
            .padding(ABY.Spacing.card)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct JournalEntryTypeBadge: View {
    let conversation: Conversation

    private var label: String {
        switch conversation.tag.lowercased() {
        case "scripture": "DEVOTION"
        case "voice": "VOICE"
        case "chaplain": "CHAPLAIN"
        case "reflection": "JOURNAL"
        case "gratitude": "GRATITUDE"
        case "prayer": "PRAYER"
        default: conversation.tag.uppercased()
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: conversation.journalIcon)
                .font(ABY.Font.microBold)
            Text(label)
                .font(ABY.Font.paywallPromoBadge)
                .tracking(0.6)
        }
        .foregroundStyle(conversation.journalAccent)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(conversation.journalAccent.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct JournalDaySectionHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    let entryCount: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(ABY.Font.title2)
                .foregroundStyle(palette.textPrimary)
            Spacer(minLength: 8)
            Text(entryCount == 1 ? "1 entry" : "\(entryCount) entries")
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textTertiary)
        }
    }
}

struct JournalRhythmsPanel: View {
    @Environment(\.sanctuaryPalette) private var palette
    let rhythmStore: DailyRhythmStore
    var onRing: (DailyRhythmRing) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily rhythms")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textSecondary)
                .tracking(0.5)

            VStack(spacing: 10) {
                ForEach(DailyRhythmRing.allCases) { ring in
                    JournalRhythmRow(
                        ring: ring,
                        isComplete: rhythmStore.isComplete(ring),
                        onTap: { onRing(ring) }
                    )
                }
            }
        }
        .id(rhythmStore.revision)
    }
}

private struct JournalRhythmRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let ring: DailyRhythmRing
    let isComplete: Bool
    let onTap: () -> Void

    private var accent: Color {
        Color(
            red: Double((ring.accentHex >> 16) & 0xFF) / 255,
            green: Double((ring.accentHex >> 8) & 0xFF) / 255,
            blue: Double(ring.accentHex & 0xFF) / 255
        )
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isComplete ? accent : palette.track, lineWidth: isComplete ? 3 : 2)
                        .frame(width: 48, height: 48)
                    Image(systemName: ring.icon)
                        .font(ABY.Font.headline)
                        .foregroundStyle(isComplete ? accent : palette.textTertiary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(ring.label)
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text(isComplete ? "Completed today" : "Tap to begin")
                        .font(ABY.Font.caption)
                        .foregroundStyle(isComplete ? accent : palette.textTertiary)
                }

                Spacer(minLength: 0)

                Image(systemName: isComplete ? "checkmark.circle.fill" : "chevron.right")
                    .font(AppFont.font(size: isComplete ? 18 : 12, weight: .semibold))
                    .foregroundStyle(isComplete ? accent : palette.textTertiary)
            }
            .padding(ABY.Spacing.card)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct JournalPromptsPanel: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Writing prompts")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textSecondary)
                .tracking(0.5)

            VStack(spacing: 10) {
                ForEach(Array(JournalPromptLibrary.prompts.enumerated()), id: \.offset) { _, prompt in
                    Button(action: onSelect) {
                        HStack(spacing: 14) {
                            Image(systemName: prompt.icon)
                                .font(ABY.Font.bodySemibold)
                                .foregroundStyle(prompt.tint)
                                .frame(width: 40, height: 40)
                                .background(prompt.tint.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            Text(prompt.text)
                                .font(ABY.Font.callout)
                                .foregroundStyle(palette.textPrimary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "arrow.up.right")
                                .font(ABY.Font.captionSemibold)
                                .foregroundStyle(palette.textTertiary)
                        }
                        .padding(ABY.Spacing.card)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                                .stroke(palette.divider, lineWidth: 1)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
}
