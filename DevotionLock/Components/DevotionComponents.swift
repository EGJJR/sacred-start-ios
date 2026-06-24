//
//  DevotionComponents.swift
//  test1
//

import SwiftUI

struct LowPolyDove: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w / 2
            let cy = h / 2

            var body = Path()
            body.move(to: CGPoint(x: cx, y: cy + h * 0.22))
            body.addLine(to: CGPoint(x: cx - w * 0.08, y: cy + h * 0.08))
            body.addLine(to: CGPoint(x: cx - w * 0.06, y: cy - h * 0.02))
            body.addLine(to: CGPoint(x: cx, y: cy + h * 0.04))
            body.addLine(to: CGPoint(x: cx + w * 0.06, y: cy - h * 0.02))
            body.addLine(to: CGPoint(x: cx + w * 0.08, y: cy + h * 0.08))
            body.closeSubpath()
            context.fill(body, with: .color(DevotionTheme.sage.opacity(0.9)))

            var leftWing = Path()
            leftWing.move(to: CGPoint(x: cx - w * 0.06, y: cy - h * 0.02))
            leftWing.addLine(to: CGPoint(x: cx - w * 0.42, y: cy - h * 0.18))
            leftWing.addLine(to: CGPoint(x: cx - w * 0.38, y: cy + h * 0.02))
            leftWing.addLine(to: CGPoint(x: cx - w * 0.12, y: cy + h * 0.04))
            leftWing.closeSubpath()
            context.fill(leftWing, with: .color(DevotionTheme.teal.opacity(0.85)))

            var rightWing = Path()
            rightWing.move(to: CGPoint(x: cx + w * 0.06, y: cy - h * 0.02))
            rightWing.addLine(to: CGPoint(x: cx + w * 0.42, y: cy - h * 0.18))
            rightWing.addLine(to: CGPoint(x: cx + w * 0.38, y: cy + h * 0.02))
            rightWing.addLine(to: CGPoint(x: cx + w * 0.12, y: cy + h * 0.04))
            rightWing.closeSubpath()
            context.fill(rightWing, with: .color(DevotionTheme.teal.opacity(0.75)))

            var head = Path()
            head.move(to: CGPoint(x: cx, y: cy - h * 0.02))
            head.addLine(to: CGPoint(x: cx + w * 0.04, y: cy - h * 0.14))
            head.addLine(to: CGPoint(x: cx + w * 0.1, y: cy - h * 0.08))
            head.closeSubpath()
            context.fill(head, with: .color(DevotionTheme.sage))

            var tail = Path()
            tail.move(to: CGPoint(x: cx, y: cy + h * 0.04))
            tail.addLine(to: CGPoint(x: cx - w * 0.06, y: cy + h * 0.2))
            tail.addLine(to: CGPoint(x: cx + w * 0.06, y: cy + h * 0.2))
            tail.closeSubpath()
            context.fill(tail, with: .color(DevotionTheme.deepBlue.opacity(0.7)))
        }
    }
}

struct StreakRing: View {
    let data: StreakData

    @State private var animatedProgress: CGFloat = 0

    private var weekProgress: CGFloat {
        CGFloat(data.completedDays.filter { $0 }.count) / CGFloat(data.completedDays.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(DevotionTheme.surfaceGlow, lineWidth: 6)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: animatedProgress * weekProgress)
                    .stroke(
                        DevotionTheme.accentGradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(data.currentStreak)")
                        .font(ABY.Font.title2)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("days")
                        .font(ABY.Font.micro)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            HStack(spacing: 6) {
                ForEach(Array(data.completedDays.enumerated()), id: \.offset) { _, completed in
                    Circle()
                        .fill(completed ? DevotionTheme.sage : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(
                                    completed ? DevotionTheme.sage.opacity(0.5) : AppTheme.textTertiary.opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )
                        .frame(width: 8, height: 8)
                }
            }

            Text("Morning streak")
                .font(ABY.Font.captionMedium)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .darkGlass(cornerRadius: 16)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                animatedProgress = 1
            }
        }
    }
}

struct DailyFocusCard: View {
    let focus: DailyFocus

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's focus")
                    .font(ABY.Font.captionSemibold)
                    .foregroundStyle(DevotionTheme.sage)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Spacer()
                Text(focus.mood)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DevotionTheme.sage.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text("\"\(focus.verse)\"")
                .font(ABY.Font.callout)
                .italic()
                .foregroundStyle(AppTheme.textPrimary.opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(focus.reference)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(DevotionTheme.teal.opacity(0.9))

            HStack(spacing: 4) {
                Text("Begin morning devotion")
                    .font(ABY.Font.captionMedium)
                Image(systemName: "arrow.right")
                    .font(ABY.Font.paywallPromoBadge)
            }
            .foregroundStyle(DevotionTheme.sage.opacity(0.85))
            .padding(.top, 4)
        }
        .padding(16)
        .darkGlass(cornerRadius: 16)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(DevotionTheme.cardGradient)
                .frame(width: 3)
                .padding(.vertical, 12)
        }
        .scaleEffect(appeared ? 1 : 0.97)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(AppTheme.springGentle.delay(0.15)) {
                appeared = true
            }
        }
    }
}

struct ChaplainReflectionCard: View {
    let insight: AIInsight

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [insight.accent, DevotionTheme.teal.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.vertical, 4)

            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(insight.accent.opacity(0.12))
                        .frame(width: 40, height: 40)
                        .shadow(color: insight.accent.opacity(0.15), radius: 8, y: 2)
                    Image(systemName: insight.icon)
                        .font(ABY.Font.body)
                        .foregroundStyle(insight.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(insight.title)
                        .font(ABY.Font.bodySemibold)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(insight.body)
                        .font(ABY.Font.callout)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineSpacing(3)
                }
            }
            .padding(.leading, 14)
        }
        .padding(16)
        .darkGlass(cornerRadius: 16)
    }
}

struct SpiritualThemeRow: View {
    let theme: SpiritualTheme

    @State private var animatedStrength: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: theme.icon)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(theme.color.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .background(theme.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(theme.label)
                    .font(ABY.Font.calloutMedium)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.85))

                Spacer()

                Text(theme.depth.rawValue)
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(theme.color.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(theme.color.opacity(0.1))
                    .clipShape(Capsule())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [theme.color, theme.color.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedStrength, height: 6)
                        .shadow(color: theme.color.opacity(0.4), radius: 4, x: geo.size.width * animatedStrength - 4)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .darkGlass(cornerRadius: 12)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animatedStrength = theme.strength
            }
        }
    }
}

#Preview {
    ZStack {
        DevotionBackground()
        ScrollView {
            VStack(spacing: 16) {
                DevotionOrb(size: 160)
                HStack(alignment: .top, spacing: 12) {
                    StreakRing(data: .sample)
                    DailyFocusCard(focus: .sample)
                }
                ChaplainReflectionCard(insight: AIInsight.samples[0])
                SpiritualThemeRow(theme: SpiritualTheme.samples[0])
            }
            .padding()
        }
    }
}
