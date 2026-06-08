//
//  StreakComponents.swift
//  DevotionLock
//

import SwiftUI

enum StreakPalette {
    static let orange = Color(red: 1.0, green: 0.55, blue: 0.22)
    static let orangeLight = Color(red: 1.0, green: 0.72, blue: 0.28)
    static let moodGreen = Color(red: 0.62, green: 0.90, blue: 0.72)
    static let pastCircle = Color.black.opacity(0.08)
    static let faceInk = Color.black.opacity(0.72)
}

/// ABY-style line-art smiley — avoids emoji + custom-font tofu glyphs.
struct StreakMoodFace: View {
    @Environment(\.sanctuaryPalette) private var palette
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w / 2
            let eyeY = h * 0.36
            let eyeSpacing = w * 0.2
            let eyeRadius: CGFloat = 1.5

            for offset in [-eyeSpacing, eyeSpacing] {
                let rect = CGRect(
                    x: cx + offset - eyeRadius,
                    y: eyeY - eyeRadius,
                    width: eyeRadius * 2,
                    height: eyeRadius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(StreakPalette.faceInk))
            }

            var smile = Path()
            smile.addArc(
                center: CGPoint(x: cx, y: h * 0.54),
                radius: w * 0.17,
                startAngle: .degrees(15),
                endAngle: .degrees(165),
                clockwise: false
            )
            context.stroke(
                smile,
                with: .color(StreakPalette.faceInk),
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
            )
        }
        .frame(width: 18, height: 18)
        .accessibilityLabel("Completed")
    }
}

struct ABYFlameBadge: View {
    @Environment(\.sanctuaryPalette) private var palette
    let streak: Int
    var action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(StreakPalette.orange)
                    .scaleEffect(pulse ? 1.06 : 1.0)
                Text("\(streak)")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(StreakPalette.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(palette.surface)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct ABYWeeklyStrip: View {
    @Environment(\.sanctuaryPalette) private var palette
    let completedDays: [Bool]

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                let completed = completedDays.indices.contains(index) ? completedDays[index] : false
                VStack(spacing: 6) {
                    Text(weekdaySymbol(for: index))
                        .font(ABY.Font.caption)
                        .foregroundStyle(isToday(index) ? palette.textPrimary : palette.textTertiary)
                    dayIndicator(completed: completed, isToday: isToday(index))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
    }

    @ViewBuilder
    private func dayIndicator(completed: Bool, isToday: Bool) -> some View {
        ZStack {
            if completed {
                Circle()
                    .fill(StreakPalette.moodGreen)
                    .frame(width: 28, height: 28)
                StreakMoodFace()
            } else if isToday {
                Circle()
                    .stroke(StreakPalette.orange, lineWidth: 2)
                    .frame(width: 28, height: 28)
            } else {
                Circle()
                    .fill(StreakPalette.pastCircle)
                    .frame(width: 28, height: 28)
            }
        }
        .frame(width: 28, height: 28)
    }

    private func isToday(_ index: Int) -> Bool {
        let todayIndex = calendar.component(.weekday, from: Date()) - calendar.firstWeekday
        let normalized = todayIndex < 0 ? todayIndex + 7 : todayIndex
        return index == normalized
    }

    private func weekdaySymbol(for index: Int) -> String {
        let symbols = calendar.shortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        let symbol = symbols[(index + start) % 7]
        return String(symbol.prefix(1))
    }
}

// MARK: - Calendar (ABY: circle above, date below)

struct StreakCalendarGrid: View {
    @Environment(\.sanctuaryPalette) private var palette
    let days: [StreakCalendarDay]
    let monthTitle: String
    var onPreviousMonth: () -> Void
    var onNextMonth: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let indicatorSize: CGFloat = 32
    private let cellHeight: CGFloat = 58

    private var weekdayHeaders: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return (0..<7).map { i in
            String(symbols[(i + start) % 7].prefix(2))
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            monthHeader

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdayHeaders, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 18)
                }

                ForEach(days) { day in
                    calendarCell(day)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private var monthHeader: some View {
        HStack {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text(monthTitle)
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
            Spacer()
            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
    }

    @ViewBuilder
    private func calendarCell(_ day: StreakCalendarDay) -> some View {
        if day.isInMonth {
            VStack(spacing: 6) {
                dayIndicator(for: day)
                dayLabel(for: day)
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight, alignment: .top)
        } else {
            Color.clear
                .frame(height: cellHeight)
        }
    }

    @ViewBuilder
    private func dayIndicator(for day: StreakCalendarDay) -> some View {
        ZStack {
            if day.isCompleted {
                Circle()
                    .fill(StreakPalette.moodGreen)
                    .frame(width: indicatorSize, height: indicatorSize)
                StreakMoodFace()
            } else if day.isToday {
                Circle()
                    .stroke(StreakPalette.orange, lineWidth: 2)
                    .frame(width: indicatorSize, height: indicatorSize)
            } else if day.isFuture {
                Circle()
                    .stroke(palette.track, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .frame(width: indicatorSize, height: indicatorSize)
            } else {
                Circle()
                    .fill(StreakPalette.pastCircle)
                    .frame(width: indicatorSize, height: indicatorSize)
            }
        }
        .frame(width: indicatorSize, height: indicatorSize)
    }

    @ViewBuilder
    private func dayLabel(for day: StreakCalendarDay) -> some View {
        if day.isToday {
            Text("\(day.day)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(StreakPalette.orange)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(StreakPalette.orange.opacity(0.14))
                .clipShape(Capsule())
        } else {
            Text("\(day.day)")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(day.isFuture ? palette.textTertiary : palette.textSecondary)
        }
    }
}

// MARK: - Challenge bar

struct StreakChallengeBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    let progress: Int
    let goal: Int = 7

    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Day \(progress)")
                    .font(ABY.Font.headline)
                    .foregroundStyle(StreakPalette.orange)
                Text("of \(goal)-day challenge")
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.track)
                        .frame(height: 6)

                    Capsule()
                        .fill(StreakPalette.orange)
                        .frame(width: max(6, geo.size.width * animatedProgress), height: 6)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(StreakPalette.orange)
                        .clipShape(Circle())
                        .offset(x: max(0, geo.size.width * animatedProgress - 11))

                    HStack {
                        Spacer()
                        Text("\(goal)")
                            .font(ABY.Font.captionMedium)
                            .foregroundStyle(palette.textTertiary)
                            .frame(width: 22, height: 22)
                            .background(palette.background)
                            .clipShape(Circle())
                    }
                }
            }
            .frame(height: 22)
        }
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedProgress = CGFloat(progress) / CGFloat(goal)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(AppTheme.springGentle) {
                animatedProgress = CGFloat(newValue) / CGFloat(goal)
            }
        }
    }
}

struct AnimatedStreakNumber: View {
    @Environment(\.sanctuaryPalette) private var palette
    let target: Int
    var color: Color = StreakPalette.orange
    @State private var displayed = 0

    var body: some View {
        Text("\(displayed)")
            .font(.system(size: 56, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .onAppear { animateCount() }
            .onChange(of: target) { _, _ in animateCount() }
    }

    private func animateCount() {
        guard target > 0 else {
            displayed = 0
            return
        }
        displayed = 0
        for step in 1...target {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.08) {
                withAnimation(AppTheme.springSnappy) {
                    displayed = step
                }
            }
        }
    }
}
