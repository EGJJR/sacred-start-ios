//
//  HomeComponents.swift
//  test1
//

import SwiftUI

// MARK: - Chrome

struct ABYScreenHeader<Trailing: View>: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    var showDot: Bool = false
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        showDot: Bool = false,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.showDot = showDot
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(ABY.Font.editorialLargeTitle)
                        .foregroundStyle(palette.textPrimary)
                    if showDot {
                        Circle()
                            .fill(ABY.Color.accentDot)
                            .frame(width: 7, height: 7)
                            .offset(y: 2)
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                }
            }

            Spacer(minLength: 12)

            trailing()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ABYProgressBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? palette.trackFill : palette.track)
                    .frame(height: 3)
                    .animation(AppTheme.springSnappy, value: current)
            }
        }
    }
}

struct ABYPrimaryButton: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(ABY.Font.button)
                if let icon {
                    Image(systemName: icon)
                        .font(ABY.Font.iconSmall)
                }
            }
            .foregroundStyle(palette.buttonForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(palette.buttonFill)
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ABYIconButton: View {
    @Environment(\.sanctuaryPalette) private var palette
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(ABY.Font.iconMedium)
                .foregroundStyle(palette.textPrimary)
                .frame(width: 36, height: 36)
                .background(palette.surface)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct ABYHeadline: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    let subtitle: String
    var alignment: TextAlignment = .leading

    var body: some View {
        VStack(alignment: alignment == .leading ? .leading : .center, spacing: 8) {
            Text(title)
                .font(ABY.Font.onboardingTitle)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(alignment)
            Text(subtitle)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(alignment)
                .lineSpacing(4)
        }
    }
}

struct ABYInsightCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let moodEmoji: String
    let moodLabel: String
    let time: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                MoodPill(label: moodLabel)
                Spacer()
                Text(time)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
            }
            Text(bodyText)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .abyCard()
    }
}

struct ABYFeatureRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(ABY.Font.iconLarge)
                .foregroundStyle(palette.textPrimary)
                .frame(width: 36, height: 36)
                .background(palette.background)
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.chip))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Text(detail)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

struct ABYSelectionChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String
    var icon: String? = nil
    var trailing: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(ABY.Font.iconMedium)
                        .foregroundStyle(isSelected ? palette.textPrimary : palette.textSecondary)
                        .frame(width: 24)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    if let trailing {
                        Text(trailing)
                            .font(ABY.Font.footnote)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(ABY.Font.checkmark)
                    .foregroundStyle(isSelected ? palette.textPrimary : palette.textTertiary)
            }
            .padding(.horizontal, ABY.Spacing.card)
            .padding(.vertical, 14)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.card)
                    .stroke(isSelected ? palette.textPrimary : palette.divider, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ABYSearchBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var text: String
    var placeholder: String = "Search"
    var autofocus: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(ABY.Font.iconMedium)
                .foregroundStyle(palette.textTertiary)
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(palette.textTertiary))
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .focused($focused)
            if !text.isEmpty {
                Button { withAnimation(AppTheme.springSnappy) { text = "" } } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(palette.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: ABY.Radius.card).stroke(palette.divider, lineWidth: 1))
        .onAppear { if autofocus { focused = true } }
    }
}

struct ABYTagChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String
    let isSelected: Bool

    var body: some View {
        Text(label)
            .font(ABY.Font.footnote)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected ? palette.textPrimary : palette.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? palette.surface : palette.background)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? palette.textPrimary : palette.divider, lineWidth: 1))
    }
}

struct ABYThemeRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let theme: SpiritualTheme
    @State private var animatedStrength: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: theme.icon)
                    .font(ABY.Font.iconSmall)
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(palette.background)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text(theme.label)
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Spacer()
                Text(theme.depth.rawValue)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(palette.background)
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.track).frame(height: 5)
                    Capsule()
                        .fill(palette.textPrimary)
                        .frame(width: geo.size.width * animatedStrength, height: 5)
                }
            }
            .frame(height: 5)
        }
        .abyCard(cornerRadius: ABY.Radius.card, padding: 14)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedStrength = theme.strength
            }
        }
    }
}

// MARK: - Home

struct HomeScriptureShortcutsRow: View {
    @Environment(\.sanctuaryPalette) private var palette

    var onBible: () -> Void
    var onPromises: () -> Void

    private var bibleSubtitle: String {
        FeatureFlags.bibleReaderEnabled ? "Browse by book" : "Curated passages"
    }

    private var promisesPreview: String {
        SpiritualPassageCatalog.passages(for: .promises).first?.reference ?? "Jeremiah 29:11"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scripture")
                    .font(ABY.Font.section)
                    .foregroundStyle(palette.textSecondary)
                    .tracking(0.5)
                Text("Bible and promises for your day")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
            }

            HStack(spacing: 12) {
                HomeScriptureShortcutTile(
                    icon: "book.closed.fill",
                    tint: ABY.Color.pillTeal,
                    title: "Bible",
                    subtitle: bibleSubtitle,
                    action: onBible
                )
                HomeScriptureShortcutTile(
                    icon: PassageTopic.promises.icon,
                    tint: PassageTopic.promises.tint,
                    title: "Promises",
                    subtitle: promisesPreview,
                    action: onPromises
                )
            }
        }
    }
}

private struct HomeScriptureShortcutTile: View {
    @Environment(\.sanctuaryPalette) private var palette
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(ABY.Font.headline)
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text(subtitle)
                        .font(ABY.Font.footnote)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ABY.Spacing.card)
            .background(palette.surface.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

struct HomeTodayCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let focus: DailyFocus
    var mood: String
    var onBegin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 6) {
                Image(systemName: "sun.horizon.fill")
                    .font(ABY.Font.iconSmall)
                    .foregroundStyle(palette.textSecondary)
                Text("Morning devotion")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
                Spacer()
                Text("~7 min")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(palette.background)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("\"\(focus.verse)\"")
                    .font(ABY.Font.body)
                    .italic()
                    .foregroundStyle(palette.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                Text(focus.reference)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
            }

            Rectangle()
                .fill(palette.divider)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 10) {
                Text("Let's begin with this moment")
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                MadLibTeaserLine(
                    prefix: "Right now, I'm feeling ",
                    highlight: mood.lowercased(),
                    color: ABY.Color.pillPink
                )
                MadLibTeaserLine(
                    prefix: "because ",
                    highlight: "something on my heart",
                    color: ABY.Color.pillOrange
                )
            }

            Button(action: onBegin) {
                HStack(spacing: 8) {
                    Text("Begin devotion")
                        .font(ABY.Font.button)
                    Image(systemName: "arrow.right")
                        .font(ABY.Font.iconSmall)
                }
                .foregroundStyle(palette.buttonForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(palette.buttonFill)
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .abyCard(cornerRadius: ABY.Radius.cardLarge)
    }
}

struct MadLibTeaserLine: View {
    @Environment(\.sanctuaryPalette) private var palette
    let prefix: String
    let highlight: String
    let color: Color

    var body: some View {
        HStack(spacing: 0) {
            Text(prefix)
                .foregroundStyle(palette.textPrimary)
            Text(highlight)
                .foregroundStyle(color)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.chip))
                .overlay {
                    RoundedRectangle(cornerRadius: ABY.Radius.chip)
                        .strokeBorder(color.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
        }
        .font(ABY.Font.body)
        .lineSpacing(4)
    }
}

struct MoodPill: View {
    @Environment(\.sanctuaryPalette) private var palette
    let label: String
    let icon: String

    init(label: String, icon: String? = nil) {
        self.label = label
        self.icon = icon ?? MoodCatalog.icon(for: label)
    }

    /// Legacy — maps mood label to SF Symbol instead of emoji.
    init(emoji _: String, label: String) {
        self.label = label
        self.icon = MoodCatalog.icon(for: label)
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(ABY.Font.paywallPromoBadge)
                .foregroundStyle(ABY.Color.moodPeachText)
            Text(label)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(ABY.Color.moodPeachText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(ABY.Color.moodPeach)
        .clipShape(Capsule())
    }
}

struct TimelineEntryRow: View {
    let time: String
    let conversation: Conversation
    var isLastInSection: Bool = true
    var onTap: () -> Void

    var body: some View {
        JournalTimelineEntry(
            conversation: conversation,
            isEarlier: !conversation.isToday,
            isLastInSection: isLastInSection,
            onTap: onTap
        )
    }
}

struct HomeJournalPreviewLink: View {
    @Environment(\.sanctuaryPalette) private var palette
    let entryCount: Int
    let latestPreview: String?
    let onSeeAll: () -> Void

    var body: some View {
        Button(action: onSeeAll) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(ABY.Color.pillPink.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: "book.pages.fill")
                        .font(ABY.Font.headline)
                        .foregroundStyle(ABY.Color.pillPink)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent reflections")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    if let latestPreview {
                        Text(latestPreview)
                            .font(ABY.Font.callout)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("\(entryCount) entries in your journal")
                            .font(ABY.Font.callout)
                            .foregroundStyle(palette.textSecondary)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Text("See all")
                        .font(ABY.Font.captionMedium)
                    Image(systemName: "chevron.right")
                        .font(ABY.Font.emojiSmall)
                }
                .foregroundStyle(ABY.Color.pillPink)
            }
            .padding(ABY.Spacing.card)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
            .overlay {
                RoundedRectangle(cornerRadius: ABY.Radius.cardLarge)
                    .stroke(palette.divider, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("See all journal reflections")
    }
}

struct HomeDaySummaryCard: View {
    let summary: DaySummary
    var onTap: (() -> Void)? = nil

    private var displayTime: String {
        summary.timeLabel.contains("-") && summary.timeLabel.count == 10 ? "" : summary.timeLabel
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if !displayTime.isEmpty {
                ABYTimelineRail(time: displayTime, showsConnector: false)
            }

            Button {
                onTap?()
            } label: {
                ABYTimelineEntryCard(
                    moodEmoji: summary.moodEmoji,
                    moodLabel: summary.mood,
                    bodyText: summary.insight,
                    entryEmoji: "🌅"
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(onTap == nil)
        }
    }
}

struct ShieldStatusCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    var isLocked: Bool
    var isCompletedToday: Bool
    var isShieldActive: Bool = false
    var onBegin: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isCompletedToday ? ABY.Color.orbSage.opacity(0.18) : ABY.Color.pillOrange.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: isCompletedToday ? "lock.open.fill" : "lock.shield.fill")
                    .font(ABY.Font.headline)
                    .foregroundStyle(isCompletedToday ? ABY.Color.pillTeal : ABY.Color.pillOrange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(isCompletedToday ? "Shield unlocked" : (isShieldActive ? "Apps shielded" : "Shield ready"))
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Text(isCompletedToday
                     ? "Your morning devotion is complete for today."
                     : (isShieldActive
                        ? "Complete devotion to unlock distracting apps."
                        : "Finish setup in Profile → App shield."))
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)

            if !isCompletedToday {
                Image(systemName: "chevron.right")
                    .font(ABY.Font.iconSmall)
                    .foregroundStyle(palette.textTertiary)
            }
        }
        .padding(ABY.Spacing.card)
        .background(palette.surface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .overlay(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge).stroke(palette.divider, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .onTapGesture {
            if !isCompletedToday { onBegin() }
        }
    }
}

typealias DevotionPrimaryButton = ABYPrimaryButton
