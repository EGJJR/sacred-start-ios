//
//  StreakScreenView.swift
//  DevotionLock
//
//  Mobbin ABY: https://mobbin.com/screens/49fcbbc9-a0d3-4a10-88a9-a791c3c8f1a6
//

import SwiftUI

struct StreakScreenView: View {
    @Environment(\.dismiss) private var dismiss
    var streakManager: StreakManager

    @State private var displayedMonth = Date()
    @State private var appeared = false

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var identity: StreakIdentity {
        streakManager.streakIdentity
    }

    var body: some View {
        ZStack(alignment: .top) {
            ABYStatsMeshBackground()

            VStack(spacing: 0) {
                ABYStreakScreenHeader(onDismiss: { dismiss() })
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ABYGlassPanel {
                            ABYStreakHero(
                                streak: streakManager.currentStreak,
                                statusName: identity.statusName
                            )
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                        HStack(spacing: 12) {
                            ABYGlassStatChip(
                                icon: "sun.max.fill",
                                value: "\(streakManager.daysJournaled)",
                                label: "Days journaled"
                            )
                            ABYGlassStatChip(
                                icon: "pencil.line",
                                value: "\(streakManager.entryCount)",
                                label: "Entries written"
                            )
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                        ABYGlassPanel(cornerRadius: 24, padding: 20) {
                            StreakCalendarGrid(
                                days: streakManager.calendarDays(for: displayedMonth),
                                monthTitle: monthTitle,
                                onPreviousMonth: { shiftMonth(by: -1) },
                                onNextMonth: { shiftMonth(by: 1) }
                            )
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)

                        ABYGlassPanel {
                            StreakChallengeBar(progress: streakManager.challengeProgress)
                        }
                        .opacity(appeared ? 1 : 0)

                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(ABY.Font.caption)
                            Text("Your mood for today will be available after midnight")
                        }
                        .font(ABY.Font.caption)
                        .foregroundStyle(ABY.Color.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 24)
                        .opacity(appeared ? 1 : 0)
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(AppTheme.springGentle.delay(0.08)) { appeared = true }
        }
    }

    private func shiftMonth(by value: Int) {
        withAnimation(AppTheme.springSnappy) {
            displayedMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
        }
    }
}

#Preview {
    StreakScreenView(streakManager: .shared)
}
