//
//  ProfileView.swift
//  test1
//
//  Mobbin ABY settings: https://mobbin.com/screens/121ba456-3b84-44f9-87b0-71f03ecfde6f
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

private enum AccountFlowSheet: Identifiable {
    case signOut
    case deleteWarning
    case deleteFinal

    var id: String {
        switch self {
        case .signOut: "sign-out"
        case .deleteWarning: "delete-warning"
        case .deleteFinal: "delete-final"
        }
    }
}

struct ProfileView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @Environment(\.authManager) private var auth
    @Environment(\.openStreakScreen) private var openStreakScreen
    @Environment(\.openMorningWrapped) private var openMorningWrapped
    @Environment(\.streakManager) private var streakManager

    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"
    @AppStorage("intentionMood") private var intentionMood = "Peaceful"
    @AppStorage("morningReminderEnabled") private var morningReminder = true
    @AppStorage("shieldEnabled") private var shieldEnabled = true
    #if DEBUG
    @AppStorage(PaywallBypass.storageKey) private var paywallBypass = false
    @AppStorage(DesignTour.storageKey) private var designTourEnabled = false
    #endif

    @State private var path = NavigationPath()
    @State private var appeared = false
    @State private var showMoodPicker = false
    private let inAppKit = InAppKit.shared

    @State private var accountSheet: AccountFlowSheet?
    @State private var isSigningOut = false
    @State private var isDeleting = false
    @State private var accountError: String?

    private var voiceName: String {
        ChaplainVoice.options.first { $0.id == selectedVoiceID }?.name ?? "Grace"
    }

    var body: some View {
        NavigationStack(path: $path) {
            ABYScreenContainer {
                VStack(alignment: .leading, spacing: 0) {
                    settingsTitle
                        .padding(.horizontal, ABY.Spacing.screen)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                        .opacity(appeared ? 1 : 0)

                    ABYSettingsProfileCard(
                        name: auth.displayName,
                        email: auth.email,
                        avatarURL: auth.avatarURL,
                        streakDays: streakManager.currentStreak,
                        onEdit: { path.append(ProfileDestination.account) }
                    )
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 16)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                    ABYSettingsPremiumBanner(isActive: PaywallAccess.hasPremium) {
                        presentPaywall()
                    }
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)

                    Button(action: openStreakScreen) {
                        VStack(alignment: .leading, spacing: 12) {
                            ABYSectionHeader(title: "Your rhythm")
                            SanctuaryIdentityCard(identity: streakManager.streakIdentity)
                            SanctuaryGrowthBadgeRow(currentStage: streakManager.streakIdentity.stage)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)

                    settingsSection("Account") {
                        ABYSettingsRow(
                            icon: "person.crop.circle",
                            title: "Profile",
                            detail: "Photo, username & email",
                            value: nil
                        ) {
                            path.append(ProfileDestination.account)
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
                        ABYSettingsRow(
                            icon: "ellipsis.bubble.fill",
                            title: "Chaplain personality",
                            detail: "Tone for text chat replies",
                            value: voiceName
                        ) {
                            path.append(ProfileDestination.voice)
                        }
                        ABYSettingsDivider()
                        ABYSettingsRow(
                            icon: "leaf.fill",
                            title: "Default mood",
                            detail: "Morning check-in",
                            value: intentionMood
                        ) {
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
                            icon: "book.closed.fill",
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

                    dangerZone

                    #if DEBUG
                    settingsSection("Developer") {
                        ABYSettingsToggleRow(
                            icon: "map.fill",
                            title: "Design tour",
                            detail: "Jump to any screen for QA",
                            isOn: $designTourEnabled
                        )
                        ABYSettingsDivider()
                        ABYSettingsToggleRow(
                            icon: "hammer.fill",
                            title: "Bypass paywall",
                            detail: "Unlock premium without purchasing",
                            isOn: $paywallBypass
                        )
                        .onChange(of: paywallBypass) { _, enabled in
                            PaywallBypass.setEnabled(enabled)
                        }
                    }
                    #endif

                    if let accountError {
                        Text(accountError)
                            .font(ABY.Font.footnote)
                            .foregroundStyle(.red.opacity(0.85))
                            .padding(.horizontal, ABY.Spacing.screen)
                            .padding(.bottom, 8)
                    }

                    ABYSettingsFooter()
                }
            }
            .navigationDestination(for: ProfileDestination.self) { destination in
                switch destination {
                case .reminders: RemindersSettingsView()
                case .notifications: NotificationSettingsView()
                case .widgets: WidgetSettingsView()
                case .voice: VoiceSettingsView()
                case .appearance: EmptyView()
                case .shield: ShieldSettingsView()
                case .search: SearchView(showsHeader: false)
                case .passages: PassageSearchView()
                case .about: AboutView()
                case .journey: JourneyTimelineView(store: JourneyTimelineStore.shared)
                case .privacyPolicy: LegalDocumentView(document: .privacyPolicy)
                case .termsOfService: LegalDocumentView(document: .termsOfService)
                case .account: AccountSettingsView()
                }
            }
        }
        .background(Color.clear)
        .toolbarBackground(.hidden, for: .navigationBar)
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
        .sheet(item: $accountSheet) { sheet in
            switch sheet {
            case .signOut:
                ABYConfirmationSheet(
                    title: "Sign out?",
                    message: "You can sign back in anytime with your email and password. Your journal stays on this device until you sign in again.",
                    confirmTitle: "Sign out",
                    isDestructive: true,
                    isLoading: isSigningOut,
                    onConfirm: { Task { await signOut() } },
                    onCancel: { accountSheet = nil }
                )
            case .deleteWarning:
                ABYConfirmationSheet(
                    title: "Delete your account?",
                    message: "This permanently removes your account, synced journal, and profile photo. This cannot be undone.",
                    confirmTitle: "Continue",
                    isDestructive: true,
                    onConfirm: { accountSheet = .deleteFinal },
                    onCancel: { accountSheet = nil }
                )
            case .deleteFinal:
                ABYConfirmationSheet(
                    title: "Are you absolutely sure?",
                    message: "All of your data will be permanently deleted from our servers.",
                    confirmTitle: "Delete account",
                    isDestructive: true,
                    isLoading: isDeleting,
                    onConfirm: { Task { await deleteAccount() } },
                    onCancel: { accountSheet = nil }
                )
            }
        }
        .onAppear {
            withAnimation(AppTheme.springGentle) { appeared = true }
        }
    }

    private var settingsTitle: some View {
        ABYScreenHeader(title: "Settings", subtitle: "Preferences & account")
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 8) {
            ABYSettingsDangerHeader(title: "Danger zone")
                .padding(.horizontal, ABY.Spacing.screen)

            ABYSettingsGroup {
                ABYSettingsDangerRow(
                    title: "Sign out",
                    subtitle: "End your session on this device. Your local journal entries remain until you sign in again.",
                    isLoading: isSigningOut
                ) {
                    accountSheet = .signOut
                }

                ABYSettingsDivider()

                ABYSettingsDangerRow(
                    title: "Delete account",
                    subtitle: "Permanently remove your account, cloud sync, and profile. This action cannot be reversed.",
                    isLoading: isDeleting
                ) {
                    accountSheet = .deleteWarning
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
        }
        .padding(.bottom, 20)
        .opacity(appeared ? 1 : 0)
    }

    private var reminderSummary: String {
        if morningReminder { "Morning · 7:00 AM" } else { "Not scheduled" }
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
        .opacity(appeared ? 1 : 0)
    }

    private func signOut() async {
        isSigningOut = true
        accountError = nil
        defer { isSigningOut = false }
        await auth.signOut()
        accountSheet = nil
    }

    private func deleteAccount() async {
        isDeleting = true
        accountError = nil
        defer { isDeleting = false }
        do {
            try await auth.deleteAccount()
            accountSheet = nil
        } catch {
            accountError = error.localizedDescription
            accountSheet = nil
        }
    }
}

#Preview {
    ZStack {
        ABYBackground()
        ProfileView()
    }
}
