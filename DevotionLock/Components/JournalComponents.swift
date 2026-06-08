//
//  JournalComponents.swift
//  DevotionLock
//
//  Mobbin refs: ABY Journal timeline, Liven journal feed, Dot chronicle cards
//

import SwiftUI

extension Conversation {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Timeline")
                    .font(ABY.Font.section)
                    .foregroundStyle(palette.textTertiary)
                    .tracking(0.5)
                HStack(spacing: 6) {
                    Text("Journal")
                        .font(ABY.Font.title)
                        .foregroundStyle(palette.textPrimary)
                    Circle()
                        .fill(ABY.Color.accentDot)
                        .frame(width: 7, height: 7)
                }
            }

            if streak > 0 || entryCount > 0 {
                HStack(spacing: 8) {
                    if streak > 0 {
                        JournalStatChip(icon: "flame.fill", label: "\(streak) day streak", tint: ABY.Color.pillOrange)
                    }
                    if entryCount > 0 {
                        JournalStatChip(
                            icon: "book.pages.fill",
                            label: entryCount == 1 ? "1 entry" : "\(entryCount) entries",
                            tint: ABY.Color.pillPurple
                        )
                    }
                }
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
                .font(.system(size: 11, weight: .semibold))
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
                        .font(.system(size: 28))
                        .foregroundStyle(ABY.Color.pillPurple)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                JournalQuickEntryChip(icon: "sun.horizon.fill", label: "Devotion", tint: ABY.Color.pillTeal, action: onDevotion)
                JournalQuickEntryChip(icon: "pencil.and.outline", label: "Write", tint: ABY.Color.pillPurple, action: onAssisted)
                JournalQuickEntryChip(icon: "waveform", label: "Voice", tint: ABY.Color.pillOrange, action: onVoice)
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
                    .font(.system(size: 16, weight: .semibold))
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
                    .font(.system(size: 18, weight: .semibold))
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
                        .font(.system(size: 12, weight: .semibold))
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
                        .font(.system(size: 11, weight: .semibold))
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
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation
    var isLastInSection: Bool = false
    var onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                JournalTimeRail(date: conversation.recordedAt, timeLabel: conversation.timelineTime)

                if !isLastInSection {
                    Rectangle()
                        .fill(palette.divider.opacity(0.8))
                        .frame(width: 1.5)
                        .frame(minHeight: 28)
                        .padding(.top, 8)
                }
            }
            .frame(width: 44)

            JournalEntryCard(conversation: conversation, onTap: onTap)
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
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.textPrimary)
                .monospacedDigit()

            if !hourMinute.period.isEmpty {
                Text(hourMinute.period.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
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
                            .font(.system(size: 22))
                        ZStack {
                            Circle()
                                .fill(conversation.journalAccent.opacity(0.14))
                                .frame(width: 28, height: 28)
                            Image(systemName: conversation.journalIcon)
                                .font(.system(size: 11, weight: .semibold))
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
                        .font(.system(size: 15, weight: .regular, design: .serif))
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
                        .font(.system(size: 12, weight: .semibold))
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
                    .font(.system(size: 9, weight: .semibold))
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
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ABY.Color.pillPurple.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "book.pages")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(ABY.Color.pillPurple)
            }

            VStack(spacing: 6) {
                Text("Your timeline is quiet")
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Text("Start with a devotion, write a reflection, or capture a voice note.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button(action: onAdd) {
                Text("Add your first entry")
                    .font(ABY.Font.button)
                    .foregroundStyle(palette.buttonForeground)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(palette.buttonFill)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
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
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ABY.Color.pillPurple)
                Text("Add entry")
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textSecondary)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "sun.horizon.fill")
                    Image(systemName: "pencil")
                    Image(systemName: "waveform")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(palette.textTertiary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.textTertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.glass, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.glass, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Detail view

struct JournalDetailHero: View {
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(conversation.moodEmoji)
                            .font(.system(size: 28))
                        MoodPill(label: conversation.moodLabel)
                    }
                    Text(conversation.timelineTime)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(conversation.journalAccent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: conversation.journalIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(conversation.journalAccent)
                }
            }

            Text(conversation.preview)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                JournalTagChip(label: conversation.tag, tint: conversation.journalAccent)
                JournalTagChip(label: conversation.duration, icon: "clock", tint: palette.textTertiary)
                JournalTagChip(label: conversation.timeAgo, icon: "calendar", tint: palette.textTertiary)
            }
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous)
                .fill(palette.surface)
                .overlay(alignment: .topLeading) {
                    LinearGradient(
                        colors: [
                            conversation.journalAccent.opacity(palette.isNight ? 0.22 : 0.14),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous))
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge + 4, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
    }
}

struct JournalTranscriptRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let segment: TranscriptSegment
    var isUser: Bool { segment.speaker == "You" }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(isUser ? ABY.Color.pillTeal.opacity(0.14) : ABY.Color.pillPurple.opacity(0.14))
                    .frame(width: 32, height: 32)
                Image(systemName: isUser ? "person.fill" : "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isUser ? ABY.Color.pillTeal : ABY.Color.pillPurple)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(segment.speaker)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textSecondary)
                    Text(segment.timestamp)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }

                Text(segment.text)
                    .font(isUser ? ABY.Font.body : .system(size: 15, weight: .regular, design: .serif))
                    .foregroundStyle(palette.textPrimary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isUser ? palette.surface : palette.surface.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.card, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
    }
}
