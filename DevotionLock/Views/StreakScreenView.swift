//
//  StreakScreenView.swift
//  DevotionLock
//

import SwiftUI

struct StreakScreenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette
    var streakManager: StreakManager

    @State private var displayedMonth = Date()
    @State private var appeared = false

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        ZStack(alignment: .top) {
            ABYCleanGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    mainCard
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 40)
            }
        }
        .abyScreen()
        .onAppear {
            withAnimation(AppTheme.springGentle.delay(0.08)) { appeared = true }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(palette.surface)
                    .clipShape(Circle())
            }
            Spacer()
            Text("Streaks & Stats")
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
    }

    private var mainCard: some View {
        VStack(spacing: 0) {
            streakHero
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 20)

            Divider().overlay(palette.divider)

            statsRow
                .padding(.vertical, 16)
                .padding(.horizontal, 20)

            Divider().overlay(palette.divider)

            calendarSection
                .padding(.vertical, 20)

            Divider().overlay(palette.divider)

            StreakChallengeBar(progress: streakManager.challengeProgress)
                .padding(.vertical, 20)

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                Text("Your mood for today will be available after midnight")
            }
            .font(ABY.Font.caption)
            .foregroundStyle(palette.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(palette.cardShadowOpacity), radius: 20, y: 8)
    }

    private var streakHero: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                AnimatedStreakNumber(target: streakManager.currentStreak)
                Text("day streak!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(StreakPalette.orange)
                Text("Morning devotion")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
                    .padding(.top, 4)
            }

            Spacer(minLength: 8)

            Image(systemName: "flame.fill")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(
                        colors: [StreakPalette.orangeLight, StreakPalette.orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: StreakPalette.orange.opacity(0.25), radius: 8, y: 3)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StreakInlineStat(icon: "sun.max.fill", value: streakManager.daysJournaled, label: "Days journaled")
            StreakInlineStat(icon: "square.and.pencil", value: streakManager.entryCount, label: "Entries written")
        }
    }

    private var calendarSection: some View {
        StreakCalendarGrid(
            days: streakManager.calendarDays(for: displayedMonth),
            monthTitle: monthTitle,
            onPreviousMonth: { shiftMonth(by: -1) },
            onNextMonth: { shiftMonth(by: 1) }
        )
    }

    private func shiftMonth(by value: Int) {
        withAnimation(AppTheme.springSnappy) {
            displayedMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
        }
    }
}

private struct StreakInlineStat: View {
    @Environment(\.sanctuaryPalette) private var palette
    let icon: String
    let value: Int
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(StreakPalette.orange)
                .frame(width: 24)
            Text("\(value) \(label.lowercased())")
                .font(ABY.Font.subheadline)
                .foregroundStyle(palette.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(palette.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.card))
    }
}

#Preview {
    StreakScreenView(streakManager: .shared)
}
