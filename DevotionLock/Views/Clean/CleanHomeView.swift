//
//  CleanHomeView.swift
//  DevotionLock
//
//  Clean-app home experiment — Solace-style shell remapped to DevotionLock.
//

import SwiftUI

struct CleanHomeView: View {
    @Environment(\.openGuidedJournal) private var openGuidedJournal
    @Environment(\.openStreakScreen) private var openStreakScreen
    @Environment(\.openPrayerWall) private var openPrayerWall
    @Environment(\.openChaplainChat) private var openChaplainChat
    @Environment(\.presentDevotionPaywall) private var presentPaywall
    @Environment(\.authManager) private var auth
    @Environment(\.streakManager) private var streakManager

    @State private var statusLine: String = ""
    @State private var tipLine: String = ""
    @State private var showScripture = false
    @State private var appeared = false

    private var firstName: String {
        let name = auth.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "friend" }
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    private var greeting: String {
        "\(ChaplainContextBuilder.greetingSalutation()), \(firstName)"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, CleanDesign.Spacing.screen)
                    .padding(.top, 8)
                    .padding(.bottom, CleanDesign.Spacing.section)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                actionGrid
                    .padding(.horizontal, CleanDesign.Spacing.screen)
                    .padding(.bottom, CleanDesign.Spacing.section)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                tipCard
                    .padding(.horizontal, CleanDesign.Spacing.screen)
                    .padding(.bottom, 100)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
            }
        }
        .background(CleanDesign.Color.background.ignoresSafeArea())
        .sheet(isPresented: $showScripture) {
            PassageSearchView(
                initialTab: FeatureFlags.bibleReaderEnabled ? .books : .discover
            )
        }
        .onAppear {
            refreshCopy()
            withAnimation(.easeOut(duration: 0.45).delay(0.05)) { appeared = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(CleanDesign.Font.display)
                    .foregroundStyle(CleanDesign.Color.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(statusLine)
                    .font(CleanDesign.Font.body)
                    .foregroundStyle(CleanDesign.Color.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            if streakManager.currentStreak > 0 {
                Button(action: openStreakScreen) {
                    HStack(spacing: 4) {
                        SolarDuotone.Glyph(
                            icon: .flame,
                            size: 16,
                            primary: CleanDesign.Color.flame,
                            secondary: CleanDesign.Color.flameSoft
                        )
                        Text("\(streakManager.currentStreak)")
                            .font(CleanDesign.Font.bodyMedium)
                            .foregroundStyle(CleanDesign.Color.flame)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(CleanDesign.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: CleanDesign.radius, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Streak \(streakManager.currentStreak) days")
            }
        }
    }

    // MARK: - 2×2 grid

    private var actionGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: CleanDesign.Spacing.grid),
                GridItem(.flexible(), spacing: CleanDesign.Spacing.grid),
            ],
            spacing: CleanDesign.Spacing.grid
        ) {
            CleanActionCard(
                icon: .chaplain,
                title: "Talk to Chaplain",
                subtitle: "Whatever's on your mind",
                action: {
                    requirePremium {
                        openChaplainChat(nil, [])
                    }
                }
            )
            CleanActionCard(
                icon: .journal,
                title: "Daily devotion",
                subtitle: streakManager.isCompletedToday ? "Completed today" : "A prompt is waiting",
                action: openGuidedJournal
            )
            CleanActionCard(
                icon: .scripture,
                title: "Scripture",
                subtitle: "Open the Word",
                action: { showScripture = true }
            )
            CleanActionCard(
                icon: .prayer,
                title: "Prayer wall",
                subtitle: "Leave a note of prayer",
                action: {
                    requirePremium { openPrayerWall(nil) }
                }
            )
        }
    }

    // MARK: - Tip

    private var tipCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: CleanDesign.radius, style: .continuous)
                    .fill(CleanDesign.Color.accentSoft)
                    .frame(width: 48, height: 48)
                SolarDuotone.Glyph(
                    icon: .cloud,
                    size: 26,
                    primary: CleanDesign.Color.accent,
                    secondary: CleanDesign.Color.accentMuted
                )
            }

            Text(tipLine)
                .font(CleanDesign.Font.title)
                .foregroundStyle(CleanDesign.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(CleanDesign.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.radius, style: .continuous))
    }

    // MARK: - Copy

    private func refreshCopy() {
        statusLine = makeStatusLine()
        tipLine = makeTipLine()
    }

    private func makeStatusLine() -> String {
        let snapshot = PersonalInsightStore.shared.snapshot
        let profile = MorningProfile.shared
        if let brief = AmbientEmpathy.storyBrief(
            snapshot: snapshot,
            profile: profile,
            streakDays: streakManager.currentStreak
        ), let narrative = brief.narrative, !narrative.isEmpty {
            return narrative
        }
        if streakManager.isCompletedToday {
            return "Shield holding today."
        }
        if streakManager.currentStreak > 0 {
            return "Day \(streakManager.currentStreak) of showing up."
        }
        return "A quiet place to begin."
    }

    private func makeTipLine() -> String {
        let focus = DailyFocus.today
        let ref = focus.reference.trimmingCharacters(in: .whitespacesAndNewlines)
        if !ref.isEmpty {
            return "Today's focus: \(ref)."
        }
        return "Take one quiet moment with Scripture before noon."
    }

    private func requirePremium(_ action: @escaping () -> Void) {
        PaywallAccess.guardPremium(presentPaywall: presentPaywall, action: action)
    }
}

// MARK: - Action card

private struct CleanActionCard: View {
    let icon: SolarDuotone.Icon
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: CleanDesign.radius, style: .continuous)
                        .fill(CleanDesign.Color.accentSoft)
                        .frame(width: 44, height: 44)
                    SolarDuotone.Glyph(
                        icon: icon,
                        size: 24,
                        primary: CleanDesign.Color.accent,
                        secondary: CleanDesign.Color.accentMuted
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(CleanDesign.Font.title)
                        .foregroundStyle(CleanDesign.Color.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(CleanDesign.Font.body)
                        .foregroundStyle(CleanDesign.Color.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
            .background(CleanDesign.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: CleanDesign.radius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CleanHomeView()
        .environment(\.streakManager, .shared)
}
