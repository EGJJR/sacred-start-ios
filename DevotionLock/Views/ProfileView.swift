//
//  ProfileView.swift
//  test1
//

import InAppKit
import SwiftUI

enum ProfileDestination: Hashable {
    case reminders
    case notifications
    case widgets
    case voice
    case shield
    case appearance
    case search
    case passages
    case about
    case journey
    case privacyPolicy
    case termsOfService
    case account
}

struct ProfileView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @Environment(\.authManager) private var auth
    @Environment(\.openStreakScreen) private var openStreakScreen
    @Environment(\.openMorningWrapped) private var openMorningWrapped
    @Environment(\.openJourneyTimeline) private var openJourneyTimeline
    @Environment(\.streakManager) private var streakManager

    @State private var journeyStore = JourneyTimelineStore.shared

    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"
    @AppStorage("intentionMood") private var intentionMood = "Peaceful"
    // @AppStorage(SanctuaryGradientMode.storageKey) private var gradientModeRaw = SanctuaryGradientMode.light.rawValue
    @AppStorage("morningReminderEnabled") private var morningReminder = true
    @AppStorage("shieldEnabled") private var shieldEnabled = true
    #if DEBUG
    @AppStorage(PaywallBypass.storageKey) private var paywallBypass = false
    #endif

    @State private var path = NavigationPath()
    @State private var appeared = false
    @State private var showMoodPicker = false
    @State private var inAppKit = InAppKit.shared

    private var voiceName: String {
        ChaplainVoice.options.first { $0.id == selectedVoiceID }?.name ?? "Grace"
    }

    // private var gradientModeLabel: String {
    //     (SanctuaryGradientMode(rawValue: gradientModeRaw) ?? .light).label
    // }

    var body: some View {
        NavigationStack(path: $path) {
            ABYScreenContainer {
                VStack(alignment: .leading, spacing: 0) {
                    ABYScreenHeader(title: "You", showDot: false, subtitle: "Settings & preferences")
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                        .opacity(appeared ? 1 : 0)

                    Button(action: openStreakScreen) {
                        ABYProfileHeader(
                            name: auth.displayName,
                            streakDays: streakManager.currentStreak,
                            avatarURL: auth.avatarURL
                        )
                    }
                    .buttonStyle(.plain)
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.bottom, 16)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)

                    Button(action: openStreakScreen) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your rhythm")
                                .font(ABY.Font.section)
                                .foregroundStyle(palette.textSecondary)
                            SanctuaryIdentityCard(identity: streakManager.streakIdentity)
                            SanctuaryGrowthBadgeRow(currentStage: streakManager.streakIdentity.stage)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                    DevotionTimelineSection(
                        streakManager: streakManager,
                        journeyStore: journeyStore,
                        onOpenJourney: openJourneyTimeline
                    )
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                    settingsSection("Account") {
                        ABYSettingsRow(
                            icon: "person.crop.circle",
                            title: "Profile",
                            detail: "Photo, username, sign out",
                            value: auth.displayName
                        ) {
                            path.append(ProfileDestination.account)
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(
                            icon: "sparkles",
                            title: "Premium",
                            detail: premiumStatusDetail,
                            value: nil
                        ) {
                            presentPaywall()
                        }
                    }

                    settingsSection("Daily rhythm") {
                        ABYSettingsRow(
                            icon: "bell.fill",
                            title: "Reminders",
                            detail: reminderSummary,
                            value: nil
                        ) {
                            path.append(ProfileDestination.reminders)
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(
                            icon: "app.badge.fill",
                            title: "Notifications",
                            detail: "Banners and previews",
                            value: nil
                        ) {
                            path.append(ProfileDestination.notifications)
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(
                            icon: "square.grid.2x2.fill",
                            title: "Widgets",
                            detail: "Streak, verse, prayer wall",
                            value: nil
                        ) {
                            path.append(ProfileDestination.widgets)
                        }
                    }

                    settingsSection("Experience") {
                        ABYSettingsRow(icon: "waveform", title: "Chaplain voice", detail: "For text chat replies", value: voiceName) {
                            path.append(ProfileDestination.voice)
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(icon: "leaf.fill", title: "Default mood", detail: "Morning check-in", value: intentionMood) {
                            showMoodPicker = true
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(
                            icon: "lock.shield.fill",
                            title: "App shield",
                            detail: shieldEnabled ? "On until devotion" : "Off",
                            value: nil
                        ) {
                            path.append(ProfileDestination.shield)
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(
                            icon: "magnifyingglass",
                            title: "Passages & promises",
                            detail: "Search, browse, library",
                            value: ScriptureLibraryStore.shared.count > 0 ? "\(ScriptureLibraryStore.shared.count) saved" : nil
                        ) {
                            path.append(ProfileDestination.passages)
                        }
                    }

                    settingsSection("More") {
                        ABYSettingsRow(icon: "sparkles", title: "Your week in review") {
                            openMorningWrapped()
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(icon: "questionmark.circle", title: "Help & about") {
                            path.append(ProfileDestination.about)
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(icon: "hand.raised.fill", title: "Privacy Policy") {
                            path.append(ProfileDestination.privacyPolicy)
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(icon: "doc.text.fill", title: "Terms of Service") {
                            path.append(ProfileDestination.termsOfService)
                        }
                    }

                    #if DEBUG
                    settingsSection("Developer") {
                        ABYSettingsToggleRow(
                            icon: "hammer.fill",
                            title: "Bypass paywall",
                            detail: "Unlock premium without purchasing",
                            isOn: $paywallBypass
                        )
                        .onChange(of: paywallBypass) { _, enabled in
                            PaywallBypass.setEnabled(enabled)
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(icon: "creditcard.fill", title: "Simulate purchase") {
                            inAppKit.simulatePurchase(DevotionProducts.annual)
                            Task { await UserPreferencesSync.shared.updatePremium(true) }
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(icon: "arrow.counterclockwise", title: "Clear purchases") {
                            inAppKit.clearPurchases()
                            paywallBypass = false
                        }
                    }
                    #endif

                    Text("Devotion Lock 1.0")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                }
            }
            .navigationDestination(for: ProfileDestination.self) { destination in
                switch destination {
                case .reminders: RemindersSettingsView()
                case .notifications: NotificationSettingsView()
                case .widgets: WidgetSettingsView()
                case .voice: VoiceSettingsView()
                case .appearance:
                    EmptyView() // Night sanctuary gradient — disabled for now
                case .shield: ShieldSettingsView()
                case .search: SearchView(showsHeader: false)
                case .passages: PassageSearchView()
                case .about: AboutView()
                case .journey: JourneyTimelineView(store: journeyStore)
                case .privacyPolicy: LegalDocumentView(document: .privacyPolicy)
                case .termsOfService: LegalDocumentView(document: .termsOfService)
                case .account: AccountSettingsView()
                }
            }
        }
        .confirmationDialog("Default mood", isPresented: $showMoodPicker, titleVisibility: .visible) {
            ForEach(MoodCatalog.options, id: \.label) { mood in
                Button(mood.label) {
                    intentionMood = mood.label
                    Task { await UserPreferencesSync.shared.pushPreferences(intentionMood: mood.label) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Used when you begin a morning devotion.")
        }
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }

    private var reminderSummary: String {
        if morningReminder { "Morning · 7:00 AM" } else { "Not scheduled" }
    }

    private var premiumStatusDetail: String {
        if PaywallAccess.hasPremium { "Active" } else { "Unlock AI Chaplain & more" }
    }

    @ViewBuilder
    private func settingsSection(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
        ABYSectionHeader(title: title)
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, 8)
        ABYSettingsGroup {
            rows()
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.bottom, 20)
    }
}

#Preview {
    ZStack {
        ABYBackground()
        ProfileView()
    }
}
