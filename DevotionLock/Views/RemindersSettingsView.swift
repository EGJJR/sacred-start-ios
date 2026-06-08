//
//  RemindersSettingsView.swift
//  test1
//

import SwiftUI

struct RemindersSettingsView: View {
    @AppStorage("morningReminderEnabled") private var morningEnabled = true
    @AppStorage("eveningReminderEnabled") private var eveningEnabled = false
    @AppStorage("morningReminderTime") private var morningTime = "7:00 AM"
    @AppStorage("eveningReminderTime") private var eveningTime = "6:00 PM"

    var body: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                ABYDetailHeader(
                    title: "Reminders",
                    subtitle: "Set reminders to make devotion a daily practice."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 24)

                reminderCard(
                    icon: "sun.horizon.fill",
                    title: "Morning devotion",
                    detail: "Start your day with intention before the world rushes in.",
                    time: morningTime,
                    isOn: $morningEnabled
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 12)

                reminderCard(
                    icon: "moon.stars.fill",
                    title: "Evening reflection",
                    detail: "Close the day with gratitude and gentle examen.",
                    time: eveningTime,
                    isOn: $eveningEnabled
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 24)

                Text("You're 3× more likely to maintain the practice with a consistent time.")
                    .font(ABY.Font.footnote)
                    .foregroundStyle(ABY.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, ABY.Spacing.screen)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar { ABYBackToolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: morningEnabled) { _, _ in NotificationManager.shared.rescheduleAll() }
        .onChange(of: eveningEnabled) { _, _ in NotificationManager.shared.rescheduleAll() }
    }

    private func reminderCard(
        icon: String,
        title: String,
        detail: String,
        time: String,
        isOn: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(ABY.Color.textSecondary)
                Text(title)
                    .font(ABY.Font.headline)
                    .foregroundStyle(ABY.Color.textPrimary)
                Spacer()
                ABYTimePill(time: time)
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(ABY.Color.textPrimary)
            }
            Text(detail)
                .font(ABY.Font.footnote)
                .foregroundStyle(ABY.Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .abyCard()
    }
}

#Preview {
    NavigationStack {
        RemindersSettingsView()
    }
}
