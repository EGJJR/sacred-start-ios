//
//  ShieldSettingsView.swift
//  test1
//

import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct ShieldSettingsView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @AppStorage("shieldEnabled") private var shieldEnabled = true
    @AppStorage("shieldStrictMode") private var strictMode = false

    @State private var shieldManager = AppShieldManager.shared
    #if canImport(FamilyControls)
    @State private var selection = ShieldSelectionStore.load() ?? FamilyActivitySelection()
    @State private var showActivityPicker = false
    #endif

    var body: some View {
        Group {
            if PaywallAccess.hasPremium {
                shieldSettingsContent
            } else {
                premiumRequiredContent
            }
        }
        .abySettingsBackNavigation()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var premiumRequiredContent: some View {
        ABYScreenContainer {
            VStack(spacing: 20) {
                ABYDetailHeader(
                    title: "App shield",
                    subtitle: "Block distracting apps until your morning devotion is complete."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)

                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(ABY.Font.heroIcon)
                        .foregroundStyle(ABY.Color.pillOrange)
                    Text("Premium feature")
                        .font(ABY.Font.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("Start your 5-day free trial to enable Screen Time shields and protect your mornings.")
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                    ABYPrimaryButton(title: "Start free trial") {
                        presentPaywall()
                    }
                }
                .padding(ABY.Spacing.card)
                .frame(maxWidth: .infinity)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
                .padding(.horizontal, ABY.Spacing.screen)

                Spacer()
            }
        }
    }

    private var shieldSettingsContent: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                ABYDetailHeader(
                    title: "App shield",
                    subtitle: "Uses Apple's Screen Time APIs to cover distracting apps until your morning devotion is complete."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 24)

                statusCard
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)

                ABYSettingsGroup {
                    ABYSettingsToggleRow(
                        icon: "lock.shield.fill",
                        title: "Enable shield",
                        detail: "Block selected apps each morning",
                        isOn: $shieldEnabled
                    )
                    .disabled(strictMode && !StreakManager.shared.isCompletedToday)
                    .onChange(of: shieldEnabled) { _, _ in
                        shieldManager.syncShieldState()
                    }
                    ABYSettingsDivider()
                    ABYSettingsToggleRow(
                        icon: "exclamationmark.shield.fill",
                        title: "Strict mode",
                        detail: "Keep shields on until devotion is finished",
                        isOn: $strictMode
                    )
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.bottom, 20)

                authorizationSection
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)

                shieldedAppsSection
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)

                infoFooter
                    .padding(.horizontal, ABY.Spacing.screen)

                #if DEBUG
                debugTestingSection
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 24)
                #endif
            }
        }
        .onAppear {
            shieldManager.refreshAuthorizationStatus()
            #if canImport(FamilyControls)
            if let saved = ShieldSelectionStore.load() {
                selection = saved
            }
            #endif
            shieldManager.syncShieldState()
        }
        #if canImport(FamilyControls)
        .familyActivityPicker(isPresented: $showActivityPicker, selection: $selection)
        .onChange(of: selection) { _, newValue in
            shieldManager.saveSelection(newValue)
        }
        #endif
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusTint.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: statusIcon)
                    .font(ABY.Font.headline)
                    .foregroundStyle(statusTint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)
                Text(statusDetail)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)
        }
        .padding(ABY.Spacing.card)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var authorizationSection: some View {
        ABYSectionHeader(title: "Screen Time access")
            .padding(.bottom, 8)

        ABYSettingsGroup {
            if shieldManager.isAuthorized {
                ABYSettingsRow(
                    icon: "checkmark.seal.fill",
                    title: "Authorized",
                    detail: "Face ID / Touch ID approved for this device",
                    value: nil
                ) {}
            } else {
                ABYSettingsRow(
                    icon: "person.badge.key.fill",
                    title: "Allow Screen Time access",
                    detail: "Required before Devotion Lock can shield apps",
                    value: nil
                ) {
                    Task { await shieldManager.requestAuthorization() }
                }
            }

            if let error = shieldManager.lastErrorMessage {
                ABYSettingsDivider()
                Text(error)
                    .font(ABY.Font.footnote)
                    .foregroundStyle(.red.opacity(0.85))
                    .padding(.horizontal, ABY.Spacing.card)
                    .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private var shieldedAppsSection: some View {
        ABYSectionHeader(title: "Shielded apps & sites")
            .padding(.bottom, 8)

        ABYSettingsGroup {
            #if canImport(FamilyControls)
            ABYSettingsRow(
                icon: "apps.iphone",
                title: "Choose what to shield",
                detail: shieldManager.isAuthorized
                    ? shieldManager.selectionSummary
                    : "Authorize Screen Time access first",
                value: nil
            ) {
                if shieldManager.isAuthorized {
                    showActivityPicker = true
                } else {
                    Task { await shieldManager.requestAuthorization() }
                }
            }
            .disabled(!shieldEnabled)
            #else
            ABYSettingsRow(
                icon: "apps.iphone",
                title: "Choose what to shield",
                detail: "Requires a physical iPhone or iPad",
                value: nil
            ) {}
            #endif
        }
    }

    private var infoFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "person.badge.key.fill")
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(palette.textTertiary)
                Text("App shield uses Apple's Family Controls entitlement. Approve Screen Time access on a physical iPhone to block selected apps until your devotion is complete.")
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(3)
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(palette.textTertiary)
                Text("Apple never reveals which apps you pick. Devotion Lock only stores opaque Screen Time tokens and applies a shield until today's devotion is complete.")
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(3)
            }

            #if targetEnvironment(simulator)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "iphone.gen3")
                    .font(ABY.Font.iconMedium)
                    .foregroundStyle(palette.textTertiary)
                Text("Screen Time shields do not work in the Simulator. Test on a physical device.")
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(3)
            }
            #endif
        }
    }

    private var statusTitle: String {
        if !shieldEnabled { return "Shield off" }
        if StreakManager.shared.isCompletedToday { return "Shield unlocked" }
        if shieldManager.isShieldActive { return "Apps shielded" }
        if !shieldManager.isAuthorized { return "Setup required" }
        if !shieldManager.hasSelection { return "Choose apps to shield" }
        return "Ready to shield"
    }

    private var statusDetail: String {
        if !shieldEnabled { return "Turn on the shield to block apps each morning." }
        if StreakManager.shared.isCompletedToday {
            return "Today's devotion is complete. Shields stay off until tomorrow."
        }
        if shieldManager.isShieldActive {
            return "Selected apps are covered until you finish your devotion."
        }
        if !shieldManager.isAuthorized {
            return "Approve Screen Time access to enable app blocking."
        }
        if !shieldManager.hasSelection {
            return "Pick the apps, categories, or websites to cover."
        }
        return "Shields apply when today's devotion isn't finished yet."
    }

    private var statusIcon: String {
        if !shieldEnabled { return "lock.open.fill" }
        if StreakManager.shared.isCompletedToday { return "lock.open.fill" }
        if shieldManager.isShieldActive { return "lock.shield.fill" }
        return "lock.shield"
    }

    private var statusTint: Color {
        if !shieldEnabled { return palette.textTertiary }
        if StreakManager.shared.isCompletedToday { return ABY.Color.pillTeal }
        if shieldManager.isShieldActive { return ABY.Color.pillOrange }
        return ABY.Color.pillPurple
    }

    #if DEBUG
    private var debugTestingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ABYSectionHeader(title: "Testing")
                .padding(.bottom, 2)

            Button(action: resetTodayDevotionForTesting) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(ABY.Font.headline)
                        .foregroundStyle(ABY.Color.pillOrange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset today's devotion")
                            .font(ABY.Font.calloutSemibold)
                            .foregroundStyle(palette.textPrimary)
                        Text("Simulates an incomplete morning. Shields re-apply on device.")
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                }
                .padding(ABY.Spacing.card)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func resetTodayDevotionForTesting() {
        StreakManager.shared.clearTodayForTesting()
        DailyRhythmStore.shared.clearTodayCompletions()
        shieldManager.syncShieldState()
        DevotionHaptics.medium()
    }
    #endif
}

#Preview {
    NavigationStack {
        ShieldSettingsView()
    }
}
