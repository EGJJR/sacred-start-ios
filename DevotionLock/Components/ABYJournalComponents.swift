//
//  ABYJournalComponents.swift
//  DevotionLock
//
//  Mobbin ABY Journal custom components:
//  - Timeline: https://mobbin.com/screens/a79d0a61-c35f-4ab7-bf44-9100c457fb53
//  - Streaks: https://mobbin.com/screens/49fcbbc9-a0d3-4a10-88a9-a791c3c8f1a6
//  - Paywall: https://mobbin.com/screens/1d8676fc-4191-44db-b1df-eeabb8002415
//

import SwiftUI

// MARK: - Mesh & glass

/// Warm sanctuary mesh for streak/stats (ABY lavender mesh, warm-shifted).
struct ABYStatsMeshBackground: View {
    @Environment(\.sanctuaryPalette) private var palette
    @State private var drift = false

    var body: some View {
        ZStack {
            if palette.isNight {
                ABYEveningReflectionBackground()
                meshBlob(ABY.Color.nightMeshPlum, size: 280, blur: 80, x: -90, y: -120)
                meshBlob(ABY.Color.nightMeshIndigo, size: 240, blur: 72, x: 110, y: 280)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.94, blue: 0.92),
                        Color(red: 0.96, green: 0.93, blue: 0.98),
                        Color(red: 0.94, green: 0.96, blue: 0.95),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                meshBlob(Color(red: 0.82, green: 0.72, blue: 0.90), size: 320, blur: 78, x: -110, y: -190)
                meshBlob(Color(red: 0.98, green: 0.78, blue: 0.62), size: 280, blur: 72, x: 130, y: 40)
                meshBlob(Color(red: 0.62, green: 0.84, blue: 0.78), size: 260, blur: 68, x: -70, y: 320)
                meshBlob(Color(red: 0.90, green: 0.70, blue: 0.82), size: 240, blur: 64, x: 120, y: 420)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func meshBlob(_ color: Color, size: CGFloat, blur: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(drift ? (palette.isNight ? 0.35 : 0.42) : (palette.isNight ? 0.22 : 0.28)))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(x: x, y: y)
            .allowsHitTesting(false)
    }
}

struct ABYGlassPanel<Content: View>: View {
    @Environment(\.sanctuaryPalette) private var palette
    var cornerRadius: CGFloat = 22
    var padding: CGFloat = 18
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        palette.isNight
                            ? palette.cardFill
                            : Color.white.opacity(0.42)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        palette.isNight
                            ? palette.divider.opacity(0.55)
                            : Color.white.opacity(0.55),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 12, y: 4)
    }
}

// MARK: - Timeline chrome

struct ABYTimelineScreenHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let sectionTitle: String
    var subtitle: String? = nil
    var streak: Int = 0
    var onStreakTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Timeline")
                    .font(ABY.Font.title)
                    .foregroundStyle(palette.textSecondary.opacity(0.72))
                Text(sectionTitle)
                    .font(ABY.Font.title2)
                    .foregroundStyle(palette.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 12)

            if streak > 0, let onStreakTap {
                Button(action: onStreakTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(ABY.Font.bodySemibold)
                            .foregroundStyle(StreakPalette.orange)
                        Text("\(streak)")
                            .font(ABY.Font.calloutMedium)
                            .foregroundStyle(StreakPalette.orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.85))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ABYMoodSmileyBadge: View {
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            Circle()
                .fill(StreakPalette.moodGreen)
                .frame(width: size, height: size)
            StreakMoodFace()
                .scaleEffect(size / 28)
        }
    }
}

/// ABY Journal mood chip — peach pill with emoji + label.
/// Mobbin: https://mobbin.com/screens/b6769a87-5bd1-4fd3-9309-8f7cdae58991
struct ABYMoodChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let emoji: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Text(emoji.isEmpty ? "😊" : emoji)
                .font(ABY.Font.callout)
            Text(label)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(palette.isNight ? ABY.Color.starlight : ABY.Color.moodPeachText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(palette.isNight ? Color.white.opacity(0.12) : ABY.Color.moodPeach)
        .clipShape(Capsule())
    }
}

// MARK: - Timeline cards

struct ABYTimelineRail: View {
    @Environment(\.sanctuaryPalette) private var palette
    let time: String
    var showsConnector: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            ABYTimelineTimePill(time: time)

            if showsConnector {
                Rectangle()
                    .fill(palette.divider.opacity(0.55))
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, -6)
            }
        }
        .frame(width: 76, alignment: .top)
    }
}

struct ABYTimelineTimePill: View {
    @Environment(\.sanctuaryPalette) private var palette
    let time: String

    private var pillFill: Color {
        palette.isNight ? ABY.Color.starlight : Color.white.opacity(0.95)
    }

    private var labelColor: Color {
        palette.isNight ? ABY.Color.eveningReflectionTop : palette.textSecondary
    }

    var body: some View {
        Text(time)
            .font(ABY.Font.captionMedium)
            .foregroundStyle(labelColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(pillFill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(palette.divider.opacity(0.7), lineWidth: 1)
            }
            .overlay(alignment: .trailing) {
                TrianglePointer()
                    .fill(pillFill)
                    .frame(width: 6, height: 8)
                    .offset(x: 5)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 14)
    }
}

private struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct ABYTimelineEntryCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    var dateLabel: String = ""
    var moodEmoji: String = ""
    var moodLabel: String = ""
    let bodyText: String
    var entryEmoji: String = ""
    var secondaryEmojis: String = ""
    var voiceDuration: String? = nil
    var showsMetadata: Bool = true
    var onTap: (() -> Void)? = nil

    private var isEarlierCard: Bool {
        !dateLabel.isEmpty && dateLabel != "Today"
    }

    private var leadingEmoji: String {
        if !entryEmoji.isEmpty { return entryEmoji }
        if !secondaryEmojis.isEmpty { return secondaryEmojis }
        if !moodEmoji.isEmpty { return moodEmoji }
        return "📝"
    }

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { cardContent }
                    .buttonStyle(ScaleButtonStyle())
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEarlierCard {
                Text(dateLabel)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
            }

            HStack(alignment: .center, spacing: 8) {
                Text(leadingEmoji)
                    .font(ABY.Font.title2)

                Spacer(minLength: 8)

                if !moodLabel.isEmpty {
                    ABYMoodChip(emoji: moodEmoji, label: moodLabel)
                }
            }

            Text(bodyText)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
                .lineLimit(isEarlierCard ? 4 : 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [cardFill.opacity(0), cardFill],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 22)
                    .allowsHitTesting(false)
                    .opacity(bodyText.count > 120 ? 1 : 0)
                }

            if let voiceDuration {
                ABYVoiceEntryMiniPlayer(duration: voiceDuration)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.isNight ? palette.surface : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(palette.isNight ? 0.25 : 0.07), radius: 14, y: 5)
    }

    private var cardFill: Color {
        palette.isNight ? palette.surface : Color.white
    }
}

struct ABYCaptureTodayCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    var onAdd: () -> Void

    private let cornerRadius: CGFloat = 22

    var body: some View {
        Button(action: onAdd) {
            Text("Add for today")
                .font(ABY.Font.body)
                .foregroundStyle(palette.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.07), radius: 14, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ABYJournalBottomChrome<Content: View>: View {
    @Environment(\.sanctuaryPalette) private var palette
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [palette.background.opacity(0), palette.background.opacity(0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 32)
            .allowsHitTesting(false)

            content()
                .padding(.horizontal, ABY.Spacing.screen)

            Color.clear
                .frame(height: 88)
        }
        .background(alignment: .bottom) {
            LinearGradient(
                colors: [palette.background.opacity(0), palette.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct ABYVoiceEntryMiniPlayer: View {
    let duration: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(ABY.Color.pillPurple)
                    .frame(width: 32, height: 32)
                Image(systemName: "play.fill")
                    .font(ABY.Font.emojiSmall)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(duration)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.textPrimary)
                ABYVoiceWaveformBars(active: false, barCount: 18)
                    .frame(height: 20)
            }
        }
        .padding(10)
        .background(ABY.Color.pillPurple.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ABYInsightsPeek: View {
    @Environment(\.sanctuaryPalette) private var palette
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            Text("Insights")
                .font(ABY.Font.calloutMedium)
                .foregroundStyle(palette.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Streak hero

struct ABYStreakHero: View {
    @Environment(\.sanctuaryPalette) private var palette
    let streak: Int
    let statusName: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(streak)")
                    .font(ABY.Font.displayLarge)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [StreakPalette.orange, StreakPalette.orangeLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("day streak!")
                    .font(ABY.Font.editorialHeadline)
                    .foregroundStyle(StreakPalette.orange)
                Text(statusName)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.isNight ? palette.textSecondary : ABY.Color.pillTeal)
                    .padding(.top, 6)
            }

            Spacer(minLength: 8)

            Image(systemName: "flame.fill")
                .font(ABY.Font.displayHero)
                .foregroundStyle(
                    LinearGradient(
                        colors: [StreakPalette.orangeLight, StreakPalette.orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: StreakPalette.orange.opacity(0.25), radius: 8, y: 4)
        }
    }
}

struct ABYGlassStatChip: View {
    @Environment(\.sanctuaryPalette) private var palette
    var icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(ABY.Font.headline)
                .foregroundStyle(StreakPalette.orange)
            Text("\(value) \(label)")
                .font(ABY.Font.captionMedium)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(palette.isNight ? palette.cardFill : Color.white.opacity(0.45))
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.divider.opacity(palette.isNight ? 0.5 : 0.25), lineWidth: 1)
        }
    }
}

struct ABYStreakScreenHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onDismiss) {
                Image(systemName: "chevron.down")
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(palette.textPrimary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")

            Text("Streaks & Stats")
                .font(ABY.Font.editorialHeadline)
                .foregroundStyle(palette.textPrimary)

            Spacer(minLength: 0)
        }
        .frame(minHeight: 44, alignment: .center)
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }
}

// MARK: - Scroll edge fade (Mobbin ABY timeline / Dot chat)

struct ABYScrollEdgeFade: View {
    enum Placement { case top, bottom }
    @Environment(\.sanctuaryPalette) private var palette
    var placement: Placement
    var height: CGFloat = 56

    var body: some View {
        LinearGradient(
            colors: placement == .top
                ? [palette.background, palette.background.opacity(0)]
                : [palette.background.opacity(0), palette.background],
            startPoint: placement == .top ? .top : .bottom,
            endPoint: placement == .top ? .bottom : .top
        )
        .frame(height: height)
        .allowsHitTesting(false)
    }
}

extension View {
    func abyScrollEdgeFades(top: Bool = true, bottom: Bool = true, height: CGFloat = 56) -> some View {
        overlay(alignment: .top) {
            if top { ABYScrollEdgeFade(placement: .top, height: height) }
        }
        .overlay(alignment: .bottom) {
            if bottom { ABYScrollEdgeFade(placement: .bottom, height: height) }
        }
    }
}

// MARK: - Assisted journal (Mobbin ABY guided entry 97c44fa4 / e3f97f9b)

/// Warm cream canvas — ABY guided write (not sanctuary lavender).
struct ABYGuidedJournalBackground: View {
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        Group {
            if palette.isNight {
                ABYNightSanctuaryBackground()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.995, green: 0.992, blue: 0.984),
                        Color(red: 0.988, green: 0.982, blue: 0.968),
                        Color(red: 0.978, green: 0.972, blue: 0.958),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct ABYAssistedJournalHeader: View {
    @Environment(\.sanctuaryPalette) private var palette
    let prompt: String
    var onShuffle: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(ABY.Font.editorialHeadline)
                .foregroundStyle(palette.isNight ? palette.textPrimary : ABY.Color.journalPromptAccent)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: 10) {
                Text("No perfect words needed. Just what's true right now…")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                if let onShuffle {
                    Button(action: onShuffle) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(ABY.Font.footnoteSemibold)
                            .foregroundStyle(palette.textTertiary)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(palette.isNight ? 0.08 : 0.72))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Suggest another question")
                }
            }
        }
    }
}

struct ABYAssistedJournalFinishButton: View {
    @Environment(\.sanctuaryPalette) private var palette

    let title: String
    let isEnabled: Bool
    let action: () -> Void

    init(_ title: String = "Finish", isEnabled: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    private var fill: Color {
        (palette.isNight ? palette.buttonFill : ABY.Color.journalFinish)
            .opacity(isEnabled ? 1 : 0.35)
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ABY.Font.calloutSemibold)
                .foregroundStyle(palette.isNight ? palette.buttonForeground : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(fill)
                .clipShape(Capsule())
                .shadow(
                    color: fill.opacity(isEnabled ? (palette.isNight ? 0.22 : 0.28) : 0),
                    radius: 8,
                    y: 3
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(AppTheme.springSnappy, value: isEnabled)
    }
}

/// Bottom-anchored write surface — prompt area above, card hugs keyboard.
struct ABYGuidedJournalWriteSurface: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var text: String
    let phrases: [String]
    var showStarters: Bool
    var onSelectPhrase: (String) -> Void
    var focused: FocusState<Bool>.Binding
    var onDictate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showStarters {
                ABYStarterPhraseRow(
                    phrases: phrases,
                    onSelect: onSelectPhrase
                )
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Add your thoughts…")
                        .font(ABY.Font.body)
                        .foregroundStyle(palette.textTertiary)
                        .padding(.top, 10)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textPrimary)
                    .tint(palette.textPrimary)
                    .scrollContentBackground(.hidden)
                    .lineSpacing(8)
                    .focused(focused)
                    .frame(minHeight: 132, maxHeight: 280, alignment: .topLeading)
                    .padding(.leading, -4)
            }

            HStack(spacing: 12) {
                ABYJournalMicButton(action: onDictate)
                Spacer(minLength: 0)
                if !text.isEmpty {
                    Text("\(text.split(whereSeparator: \.isWhitespace).filter { !$0.isEmpty }.count) words")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(Color.white.opacity(palette.isNight ? 0.12 : 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.divider.opacity(0.5), lineWidth: 1)
        }
        .shadow(color: .black.opacity(palette.isNight ? 0.2 : 0.07), radius: 20, y: 8)
    }
}

/// White floating composer — legacy; prefer ABYGuidedJournalWriteSurface.
struct ABYAssistedJournalComposer: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var text: String
    var placeholder: String = "Start writing…"
    var focused: FocusState<Bool>.Binding
    var onDictate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(ABY.Font.body)
                        .foregroundStyle(palette.textSecondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textPrimary)
                    .tint(palette.textPrimary)
                    .scrollContentBackground(.hidden)
                    .lineSpacing(7)
                    .focused(focused)
                    .frame(minHeight: 108, maxHeight: 200, alignment: .topLeading)
                    .padding(.leading, -4)
            }

            HStack {
                ABYJournalMicButton(action: onDictate)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }
}

/// Borderless editor — used where no card chrome is needed.
struct ABYMinimalJournalEditor: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var text: String
    var placeholder: String = "Start writing…"
    var focused: FocusState<Bool>.Binding

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(ABY.Font.body)
                    .foregroundStyle(palette.textSecondary)
                    .padding(.top, 10)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .tint(palette.textPrimary)
                .scrollContentBackground(.hidden)
                .lineSpacing(7)
                .focused(focused)
                .padding(.leading, -4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct ABYJournalMicButton: View {
    @Environment(\.sanctuaryPalette) private var palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "mic")
                .font(ABY.Font.bodyMedium)
                .foregroundStyle(palette.textSecondary)
                .frame(width: 38, height: 38)
                .overlay {
                    Circle()
                        .strokeBorder(palette.textSecondary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Speak instead")
    }
}

struct ABYStarterPhraseRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let phrases: [String]
    var onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(phrases, id: \.self) { phrase in
                    Button { onSelect(phrase) } label: {
                        Text(phrase)
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(ABY.Color.pillPurple.opacity(0.92))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(ABY.Color.pillPurple.opacity(palette.isNight ? 0.16 : 0.08))
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(ABY.Color.pillPurple.opacity(0.28), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Home journey section (moved from Settings)

struct ABYDevotionJourneySection: View {
    @Environment(\.sanctuaryPalette) private var palette
    var streakManager: StreakManager
    var journeyStore: JourneyTimelineStore
    var journalEntryCount: Int
    var onSeeAll: () -> Void
    var onStreakTap: (() -> Void)? = nil

    private var displayEntries: [JourneyTimelineEntry] {
        if !journeyStore.todayEntries.isEmpty {
            return Array(journeyStore.todayEntries.prefix(4))
        }
        return Array(journeyStore.recentEntries.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Journey")
                        .font(ABY.Font.editorialAccent)
                        .foregroundStyle(palette.textSecondary)
                    Text(journeyStore.todayEntries.isEmpty ? "Your path" : "Today")
                        .font(ABY.Font.title2)
                        .foregroundStyle(palette.textPrimary)
                }
                Spacer()
                Button("See all", action: onSeeAll)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(ABY.Color.pillPurple)
            }

            HStack(spacing: 10) {
                ABYGlassStatChip(
                    icon: "sun.max.fill",
                    value: "\(streakManager.daysJournaled)",
                    label: "Days journaled"
                )
                ABYGlassStatChip(
                    icon: "pencil.line",
                    value: "\(max(journalEntryCount, journeyStore.entries.count))",
                    label: "Entries"
                )
            }

            if let onStreakTap, streakManager.currentStreak > 0 {
                Button(action: onStreakTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(StreakPalette.orange)
                        Text("\(streakManager.currentStreak) day streak")
                            .font(ABY.Font.calloutMedium)
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(palette.textTertiary)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
            }

            if displayEntries.isEmpty {
                Text("Moods, verses, prayers, and reflections gather here as you move through your day.")
                    .font(ABY.Font.callout)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(4)
                    .padding(ABY.Spacing.card)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
            } else {
                VStack(spacing: 14) {
                    ForEach(displayEntries) { entry in
                        ABYJourneyTimelineRow(entry: entry)
                    }
                }
            }
        }
    }
}

// MARK: - Guided journal (Mobbin ABY mad-libs + guided entry)

struct ABYGuidedJournalStepLabel: View {
    @Environment(\.sanctuaryPalette) private var palette
    let stepTitle: String
    let stepIndex: Int
    let totalSteps: Int

    var body: some View {
        Text("Morning devotion · \(stepTitle) · \(stepIndex) of \(totalSteps)")
            .font(ABY.Font.caption)
            .foregroundStyle(palette.textTertiary)
            .frame(maxWidth: .infinity)
    }
}

struct ABYGuidedMoodGrid: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var selectedMood: String
    var onSelect: (String) -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    static func accent(for mood: String) -> Color {
        switch mood.lowercased() {
        case "peaceful": ABY.Color.pillTeal
        case "overwhelmed": ABY.Color.pillOrange
        case "grateful": ABY.Color.pillPink
        case "restless": ABY.Color.pillPurple
        case "hopeful": ABY.Color.pillOrange
        default: ABY.Color.pillPink
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(MoodCatalog.options, id: \.label) { mood in
                let isSelected = selectedMood == mood.label
                Button {
                    onSelect(mood.label)
                } label: {
                    HStack(spacing: 10) {
                        Text(mood.emoji)
                            .font(ABY.Font.title2)
                        Text(mood.label)
                            .font(ABY.Font.calloutMedium)
                            .foregroundStyle(moodLabelColor(isSelected: isSelected))
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(moodBackground(isSelected: isSelected, mood: mood.label))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isSelected
                                    ? Self.accent(for: mood.label).opacity(palette.isNight ? 0.9 : 0.85)
                                    : palette.divider,
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
                    .shadow(
                        color: .black.opacity(isSelected ? palette.cardShadowOpacity : palette.cardShadowOpacity * 0.35),
                        radius: isSelected ? 10 : 4,
                        y: 2
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private func moodLabelColor(isSelected: Bool) -> Color {
        if palette.isNight {
            return isSelected ? palette.textPrimary : palette.textSecondary
        }
        return isSelected ? ABY.Color.textPrimary : palette.textSecondary
    }

    private func moodBackground(isSelected: Bool, mood: String) -> Color {
        if palette.isNight {
            if isSelected {
                return Self.accent(for: mood).opacity(0.24)
            }
            return palette.cardFill
        }
        return isSelected ? Color.white : Color.white.opacity(0.55)
    }
}

struct ABYMadLibEditSheet: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.dismiss) private var dismiss
    let field: MadLibField
    @Binding var text: String
    var onDone: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(palette.divider)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 18)

            HStack {
                Text(field.sheetTitle)
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(ABY.Font.footnoteSemibold)
                        .foregroundStyle(palette.textTertiary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 20)

            TextField(field.sheetPlaceholder, text: $text)
                .font(ABY.Font.bodyMedium)
                .foregroundStyle(field.color)
                .tint(field.color)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.sentences)
                .focused($focused)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(field.color.opacity(0.08))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(field.color.opacity(0.65), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(field.suggestions, id: \.self) { suggestion in
                        Button {
                            text = field == .emotion ? suggestion.lowercased() : suggestion
                        } label: {
                            Text(suggestion)
                                .font(ABY.Font.captionMedium)
                                .foregroundStyle(field.color)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(field.color.opacity(0.10))
                                .clipShape(Capsule())
                                .overlay(Capsule().strokeBorder(field.color.opacity(0.35), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
            }
            .padding(.bottom, 24)

            Button(action: onDone) {
                Text("Add yours!")
                    .font(ABY.Font.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(palette.buttonFill)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 12)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.white)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focused = true
            }
        }
    }
}

struct ABYGuidedVoiceHandoffCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let savedPhrase: String
    var mood: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Ready to reflect")
                    .font(ABY.Font.section)
                    .foregroundStyle(palette.textSecondary)
                    .tracking(0.4)
                Spacer()
                MoodPill(label: mood)
            }

            if !savedPhrase.isEmpty {
                Text("“\(savedPhrase)”")
                    .font(ABY.Font.editorialHeadline)
                    .foregroundStyle(palette.textPrimary)
                    .lineSpacing(5)
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(palette.textPrimary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .frame(width: 44, height: 44)
                    Image(systemName: "mic.fill")
                        .font(ABY.Font.bodyMedium)
                        .foregroundStyle(palette.textPrimary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Speak your reflection")
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textPrimary)
                    Text("We'll transcribe your words, then you can continue with Chaplain.")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineSpacing(3)
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

struct ABYJourneyTimelineRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let entry: JourneyTimelineEntry

    private var timeLabel: String {
        entry.createdAt.formatted(date: .omitted, time: .shortened)
    }

    private var entryKindEmoji: String {
        switch entry.kind {
        case .evening: "🌙"
        case .devotion: "☀️"
        case .gratitude: "🙏"
        case .verse: "📖"
        case .voiceNote: "🎙️"
        case .answeredPrayer: "✅"
        default: "📝"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ABYTimelineTimePill(time: timeLabel)

            ABYTimelineEntryCard(
                moodEmoji: entry.moodEmoji ?? entryKindEmoji,
                bodyText: entry.body ?? entry.title,
                secondaryEmojis: entry.kind == .devotion ? "🙏" : "",
                showsMetadata: false
            )
            .padding(.leading, 4)
        }
    }
}

// MARK: - Prompt templates (Mobbin ABY Journal templates 6bfa1cd3, quote card 4f9d087f)

struct ABYJournalRuledLines: View {
    @Environment(\.sanctuaryPalette) private var palette
    var lineCount: Int = 5
    var spacing: CGFloat = 18

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<lineCount, id: \.self) { _ in
                Rectangle()
                    .fill(
                        palette.isNight
                            ? Color.white.opacity(0.14)
                            : Color(red: 0.78, green: 0.86, blue: 0.96).opacity(0.85)
                    )
                    .frame(height: 1)
            }
        }
    }
}

/// ABY Templates grid card — bold title, ruled paper, handwritten preview.
/// Mobbin: https://mobbin.com/screens/6bfa1cd3-b997-41bd-afac-4ef5cf98a016
struct ABYJournalTemplateCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let title: String
    let preview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(ABY.Font.calloutSemibold)
                .foregroundStyle(palette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .padding(.bottom, 10)

            Text(preview)
                .font(ABY.Font.editorialAccent)
                .foregroundStyle(palette.textSecondary.opacity(0.88))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.bottom, 12)

            Spacer(minLength: 0)

            ABYJournalRuledLines(lineCount: 4, spacing: 16)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
        .background(palette.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.divider.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 10, y: 3)
    }
}

/// ABY timeline quote card — serif passage with shuffle.
/// Mobbin: https://mobbin.com/screens/4f9d087f-492e-4bc9-92ec-31064a5c5800
struct ABYJournalDailyQuoteCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let quote: String
    let attribution: String
    var onShuffle: () -> Void

    private var dateLabel: String {
        Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(dateLabel)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
                Spacer(minLength: 0)
                Button(action: onShuffle) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(ABY.Font.captionSemibold)
                        .foregroundStyle(palette.textTertiary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Another quote")
            }

            Text("\"\(quote)\"")
                .font(ABY.Font.editorialBody)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text(attribution)
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textTertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(ABY.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .stroke(palette.divider.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 12, y: 4)
    }
}
