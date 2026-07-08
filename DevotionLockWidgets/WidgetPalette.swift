//
//  WidgetPalette.swift
//  DevotionLockWidgets
//

import SwiftUI
import WidgetKit

enum WidgetPalette {
    // MARK: - ABY sanctuary (aligned with main app)

    static let pillTeal = Color(red: 0.30, green: 0.62, blue: 0.58)
    static let pillPurple = Color(red: 0.55, green: 0.48, blue: 0.72)
    static let pillOrange = Color(red: 1.0, green: 0.55, blue: 0.22)
    static let orbSage = Color(red: 0.48, green: 0.68, blue: 0.56)
    static let orbTeal = Color(red: 0.36, green: 0.71, blue: 0.64)

    static let meshLilac = Color(red: 0.72, green: 0.58, blue: 0.88)
    static let meshLavender = Color(red: 0.88, green: 0.70, blue: 0.86)
    static let meshPeriwinkle = Color(red: 0.58, green: 0.64, blue: 0.90)
    static let meshSky = Color(red: 0.52, green: 0.74, blue: 0.94)
    static let meshGold = Color(red: 0.99, green: 0.78, blue: 0.35)

    static let sanctuaryTop = Color(red: 0.90, green: 0.84, blue: 0.96)
    static let sanctuaryMid = Color(red: 0.94, green: 0.86, blue: 0.94)
    static let sanctuaryBottom = Color(red: 0.86, green: 0.92, blue: 0.98)
    static let warmCream = Color(red: 0.984, green: 0.948, blue: 0.908)
    static let warmPaper = Color.white

    static let moodPeach = Color(red: 1.0, green: 0.93, blue: 0.88)
    static let moodPeachText = Color(red: 0.72, green: 0.45, blue: 0.28)
    static let moodGreen = Color(red: 0.62, green: 0.90, blue: 0.72)

    static let textPrimary = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let textSecondary = Color(red: 0.42, green: 0.42, blue: 0.46)
    static let textTertiary = Color(red: 0.58, green: 0.58, blue: 0.62)

    static let liveActivityTint = Color(red: 0.90, green: 0.88, blue: 0.97)

    static let paper = [
        Color(red: 0.98, green: 0.95, blue: 0.82),
        Color(red: 0.94, green: 0.97, blue: 1.0),
        Color(red: 0.97, green: 0.93, blue: 0.96),
        Color(red: 0.92, green: 0.98, blue: 0.94),
        Color(red: 1.0, green: 0.94, blue: 0.90),
    ]

    static let devotionSteps: [(icon: String, label: String)] = [
        ("heart.fill", "Arrive"),
        ("text.word.spacing", "Story"),
        ("book.fill", "Word"),
        ("mic.fill", "Voice"),
        ("checkmark", "Done"),
    ]

    static func paperColor(index: Int) -> Color {
        paper[index % paper.count]
    }

    static func kindAccent(_ kind: String) -> Color {
        switch kind {
        case "request": pillPurple
        case "reminder": pillOrange
        case "answered": orbSage
        default: pillTeal
        }
    }
}

enum WidgetTypography {
    static func streakNumber(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func quote(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func editorialTitle(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func micro(_ size: CGFloat = 9) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

// MARK: - Backgrounds

struct WidgetSanctuaryBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    WidgetPalette.sanctuaryTop,
                    WidgetPalette.sanctuaryMid,
                    WidgetPalette.sanctuaryBottom,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            WidgetSanctuaryOrbs(intensity: 0.65)
        }
    }
}

struct WidgetSanctuaryOrbs: View {
    var intensity: Double = 1

    var body: some View {
        ZStack {
            Circle()
                .fill(WidgetPalette.meshLilac.opacity(0.22 * intensity))
                .frame(width: 140, height: 140)
                .blur(radius: 1)
                .offset(x: -58, y: -42)
            Circle()
                .fill(WidgetPalette.meshSky.opacity(0.20 * intensity))
                .frame(width: 110, height: 110)
                .blur(radius: 2)
                .offset(x: 64, y: 48)
            Circle()
                .fill(WidgetPalette.meshGold.opacity(0.12 * intensity))
                .frame(width: 72, height: 72)
                .blur(radius: 1)
                .offset(x: 40, y: -56)
        }
    }
}

/// Completed devotion — warm sage celebration wash.
struct WidgetCompletedBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    WidgetPalette.orbSage.opacity(0.92),
                    WidgetPalette.orbTeal.opacity(0.88),
                    WidgetPalette.pillTeal.opacity(0.82),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            WidgetSanctuaryOrbs(intensity: 0.35)
        }
    }
}

struct WidgetAdaptiveBackground: View {
    var completed: Bool

    var body: some View {
        if completed {
            WidgetCompletedBackground()
        } else {
            WidgetSanctuaryBackground()
        }
    }
}

// MARK: - Cards & chrome

struct WidgetPaperCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    var peachAccent = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(WidgetPalette.warmPaper)
                    .shadow(color: .black.opacity(0.07), radius: 14, y: 5)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: peachAccent
                                ? [
                                    WidgetPalette.moodPeach.opacity(0.95),
                                    WidgetPalette.pillOrange.opacity(0.35),
                                    WidgetPalette.moodPeach.opacity(0.6),
                                ]
                                : [
                                    WidgetPalette.meshPeriwinkle.opacity(0.55),
                                    WidgetPalette.meshLilac.opacity(0.45),
                                    WidgetPalette.meshSky.opacity(0.35),
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct WidgetBrandMark: View {
    var compact = false
    var onDark = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "sparkles")
                .font(.system(size: compact ? 9 : 10, weight: .semibold))
                .foregroundStyle(onDark ? .white.opacity(0.9) : WidgetPalette.pillPurple)
            Text("DEVOTION LOCK")
                .font(WidgetTypography.micro(compact ? 8 : 9))
                .tracking(0.8)
                .foregroundStyle(onDark ? .white.opacity(0.82) : WidgetPalette.textTertiary)
        }
    }
}

struct WidgetCTAPill: View {
    let title: String
    var tint: Color = WidgetPalette.textPrimary

    var body: some View {
        Text(title)
            .font(WidgetTypography.label(11))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(tint)
            .clipShape(Capsule())
    }
}

// MARK: - Streak visuals

struct WidgetWeekRingRow: View {
    let flags: [Bool]
    var onDark = false
    var compact = false

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return (0..<7).map { i in
            String(symbols[(i + start) % 7].prefix(1))
        }
    }

    private var todayIndex: Int {
        let today = Calendar.current.component(.weekday, from: Date()) - Calendar.current.firstWeekday
        return today < 0 ? today + 7 : today
    }

    var body: some View {
        HStack(spacing: compact ? 3 : 5) {
            ForEach(0..<7, id: \.self) { index in
                dayCell(index: index)
            }
        }
    }

    @ViewBuilder
    private func dayCell(index: Int) -> some View {
        let completed = flags.indices.contains(index) && flags[index]
        let isToday = index == todayIndex
        let size: CGFloat = compact ? 15 : 18

        VStack(spacing: compact ? 2 : 3) {
            ZStack {
                if completed {
                    Circle()
                        .fill(WidgetPalette.moodGreen)
                        .frame(width: size, height: size)
                    Image(systemName: "checkmark")
                        .font(.system(size: compact ? 6 : 7, weight: .bold))
                        .foregroundStyle(WidgetPalette.textPrimary.opacity(0.72))
                } else if isToday {
                    Circle()
                        .stroke(WidgetPalette.pillOrange, lineWidth: compact ? 1.5 : 2)
                        .frame(width: size, height: size)
                } else {
                    Circle()
                        .fill(onDark ? Color.white.opacity(0.14) : WidgetPalette.textPrimary.opacity(0.07))
                        .frame(width: size, height: size)
                }
            }
            Text(weekdaySymbols[index])
                .font(WidgetTypography.micro(compact ? 7 : 8))
                .foregroundStyle(onDark ? .white.opacity(0.65) : WidgetPalette.textTertiary)
        }
    }
}

struct WidgetStreakRing: View {
    let streak: Int
    let weekFlags: [Bool]
    var diameter: CGFloat = 72
    var onDark = false
    var accent: Color = WidgetPalette.pillOrange

    private var weekProgress: Double {
        Double(weekFlags.filter { $0 }.count) / 7
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    onDark ? Color.white.opacity(0.20) : WidgetPalette.textPrimary.opacity(0.08),
                    lineWidth: 5
                )
            Circle()
                .trim(from: 0, to: max(weekProgress, streak > 0 ? 0.12 : 0.06))
                .stroke(
                    AngularGradient(
                        colors: onDark
                            ? [accent, accent.opacity(0.55), accent]
                            : [WidgetPalette.pillTeal, WidgetPalette.orbSage, WidgetPalette.pillTeal],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: diameter * 0.16, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(.bottom, 1)
                Text("\(streak)")
                    .font(WidgetTypography.streakNumber(diameter * 0.34))
                    .foregroundStyle(onDark ? .white : WidgetPalette.textPrimary)
                Text(streak == 1 ? "day" : "days")
                    .font(.system(size: diameter * 0.13, weight: .semibold, design: .rounded))
                    .foregroundStyle(onDark ? .white.opacity(0.78) : WidgetPalette.textSecondary)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

// MARK: - Prayer notes

struct WidgetPaperNote: View {
    let text: String
    let kind: String
    let tintIndex: Int
    let rotation: Double
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 5) {
            HStack(spacing: 4) {
                Image(systemName: kindIcon)
                    .font(.system(size: compact ? 8 : 9, weight: .semibold))
                Text(kindLabel)
                    .font(WidgetTypography.micro(compact ? 8 : 9))
            }
            .foregroundStyle(WidgetPalette.kindAccent(kind))

            Text(text)
                .font(WidgetTypography.quote(compact ? 11 : 12))
                .foregroundStyle(WidgetPalette.textPrimary)
                .lineLimit(compact ? 3 : 4)
                .minimumScaleFactor(0.85)
        }
        .padding(compact ? 8 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: compact ? 9 : 11, style: .continuous)
                .fill(WidgetPalette.paperColor(index: tintIndex))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
        .overlay(alignment: .top) {
            Capsule()
                .fill(WidgetPalette.kindAccent(kind).opacity(0.35))
                .frame(width: compact ? 22 : 28, height: 4)
                .offset(y: -2)
        }
        .rotationEffect(.degrees(rotation))
    }

    private var kindIcon: String {
        switch kind {
        case "request": "hands.sparkles.fill"
        case "reminder": "bell.fill"
        case "answered": "checkmark.seal.fill"
        default: "heart.fill"
        }
    }

    private var kindLabel: String {
        switch kind {
        case "request": "Request"
        case "reminder": "Reminder"
        case "answered": "Answered"
        default: kind.capitalized
        }
    }
}

struct WidgetActionChip: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(tint.opacity(0.11))
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(tint.opacity(0.22), lineWidth: 0.8)
            }
    }
}

struct WidgetQuoteMark: View {
    var size: CGFloat = 36

    var body: some View {
        Text("\u{201C}")
            .font(.system(size: size, weight: .light, design: .serif))
            .foregroundStyle(WidgetPalette.moodPeachText.opacity(0.45))
    }
}

struct WidgetVerseReferencePill: View {
    let reference: String

    var body: some View {
        Text(reference)
            .font(WidgetTypography.label(10))
            .foregroundStyle(WidgetPalette.pillPurple)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(WidgetPalette.pillPurple.opacity(0.10))
            .clipShape(Capsule())
    }
}

// MARK: - Live Activity (unchanged API)

struct WidgetStepTrail: View {
    let current: Int
    let total: Int
    var compact = false
    var onDark = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<total, id: \.self) { index in
                HStack(spacing: 0) {
                    stepNode(index: index)
                    if index < total - 1 {
                        connector(filled: index < current)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func stepNode(index: Int) -> some View {
        let step = WidgetPalette.devotionSteps[min(index, WidgetPalette.devotionSteps.count - 1)]
        let isComplete = index < current
        let isCurrent = index == current

        VStack(spacing: compact ? 2 : 4) {
            ZStack {
                Circle()
                    .fill(nodeFill(complete: isComplete, current: isCurrent))
                    .frame(width: compact ? 18 : 22, height: compact ? 18 : 22)
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: compact ? 8 : 9, weight: .bold))
                        .foregroundStyle(onDark ? WidgetPalette.pillTeal : .white)
                } else {
                    Image(systemName: step.icon)
                        .font(.system(size: compact ? 7 : 8, weight: .semibold))
                        .foregroundStyle(isCurrent ? (onDark ? WidgetPalette.pillPurple : .white) : WidgetPalette.textSecondary.opacity(0.7))
                }
            }
            if !compact {
                Text(step.label)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(isCurrent ? WidgetPalette.textPrimary : WidgetPalette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(minWidth: compact ? 18 : 28)
    }

    private func connector(filled: Bool) -> some View {
        Capsule()
            .fill(filled ? WidgetPalette.pillTeal : WidgetPalette.textSecondary.opacity(0.18))
            .frame(height: compact ? 2 : 3)
            .frame(maxWidth: compact ? 10 : 14)
    }

    private func nodeFill(complete: Bool, current: Bool) -> Color {
        if complete { return onDark ? .white : WidgetPalette.pillTeal }
        if current { return onDark ? WidgetPalette.pillPurple.opacity(0.18) : WidgetPalette.pillPurple }
        return WidgetPalette.textSecondary.opacity(0.12)
    }
}

struct LiveActivityStepIcon: View {
    let icon: String
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            WidgetPalette.meshLilac.opacity(0.45),
                            WidgetPalette.pillPurple.opacity(0.28),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(WidgetPalette.pillPurple)
        }
        .frame(width: size, height: size)
    }
}

struct LiveActivityCompactProgress: View {
    let current: Int
    let total: Int

    private var fraction: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(current + 1) / CGFloat(total)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [WidgetPalette.pillTeal, WidgetPalette.pillPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, proxy.size.width * fraction))
            }
        }
        .frame(height: 4)
    }
}

struct LiveActivityLockBanner: View {
    let sessionTitle: String
    let stepTitle: String
    let stepIndex: Int
    let totalSteps: Int
    let elapsedSeconds: Int
    var session: SanctuaryLiveSession = .morningDevotion
    var breathsRemaining: Int = 0
    var breathPhaseLabel: String = ""

    private var step: (icon: String, label: String) {
        WidgetPalette.devotionSteps[min(stepIndex, WidgetPalette.devotionSteps.count - 1)]
    }

    private var displayIcon: String {
        guard session == .prayerBreath else { return step.icon }
        switch breathPhaseLabel.lowercased() {
        case "inhale": return "arrow.up.circle.fill"
        case "hold": return "pause.circle.fill"
        case "exhale": return "arrow.down.circle.fill"
        default: return "wind"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            LiveActivityCompactProgress(current: stepIndex, total: totalSteps)
                .padding(.top, 10)
            footerStrip
        }
    }

    private var mainRow: some View {
        HStack(alignment: .center, spacing: 12) {
            LiveActivityStepIcon(icon: displayIcon, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                if session == .prayerBreath {
                    Text(breathPhaseLabel.isEmpty ? "Breathe" : breathPhaseLabel)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(breathsRemaining > 0 ? "\(breathsRemaining) breaths left" : stepTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(formattedElapsed)
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    ViewThatFits(in: .horizontal) {
                        Text(stepTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(step.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 4)

            Text(session == .prayerBreath ? "\(breathsRemaining)" : "\(stepIndex + 1)/\(totalSteps)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(WidgetPalette.pillPurple)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(WidgetPalette.pillPurple.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    private var footerStrip: some View {
        HStack(spacing: 8) {
            Label {
                Text(sessionTitle)
                    .lineLimit(1)
            } icon: {
                Image(systemName: session == .prayerBreath ? "wind" : "sparkles")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)

            Spacer(minLength: 0)

            Text(footerCaption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.top, 10)
        .padding(.bottom, 2)
    }

    private var footerCaption: String {
        if stepIndex >= totalSteps - 1 { return "Almost done" }
        if stepIndex == 0 { return "In your sanctuary" }
        return "Hang in there"
    }

    private var formattedElapsed: String {
        let minutes = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
