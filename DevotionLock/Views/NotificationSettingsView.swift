//
//  NotificationSettingsView.swift
//  DevotionLock
//

import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("morningReminderEnabled") private var morningEnabled = true
    @AppStorage("eveningReminderEnabled") private var eveningEnabled = false
    @AppStorage("streakNudgeEnabled") private var streakEnabled = true
    @AppStorage("affirmationEnabled") private var affirmationEnabled = true
    @AppStorage("prayerWallReminderEnabled") private var prayerWallEnabled = false
    @AppStorage("notificationTone") private var toneRaw = NotificationTone.gentle.rawValue

    @State private var showPreview = false
    @State private var previewKind: DevotionNotificationCategory = .morning
    @State private var authorizationDenied = false

    private var tone: NotificationTone {
        NotificationTone(rawValue: toneRaw) ?? .gentle
    }

    var body: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                ABYDetailHeader(
                    title: "Notifications",
                    subtitle: "Gentle nudges and direct streak reminders — your choice."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 20)

                settingsSection("Tone") {
                    Picker("Tone", selection: $toneRaw) {
                        ForEach(NotificationTone.allCases) { item in
                            Text(item.label).tag(item.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(ABY.Spacing.card)
                    .onChange(of: toneRaw) { _, _ in reschedule() }
                }

                settingsSection("Daily") {
                    toggleRow("Morning sanctuary", isOn: $morningEnabled)
                    ABYSettingsDivider()
                    toggleRow("Evening reflection", isOn: $eveningEnabled)
                }

                settingsSection("Encouragement") {
                    toggleRow("Streak nudge (2:30 PM)", isOn: $streakEnabled)
                    ABYSettingsDivider()
                    toggleRow("Verse of the day (noon)", isOn: $affirmationEnabled)
                    ABYSettingsDivider()
                    toggleRow("Prayer wall (Sundays)", isOn: $prayerWallEnabled)
                }

                settingsSection("Preview") {
                    ForEach([DevotionNotificationCategory.morning, .evening, .streak, .prayerWall], id: \.rawValue) { kind in
                        Button {
                            previewKind = kind
                            showPreview = true
                        } label: {
                            HStack {
                                Text(previewTitle(for: kind))
                                    .font(ABY.Font.callout)
                                    .foregroundStyle(ABY.Color.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(ABY.Font.captionSemibold)
                                    .foregroundStyle(ABY.Color.textTertiary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, ABY.Spacing.card)
                        }
                        .buttonStyle(.plain)
                        if kind != .prayerWall { ABYSettingsDivider() }
                    }
                }

                if authorizationDenied {
                    Text("Notifications are off in iOS Settings. Enable them to receive reminders.")
                        .font(ABY.Font.footnote)
                        .foregroundStyle(ABY.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.top, 12)
                }
            }
        }
        .abySettingsBackNavigation()
        .sheet(isPresented: $showPreview) {
            NotificationBannerPreviewView(category: previewKind, tone: tone)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .task {
            let status = await NotificationManager.shared.authorizationStatus()
            authorizationDenied = status == .denied
            if status == .notDetermined {
                let granted = await NotificationManager.shared.requestAuthorization()
                authorizationDenied = !granted
            }
            reschedule()
        }
        .onChange(of: morningEnabled) { _, _ in reschedule() }
        .onChange(of: eveningEnabled) { _, _ in reschedule() }
        .onChange(of: streakEnabled) { _, _ in reschedule() }
        .onChange(of: affirmationEnabled) { _, _ in reschedule() }
        .onChange(of: prayerWallEnabled) { _, _ in reschedule() }
    }

    @ViewBuilder
    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        ABYSectionHeader(title: title)
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 8)
        ABYSettingsGroup { content() }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 20)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(ABY.Font.callout)
                .foregroundStyle(ABY.Color.textPrimary)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(ABY.Color.textPrimary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, ABY.Spacing.card)
    }

    private func previewTitle(for kind: DevotionNotificationCategory) -> String {
        switch kind {
        case .morning: "Preview morning banner"
        case .evening: "Preview evening banner"
        case .streak: "Preview streak nudge"
        case .prayerWall: "Preview prayer wall"
        default: "Preview"
        }
    }

    private func reschedule() {
        NotificationManager.shared.rescheduleAll()
    }
}

struct NotificationBannerPreviewView: View {
    let category: DevotionNotificationCategory
    let tone: NotificationTone

    var body: some View {
        VStack(spacing: 20) {
            Text("Notification preview")
                .font(ABY.Font.headline)
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ABY.Color.meshLilac.opacity(0.35), ABY.Color.gradientBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                notificationBanner
                    .padding(.horizontal, 14)
                    .padding(.top, 24)
            }
            Text("This is how it may appear on your lock screen.")
                .font(ABY.Font.footnote)
                .foregroundStyle(ABY.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(ABY.Spacing.screen)
        .background(ABYCleanGradientBackground())
    }

    private var notificationBanner: some View {
        let copy = NotificationManager.shared.previewContent(for: category, tone: tone)
        return HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [ABY.Color.pillTeal, ABY.Color.pillPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "flame.fill")
                        .font(ABY.Font.caption)
                        .foregroundStyle(.white)
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("DEVOTION LOCK")
                        .font(ABY.Font.paywallPromoBadge)
                        .foregroundStyle(ABY.Color.textSecondary)
                    Spacer()
                    Text("now")
                        .font(ABY.Font.micro)
                        .foregroundStyle(ABY.Color.textTertiary)
                }
                Text(copy.title)
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(ABY.Color.textPrimary)
                Text(copy.body)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(ABY.Color.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}
