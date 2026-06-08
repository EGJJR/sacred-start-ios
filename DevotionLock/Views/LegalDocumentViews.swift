//
//  LegalDocumentViews.swift
//  DevotionLock
//

import SwiftUI

enum LegalDocument: String, Hashable, CaseIterable {
    case privacyPolicy
    case termsOfService

    var title: String {
        switch self {
        case .privacyPolicy: "Privacy Policy"
        case .termsOfService: "Terms of Service"
        }
    }

    var subtitle: String {
        switch self {
        case .privacyPolicy:
            "How Devotion Lock collects, uses, and protects your information."
        case .termsOfService:
            "The rules and guidelines for using Devotion Lock."
        }
    }

    var lastUpdated: String { "June 6, 2026" }

    var sections: [LegalSection] {
        switch self {
        case .privacyPolicy: Self.privacySections
        case .termsOfService: Self.termsSections
        }
    }

    private static let privacySections: [LegalSection] = [
        LegalSection(
            title: "Overview",
            body: """
            Devotion Lock (“we,” “us,” or “our”) is a devotional journaling app that helps you begin each day with intention. This Privacy Policy explains what information we collect, how we use it, and the choices you have.

            By using Devotion Lock, you agree to the collection and use of information as described here.
            """
        ),
        LegalSection(
            title: "Information We Collect",
            body: """
            Account information: When you create an account, we collect your email address and username through our authentication provider (Supabase).

            Journal & devotion content: Entries, moods, prayer notes, and conversations you create in the app may be stored on your device and synced to our servers when you are signed in.

            AI Chaplain interactions: Messages you send to the Chaplain feature are processed to generate responses. We send relevant context (such as recent journal themes and streak data) to our AI service provider to personalize replies.

            On-device insights: Mood patterns and keyword themes are analyzed locally on your device. These insights are not uploaded unless you explicitly use a feature that sends them as context to the Chaplain.

            App shield selections: If you enable app blocking, your selected apps are stored using Apple’s Family Controls framework. We do not receive the names of your apps—only privacy-preserving tokens managed by iOS.

            Purchase information: Subscription status is handled by Apple through StoreKit. We do not receive your payment card details.

            Usage & diagnostics: We may collect crash logs or basic usage data to improve stability and performance.
            """
        ),
        LegalSection(
            title: "How We Use Information",
            body: """
            We use your information to:

            • Provide and sync your journal, streaks, prayer circles, and account
            • Power AI-assisted features such as the Chaplain and weekly insights
            • Send reminders and notifications you opt into
            • Enforce app shield settings you configure
            • Process subscriptions and restore purchases
            • Improve the app and fix bugs

            We do not sell your personal information.
            """
        ),
        LegalSection(
            title: "Third-Party Services",
            body: """
            Devotion Lock relies on trusted service providers, including:

            • Supabase — authentication, database, and cloud sync
            • Apple — sign-in, subscriptions, notifications, Screen Time APIs, and device storage
            • AI providers — to generate Chaplain responses and insights through our secure backend

            These providers process data only as needed to deliver their services and are bound by their own privacy policies.
            """
        ),
        LegalSection(
            title: "Data Retention & Deletion",
            body: """
            We retain your account and synced content while your account is active. You may delete journal entries within the app.

            To delete your account and associated cloud data, contact us at support@devotionlock.app or use account deletion if available in Settings. Some data may remain in backups for a limited period before being purged.

            Content stored only on your device can be removed by deleting the app.
            """
        ),
        LegalSection(
            title: "Your Choices",
            body: """
            • Notifications: Manage in Settings or iOS System Settings
            • App shield: Enable or disable at any time in Settings
            • AI features: Require an account and network connection; you choose what you share in journal entries and chat
            • Sign out: Clears your local session; synced data remains until account deletion
            """
        ),
        LegalSection(
            title: "Children’s Privacy",
            body: """
            Devotion Lock is not directed to children under 13. We do not knowingly collect personal information from children. If you believe a child has provided us information, contact us and we will delete it.
            """
        ),
        LegalSection(
            title: "Security",
            body: """
            We use industry-standard measures including encrypted connections (HTTPS), authenticated access, and platform security features from Apple and Supabase. No method of transmission or storage is 100% secure.
            """
        ),
        LegalSection(
            title: "Changes & Contact",
            body: """
            We may update this Privacy Policy from time to time. Continued use of the app after changes means you accept the updated policy.

            Questions? Email support@devotionlock.app
            """
        ),
    ]

    private static let termsSections: [LegalSection] = [
        LegalSection(
            title: "Agreement",
            body: """
            These Terms of Service (“Terms”) govern your use of the Devotion Lock mobile application and related services. By creating an account or using the app, you agree to these Terms.

            If you do not agree, do not use Devotion Lock.
            """
        ),
        LegalSection(
            title: "Eligibility",
            body: """
            You must be at least 13 years old (or the minimum age required in your country) to use Devotion Lock. You are responsible for maintaining the confidentiality of your account credentials.
            """
        ),
        LegalSection(
            title: "The Service",
            body: """
            Devotion Lock provides devotional journaling, streak tracking, prayer circles, optional app shielding, widgets, reminders, and AI-assisted spiritual guidance through the Chaplain feature.

            Features may change, be added, or removed over time. Some features require a network connection or a Premium subscription.
            """
        ),
        LegalSection(
            title: "Subscriptions & Billing",
            body: """
            Premium features are billed through Apple’s In-App Purchase system. Payment is charged to your Apple ID account. Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period.

            Manage or cancel subscriptions in iOS Settings → Apple ID → Subscriptions. Refunds are handled by Apple according to their policies.

            Free trials, if offered, convert to a paid subscription unless canceled before the trial ends.
            """
        ),
        LegalSection(
            title: "Acceptable Use",
            body: """
            You agree not to:

            • Use the app for unlawful, harmful, or abusive purposes
            • Harass others in prayer circles or shared spaces
            • Attempt to reverse engineer, scrape, or overload our systems
            • Misrepresent your identity or impersonate others
            • Use AI features to generate content that violates our community standards

            We may suspend or terminate access for violations of these Terms.
            """
        ),
        LegalSection(
            title: "AI Chaplain Disclaimer",
            body: """
            The Chaplain and AI insight features offer spiritual encouragement and reflection—they are not a substitute for professional counseling, medical advice, pastoral care, or emergency services.

            If you are in crisis, contact local emergency services or a qualified professional. AI responses may be inaccurate or incomplete; use discernment and verify important guidance with trusted sources.
            """
        ),
        LegalSection(
            title: "App Shield & Screen Time",
            body: """
            App shielding uses Apple’s Screen Time APIs. You are responsible for selecting apps to block and for complying with Apple’s terms. Blocking behavior depends on iOS system permissions and may not be available on all devices or account types.

            We are not liable for interruptions to device functionality caused by shield settings you enable.
            """
        ),
        LegalSection(
            title: "Your Content",
            body: """
            You retain ownership of content you create in Devotion Lock. You grant us a limited license to host, process, and display your content solely to operate the service—including syncing across your devices and powering features you request.

            You are responsible for the content you post, including in prayer circles. Do not post content that infringes others’ rights or violates applicable law.
            """
        ),
        LegalSection(
            title: "Intellectual Property",
            body: """
            Devotion Lock, including its design, branding, and software, is owned by us or our licensors. These Terms do not grant you rights to our trademarks or code except as needed to use the app.
            """
        ),
        LegalSection(
            title: "Disclaimer of Warranties",
            body: """
            Devotion Lock is provided “as is” and “as available” without warranties of any kind, express or implied, including fitness for a particular purpose or uninterrupted availability.
            """
        ),
        LegalSection(
            title: "Limitation of Liability",
            body: """
            To the fullest extent permitted by law, Devotion Lock and its operators are not liable for indirect, incidental, special, or consequential damages arising from your use of the app.

            Our total liability for any claim related to the service is limited to the amount you paid us in the twelve months before the claim, or USD $50, whichever is greater.
            """
        ),
        LegalSection(
            title: "Termination",
            body: """
            You may stop using the app at any time. We may suspend or terminate your access if you violate these Terms or if we discontinue the service.

            Sections that by nature should survive termination (including disclaimers, limitations of liability, and dispute terms) will remain in effect.
            """
        ),
        LegalSection(
            title: "Governing Law & Contact",
            body: """
            These Terms are governed by the laws of the United States and the state in which we operate, without regard to conflict-of-law principles.

            Questions about these Terms: support@devotionlock.app
            """
        ),
    ]
}

struct LegalSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct LegalDocumentView: View {
    @Environment(\.sanctuaryPalette) private var palette
    let document: LegalDocument

    var body: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                ABYDetailHeader(title: document.title, subtitle: document.subtitle)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                Text("Last updated \(document.lastUpdated)")
                    .font(ABY.Font.footnote)
                    .foregroundStyle(palette.textTertiary)
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 20)

                VStack(spacing: 16) {
                    ForEach(document.sections) { section in
                        legalSectionCard(section)
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar { ABYBackToolbar() }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func legalSectionCard(_ section: LegalSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
                .font(ABY.Font.headline)
                .foregroundStyle(palette.textPrimary)
            Text(section.body)
                .font(ABY.Font.callout)
                .foregroundStyle(palette.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ABY.Spacing.card)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

#Preview("Privacy") {
    NavigationStack {
        LegalDocumentView(document: .privacyPolicy)
    }
}

#Preview("Terms") {
    NavigationStack {
        LegalDocumentView(document: .termsOfService)
    }
}
