//
//  CleanStreakView.swift
//  DevotionLock
//
//  Clean-app streak celebration — matches the Solace-style reference shell.
//

import SwiftUI

struct CleanStreakView: View {
    @Environment(\.dismiss) private var dismiss
    var streakManager: StreakManager

    @State private var appeared = false

    private var togetherCopy: String {
        let days = max(streakManager.daysJournaled, streakManager.currentStreak)
        if days <= 0 {
            return "Your first day starts now."
        }
        if days == 1 {
            return "1 day together since you began."
        }
        return "\(days) days together since you began."
    }

    var body: some View {
        ZStack(alignment: .top) {
            CleanDesign.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        SolarDuotone.Glyph(
                            icon: .close,
                            size: 28,
                            primary: CleanDesign.Color.textSecondary,
                            secondary: CleanDesign.Color.textTertiary.opacity(0.45)
                        )
                        .frame(width: 44, height: 44)
                        .background(CleanDesign.Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.radius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")

                    Spacer()
                }
                .padding(.horizontal, CleanDesign.Spacing.screen)
                .padding(.top, 12)

                Spacer(minLength: 24)

                VStack(spacing: 20) {
                    Text("Your streak")
                        .font(CleanDesign.Font.title)
                        .foregroundStyle(CleanDesign.Color.textSecondary)

                    ZStack {
                        ForEach(0..<4, id: \.self) { i in
                            Diamond()
                                .fill(CleanDesign.Color.flame.opacity(0.35))
                                .frame(width: 8, height: 8)
                                .offset(sparkleOffset(i))
                                .opacity(appeared ? 1 : 0)
                        }

                        SolarDuotone.Glyph(
                            icon: .flame,
                            size: 88,
                            primary: CleanDesign.Color.flame,
                            secondary: CleanDesign.Color.flameSoft
                        )
                        .scaleEffect(appeared ? 1 : 0.86)
                    }
                    .frame(height: 120)

                    VStack(spacing: 6) {
                        Text("\(streakManager.currentStreak)")
                            .font(CleanDesign.Font.metric)
                            .foregroundStyle(CleanDesign.Color.textPrimary)
                            .monospacedDigit()

                        Text(streakManager.currentStreak == 1 ? "day streak!" : "day streak!")
                            .font(CleanDesign.Font.title)
                            .foregroundStyle(CleanDesign.Color.textPrimary)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                Spacer()

                HStack(spacing: 14) {
                    SolarDuotone.Glyph(
                        icon: .flame,
                        size: 28,
                        primary: CleanDesign.Color.flame,
                        secondary: CleanDesign.Color.flameSoft
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("You've been showing up lately")
                            .font(CleanDesign.Font.title)
                            .foregroundStyle(CleanDesign.Color.textPrimary)
                        Text(togetherCopy)
                            .font(CleanDesign.Font.body)
                            .foregroundStyle(CleanDesign.Color.textSecondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(18)
                .background(CleanDesign.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: CleanDesign.radius, style: .continuous))
                .padding(.horizontal, CleanDesign.Spacing.screen)
                .padding(.bottom, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05)) {
                appeared = true
            }
        }
    }

    private func sparkleOffset(_ index: Int) -> CGSize {
        switch index {
        case 0: CGSize(width: -52, height: -28)
        case 1: CGSize(width: 56, height: -36)
        case 2: CGSize(width: -48, height: 36)
        default: CGSize(width: 50, height: 28)
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    CleanStreakView(streakManager: .shared)
}
