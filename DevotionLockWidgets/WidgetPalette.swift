//
//  WidgetPalette.swift
//  DevotionLockWidgets
//

import SwiftUI
import WidgetKit

enum WidgetPalette {
    static let pillTeal = Color(red: 0.30, green: 0.62, blue: 0.58)
    static let pillPurple = Color(red: 0.55, green: 0.48, blue: 0.72)
    static let pillOrange = Color(red: 0.92, green: 0.55, blue: 0.32)
    static let orbSage = Color(red: 0.48, green: 0.68, blue: 0.56)
    static let meshLilac = Color(red: 0.74, green: 0.66, blue: 0.93)
    static let meshPeriwinkle = Color(red: 0.56, green: 0.66, blue: 0.91)
    static let warmCream = Color(red: 0.984, green: 0.948, blue: 0.908)
    static let textPrimary = Color.primary
    static let textSecondary = Color(red: 0.557, green: 0.557, blue: 0.576)
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

    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

struct WidgetSanctuaryBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.975, green: 0.968, blue: 0.992),
                    Color(red: 0.928, green: 0.918, blue: 0.958),
                    WidgetPalette.warmCream,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            WidgetSoftOrbs(intensity: 0.55)
        }
    }
}

struct WidgetStreakGradient: View {
    var completed: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: completed
                    ? [WidgetPalette.orbSage, WidgetPalette.pillTeal, Color(red: 0.36, green: 0.71, blue: 0.64)]
                    : [WidgetPalette.meshLilac, WidgetPalette.meshPeriwinkle, WidgetPalette.pillPurple.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            WidgetSoftOrbs(intensity: completed ? 0.35 : 0.5)
        }
    }
}

struct WidgetSoftOrbs: View {
    var intensity: Double = 1

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.22 * intensity))
                .frame(width: 120, height: 120)
                .blur(radius: 2)
                .offset(x: -50, y: -30)
            Circle()
                .fill(WidgetPalette.meshLilac.opacity(0.28 * intensity))
                .frame(width: 90, height: 90)
                .blur(radius: 4)
                .offset(x: 60, y: 40)
            Circle()
                .fill(Color.white.opacity(0.16 * intensity))
                .frame(width: 70, height: 70)
                .blur(radius: 2)
                .offset(x: 30, y: -50)
        }
    }
}

struct WidgetBrandMark: View {
    var compact = false
    var onDark = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: compact ? 10 : 11, weight: .semibold))
                .foregroundStyle(onDark ? .white.opacity(0.9) : WidgetPalette.pillPurple)
            Text("Devotion Lock")
                .font(WidgetTypography.label(compact ? 10 : 11))
                .foregroundStyle(onDark ? .white.opacity(0.92) : WidgetPalette.textSecondary)
        }
    }
}

struct WidgetWeekRingRow: View {
    let flags: [Bool]
    var onDark = true
    var compact = false

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.veryShortWeekdaySymbols
    }

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: compact ? 2 : 4) {
                    ZStack {
                        Circle()
                            .stroke(
                                onDark ? Color.white.opacity(0.35) : WidgetPalette.textSecondary.opacity(0.25),
                                lineWidth: 1.5
                            )
                            .frame(width: compact ? 16 : 20, height: compact ? 16 : 20)
                        if flags[index] {
                            Circle()
                                .fill(onDark ? Color.white : WidgetPalette.pillTeal)
                                .frame(width: compact ? 16 : 20, height: compact ? 16 : 20)
                            Image(systemName: "checkmark")
                                .font(.system(size: compact ? 7 : 8, weight: .bold))
                                .foregroundStyle(onDark ? WidgetPalette.pillTeal : .white)
                        }
                    }
                    Text(weekdaySymbols[index].prefix(1))
                        .font(.system(size: compact ? 8 : 9, weight: .medium, design: .rounded))
                        .foregroundStyle(onDark ? .white.opacity(0.72) : WidgetPalette.textSecondary)
                }
            }
        }
    }
}

struct WidgetStreakRing: View {
    let streak: Int
    let weekFlags: [Bool]
    var diameter: CGFloat = 72
    var onDark = true

    private var weekProgress: Double {
        Double(weekFlags.filter { $0 }.count) / 7
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    onDark ? Color.white.opacity(0.22) : WidgetPalette.textSecondary.opacity(0.15),
                    lineWidth: 5
                )
            Circle()
                .trim(from: 0, to: max(weekProgress, 0.08))
                .stroke(
                    AngularGradient(
                        colors: onDark
                            ? [.white.opacity(0.95), .white.opacity(0.55), .white.opacity(0.95)]
                            : [WidgetPalette.pillTeal, WidgetPalette.orbSage, WidgetPalette.pillTeal],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(streak)")
                    .font(WidgetTypography.streakNumber(diameter * 0.38))
                    .foregroundStyle(onDark ? .white : WidgetPalette.textPrimary)
                Text(streak == 1 ? "day" : "days")
                    .font(.system(size: diameter * 0.14, weight: .semibold, design: .rounded))
                    .foregroundStyle(onDark ? .white.opacity(0.82) : WidgetPalette.textSecondary)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

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
                    .font(.system(size: compact ? 8 : 9, weight: .semibold, design: .rounded))
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
            RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous)
                .fill(WidgetPalette.paperColor(index: tintIndex))
                .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
        )
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
            .fill(filled
                ? (onDark ? WidgetPalette.pillTeal : WidgetPalette.pillTeal)
                : (onDark ? Color.black.opacity(0.08) : WidgetPalette.textSecondary.opacity(0.18)))
            .frame(height: compact ? 2 : 3)
            .frame(maxWidth: compact ? 10 : 14)
    }

    private func nodeFill(complete: Bool, current: Bool) -> Color {
        if complete { return onDark ? .white : WidgetPalette.pillTeal }
        if current { return onDark ? WidgetPalette.pillPurple.opacity(0.18) : WidgetPalette.pillPurple }
        return onDark ? Color.black.opacity(0.06) : WidgetPalette.textSecondary.opacity(0.12)
    }
}

struct WidgetActionChip: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct WidgetQuoteMark: View {
    var body: some View {
        Text("“")
            .font(.system(size: 34, weight: .light, design: .serif))
            .foregroundStyle(WidgetPalette.pillPurple.opacity(0.35))
            .offset(y: -4)
    }
}

// MARK: - Live Activity

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

/// Thin progress bar sized for lock-screen Live Activities (max ~160pt total height).
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

    private var step: (icon: String, label: String) {
        WidgetPalette.devotionSteps[min(stepIndex, WidgetPalette.devotionSteps.count - 1)]
    }

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            LiveActivityCompactProgress(current: stepIndex, total: totalSteps)
                .padding(.top, 10)
            footerStrip
        }
    }

    /// Forest-style single row: icon · timer + label · step badge.
    private var mainRow: some View {
        HStack(alignment: .center, spacing: 12) {
            LiveActivityStepIcon(icon: step.icon, size: 40)

            VStack(alignment: .leading, spacing: 2) {
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

            Spacer(minLength: 4)

            Text("\(stepIndex + 1)/\(totalSteps)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(WidgetPalette.pillPurple)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(WidgetPalette.pillPurple.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    /// Subtle footer band — matches Forest / Apple 14pt margin rhythm.
    private var footerStrip: some View {
        HStack(spacing: 8) {
            Label {
                Text(sessionTitle)
                    .lineLimit(1)
            } icon: {
                Image(systemName: "sparkles")
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
