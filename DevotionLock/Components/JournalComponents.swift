//
//  JournalComponents.swift
//  DevotionLock
//
//  Mobbin refs: ABY Journal timeline, Liven journal feed, Dot chronicle cards
//

import SwiftUI

extension Conversation {
    var primaryUserText: String {
        if let userLine = transcript.first(where: { $0.speaker == "You" })?.text {
            let trimmed = userLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return preview.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var wordCount: Int {
        primaryUserText.split { $0.isWhitespace || $0.isNewline }.count
    }

    /// One-line mood check-ins and quick Chaplain pings — too thin for a document page.
    var isThinCapture: Bool {
        wordCount < ConversationMerger.journalSubstanceWordThreshold
            && transcript.filter { $0.speaker == "You" }.count <= 1
    }

    /// Reflections long enough to earn a journal card (voice, devotion, written).
    var isSubstantiveReflection: Bool {
        if ConversationMerger.isChaplainChat(self) { return false }

        let tag = tag.lowercased()
        if tag == "voice" { return !primaryUserText.isEmpty }

        let capturedPracticeTags = ["scripture", "devotion", "prayer", "gratitude", "reflection"]
        if capturedPracticeTags.contains(tag) {
            return !primaryUserText.isEmpty
        }

        if wordCount >= ConversationMerger.journalSubstanceWordThreshold { return true }
        return transcript.count > 1
    }

    /// Chat thread layout (Pi / Wysa) vs long-form journal read.
    var prefersChatStyleDetail: Bool {
        if ConversationMerger.isChaplainChat(self) { return true }
        if transcript.contains(where: { $0.speaker == "Chaplain" }) { return true }
        return isThinCapture
    }

    var detailDisplayTitle: String {
        if ConversationMerger.isChaplainChat(self) {
            return chaplainHistoryTitle
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.hasPrefix("Morning —")
            || trimmedTitle.hasPrefix("Evening —")
            || trimmedTitle == "Journal entry" {
            let body = primaryUserText
            if !body.isEmpty { return body }
        }
        return trimmedTitle
    }

    /// User-facing snippet for timeline cards — prefer the person's words over Chaplain replies.
    var timelinePreview: String {
        if let userLine = transcript.first(where: { $0.speaker == "You" })?.text {
            let trimmed = userLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }

        let trimmedPreview = preview.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPreview.isEmpty,
           !isGenericTimelineTitle(trimmedPreview) {
            return trimmedPreview
        }

        if ConversationMerger.isChaplainChat(self) {
            return chaplainHistoryTitle
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty, !isGenericTimelineTitle(trimmedTitle) {
            return trimmedTitle
        }

        return trimmedPreview.isEmpty ? "A quiet moment captured." : trimmedPreview
    }

    private func isGenericTimelineTitle(_ value: String) -> Bool {
        value == "Chaplain Conversation"
            || value == "Chaplain Chat"
            || value.hasPrefix("Morning —")
            || value.hasPrefix("Evening —")
            || value == "Journal entry"
            || value == "Voice note"
    }

    var timelineMoodLabel: String {
        let label = moodLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty, label != "Present" else { return "" }
        return label
    }

    /// Prompt shown on the journal read screen — prefer the writing question over generic titles.
    var journalReadPrompt: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty, !isGenericTimelineTitle(trimmedTitle) {
            return trimmedTitle
        }
        return "What's on your mind?"
    }

    var journalReadBody: String {
        let body = primaryUserText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !body.isEmpty { return body }
        return preview.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Single-block reflections the user can revise (guided entry, voice transcript).
    @MainActor
    var isEditableJournalEntry: Bool {
        if ConversationMerger.isChaplainChat(self) { return false }
        if transcript.contains(where: { segment in
            let speaker = segment.speaker.lowercased()
            return speaker != "you" && speaker != "user"
        }) {
            return false
        }
        guard !journalReadBody.isEmpty else { return false }
        guard let local = JournalLocalStore.shared.entry(id: id) else { return false }
        return local.kind == .assisted || local.kind == .voiceNote
    }

    var journalReadDateLabel: String {
        guard let recordedAt else { return timelineDateLabel.uppercased() }
        return recordedAt
            .formatted(.dateTime.month(.abbreviated).day().year())
            .uppercased()
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
        switch tag.lowercased() {
        case "chaplain": return "💭"
        case "voice": return "🎙️"
        case "scripture", "devotion": return "📖"
        case "gratitude": return "🙏"
        case "prayer": return "✨"
        case "reflection": return "✍️"
        default: break
        }
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

/// Open-ended writing prompt for the Prompts tab.
struct JournalFreeWritePromptCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onWrite: () -> Void

    private let cornerRadius: CGFloat = 24

    var body: some View {
        Button(action: onWrite) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.and.outline")
                        .font(ABY.Font.captionSemibold)
                    Text("Free write")
                        .font(ABY.Font.captionMedium)
                        .tracking(0.35)
                }
                .foregroundStyle(ABY.Color.pillPurple)

                Text("What's on your mind?")
                    .font(ABY.Font.editorialTitle)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Write freely — no template required.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text("Start writing")
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
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { freeWriteCardBackground }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(palette.isNight ? 0.08 : 0.72), lineWidth: 1)
            }
            .shadow(color: .black.opacity(palette.isNight ? 0.24 : 0.07), radius: 18, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private var freeWriteCardBackground: some View {
        ZStack {
            palette.isNight ? palette.surface : Color.white

            RadialGradient(
                colors: [ABY.Color.meshLilac.opacity(0.3), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 200
            )

            RadialGradient(
                colors: [ABY.Color.pillPurple.opacity(0.14), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 160
            )
        }
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
    var dateLabel: String = ""
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
                dateLabel: dateLabel,
                moodEmoji: conversation.moodEmoji,
                moodLabel: conversation.timelineMoodLabel,
                bodyText: conversation.timelinePreview,
                entryEmoji: conversation.journalEntryEmoji,
                secondaryEmojis: conversation.timelineEmojiSuffix,
                voiceDuration: isVoiceEntry ? conversation.duration : nil,
                showsMetadata: false,
                onTap: onTap
            )
        }
        .padding(.bottom, isLastInSection ? 0 : 14)
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

// MARK: - Entry read (Mobbin: Calm reflection 4a64480ac, Liven History 862600c1)

struct JournalEntryReadCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let conversation: Conversation

    private let cornerRadius: CGFloat = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.journalReadDateLabel)
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(palette.textTertiary)
                        .tracking(0.6)

                    Text(conversation.timelineTime)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }

                Spacer(minLength: 8)

                if !conversation.timelineMoodLabel.isEmpty {
                    ABYMoodChip(
                        emoji: conversation.moodEmoji,
                        label: conversation.timelineMoodLabel
                    )
                }
            }

            HStack(spacing: 8) {
                JournalTagChip(
                    label: conversation.tag,
                    icon: conversation.journalIcon,
                    tint: conversation.journalAccent
                )
            }

            Text(conversation.journalReadPrompt)
                .font(ABY.Font.editorialTitle)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(palette.divider.opacity(0.55))
                .frame(height: 1)

            Text("Your reflection")
                .font(ABY.Font.section)
                .foregroundStyle(palette.textTertiary)
                .tracking(0.8)

            Text(conversation.journalReadBody)
                .font(ABY.Font.editorialBody)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { readCardBackground }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(palette.isNight ? 0.1 : 0.75), lineWidth: 1)
        }
        .shadow(color: .black.opacity(palette.isNight ? 0.28 : 0.08), radius: 20, y: 8)
    }

    @ViewBuilder
    private var readCardBackground: some View {
        ZStack {
            palette.isNight ? palette.surface : Color.white

            RadialGradient(
                colors: [conversation.journalAccent.opacity(0.1), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 180
            )

            RadialGradient(
                colors: [ABY.Color.meshLilac.opacity(0.08), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 160
            )
        }
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
                Text("Open Prompts and start writing.")
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
    static let templates: [JournalPromptTemplate] = [
        JournalPromptTemplate(
            id: "gratitude",
            title: "Morning Gratitude",
            preview: "Reflect on today's gifts",
            prompt: "What are you grateful for in this moment?"
        ),
        JournalPromptTemplate(
            id: "evening",
            title: "Evening Reflection",
            preview: "Reflect on your day",
            prompt: "What felt heavy — or surprisingly light?"
        ),
        JournalPromptTemplate(
            id: "presence",
            title: "God's Presence",
            preview: "Where you sensed Him today",
            prompt: "Where did you sense God today?"
        ),
        JournalPromptTemplate(
            id: "heart",
            title: "Heart Check-in",
            preview: "What's true right now",
            prompt: "What's on your heart right now?"
        ),
        JournalPromptTemplate(
            id: "scripture",
            title: "Scripture Moment",
            preview: "What scripture is speaking",
            prompt: "What scripture is speaking to you?"
        ),
        JournalPromptTemplate(
            id: "release",
            title: "Release & Rest",
            preview: "Let go before tomorrow",
            prompt: "What do you need to release before tomorrow?"
        ),
    ]

    static let dailyQuotes: [(text: String, attribution: String)] = [
        ("Be still, and know that I am God.", "Psalm 46:10"),
        ("The Lord is my shepherd; I shall not want.", "Psalm 23:1"),
        ("Cast all your anxiety on him because he cares for you.", "1 Peter 5:7"),
        ("Come to me, all you who are weary and burdened, and I will give you rest.", "Matthew 11:28"),
        ("Trust in the Lord with all your heart and lean not on your own understanding.", "Proverbs 3:5"),
    ]
}

struct JournalPromptTemplate: Identifiable {
    let id: String
    let title: String
    let preview: String
    let prompt: String
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
    @Namespace private var segmentNamespace

    var body: some View {
        HStack(spacing: 6) {
            ForEach(JournalBrowseMode.allCases) { option in
                Button {
                    guard mode != option else { return }
                    withAnimation(AppTheme.springSnappy) { mode = option }
                    DevotionHaptics.soft()
                } label: {
                    Text(option.label)
                        .font(mode == option ? ABY.Font.captionSemibold : ABY.Font.captionMedium)
                        .foregroundStyle(mode == option ? palette.textPrimary : palette.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if mode == option {
                                Capsule()
                                    .fill(palette.surface.opacity(0.96))
                                    .matchedGeometryEffect(id: "journalSegment", in: segmentNamespace)
                                    .shadow(color: .black.opacity(palette.isNight ? 0.28 : 0.06), radius: 8, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            ABYGlassBarBackground(cornerRadius: 999)
        }
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

// MARK: - Day insight (Mobbin ABY summary card 4f9d087f / 91b001e2)

enum JournalDayInsightBuilder {
    struct Insight: Equatable {
        let emojiRow: String
        let summary: String
        let moodEmoji: String
        let moodLabel: String
    }

    static func build(dayTitle: String, entries: [Conversation]) -> Insight? {
        guard entries.count >= 2 else { return nil }

        let moods: [(emoji: String, label: String)] = entries.compactMap { entry in
            let label = entry.timelineMoodLabel
            guard !label.isEmpty else { return nil }
            return (entry.moodEmoji, label)
        }

        let emojiRow = entries
            .map(\.journalEntryEmoji)
            .reduce(into: [String]()) { acc, emoji in
                if !acc.contains(emoji) { acc.append(emoji) }
            }
            .prefix(4)
            .joined(separator: " ")

        let dayRef: String = switch dayTitle {
        case "Today": "Today"
        case "Yesterday": "Yesterday"
        default: dayTitle
        }

        let uniqueMoodLabels = moods.map(\.label).reduce(into: [String]()) { acc, label in
            if !acc.contains(label) { acc.append(label) }
        }

        let summary: String
        if uniqueMoodLabels.count >= 2 {
            let moodPhrase = uniqueMoodLabels.prefix(2).map { $0.lowercased() }.joined(separator: " and ")
            summary = "\(dayRef) you leaned into \(moodPhrase) — \(entries.count) moments captured."
        } else if let mood = uniqueMoodLabels.first {
            summary = "\(dayRef) centered on \(mood.lowercased()) — \(entries.count) moments captured."
        } else if let kinds = entryKindPhrase(entries), !kinds.isEmpty {
            summary = "\(dayRef) held \(kinds) — \(entries.count) moments captured."
        } else {
            summary = "\(entries.count) reflections from \(dayRef.lowercased())."
        }

        let dominant = moods.first ?? (emoji: "😊", label: "Present")
        return Insight(
            emojiRow: emojiRow,
            summary: summary,
            moodEmoji: dominant.emoji.isEmpty ? "😊" : dominant.emoji,
            moodLabel: dominant.label
        )
    }

    private static func entryKindPhrase(_ entries: [Conversation]) -> String? {
        var kinds: [String] = []
        for entry in entries {
            switch entry.tag.lowercased() {
            case "chaplain":
                if !kinds.contains("conversation with Chaplain") { kinds.append("conversation with Chaplain") }
            case "voice":
                if !kinds.contains("voice notes") { kinds.append("voice notes") }
            case "reflection":
                if !kinds.contains("journal writing") { kinds.append("journal writing") }
            case "scripture", "devotion":
                if !kinds.contains("devotion") { kinds.append("devotion") }
            case "gratitude":
                if !kinds.contains("gratitude") { kinds.append("gratitude") }
            default:
                break
            }
        }
        guard !kinds.isEmpty else { return nil }
        return kinds.prefix(2).joined(separator: " and ")
    }
}

/// ABY day rollup — narrative summary above the rail when a day has multiple entries.
struct JournalDayInsightCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let dayTitle: String
    let insight: JournalDayInsightBuilder.Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(dayTitle)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
                Spacer(minLength: 8)
                ABYMoodChip(emoji: insight.moodEmoji, label: insight.moodLabel)
            }

            if !insight.emojiRow.isEmpty {
                Text(insight.emojiRow)
                    .font(ABY.Font.title2)
            }

            Text(insight.summary)
                .font(ABY.Font.editorialBody)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.isNight ? palette.surface : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(palette.isNight ? 0.22 : 0.06), radius: 14, y: 5)
    }
}

struct JournalRhythmsPanel: View {
    @Environment(\.sanctuaryPalette) private var palette
    let rhythmStore: DailyRhythmStore
    var onRing: (DailyRhythmRing) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's rhythm")
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
    var onFreeWrite: () -> Void
    var onSelect: (JournalPromptTemplate) -> Void

    @State private var quoteIndex = 0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var currentQuote: (text: String, attribution: String) {
        let quotes = JournalPromptLibrary.dailyQuotes
        return quotes[quoteIndex % quotes.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            JournalFreeWritePromptCard(onWrite: onFreeWrite)

            ABYJournalDailyQuoteCard(
                quote: currentQuote.text,
                attribution: currentQuote.attribution,
                onShuffle: shuffleQuote
            )

            Text("Templates")
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(JournalPromptLibrary.templates) { template in
                    Button {
                        onSelect(template)
                    } label: {
                        ABYJournalTemplateCard(
                            title: template.title,
                            preview: template.preview
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            Text("More coming soon…")
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }

    private func shuffleQuote() {
        withAnimation(AppTheme.springSnappy) {
            quoteIndex = (quoteIndex + 1) % JournalPromptLibrary.dailyQuotes.count
        }
        DevotionHaptics.light()
    }
}
