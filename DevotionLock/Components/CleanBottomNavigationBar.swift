//
//  CleanBottomNavigationBar.swift
//  DevotionLock
//
//  Floating pill for the Clean experiment: Home · Journal · Chat · Profile.
//

import SwiftUI

struct CleanBottomNavigationBar: View {
    @Binding var selectedTab: AppTab

    private let tabs: [AppTab] = [.home, .conversations, .insights, .profile]

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: 2) {
                ForEach(tabs) { tab in
                    cleanTabButton(tab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(CleanDesign.Color.surface)
            .clipShape(Capsule(style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
            .frame(maxWidth: 380)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func cleanTabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(CleanDesign.Color.accentSoft)
                            .frame(width: 40, height: 40)
                    }
                    SolarDuotone.Glyph(
                        icon: icon(for: tab),
                        size: 24,
                        primary: isSelected ? CleanDesign.Color.accent : CleanDesign.Color.textTertiary,
                        secondary: isSelected ? CleanDesign.Color.accentMuted : CleanDesign.Color.textTertiary.opacity(0.45)
                    )
                }
                .frame(height: 40)

                Text(label(for: tab))
                    .font(CleanDesign.Font.bodyMedium)
                    .foregroundStyle(isSelected ? CleanDesign.Color.textPrimary : CleanDesign.Color.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label(for: tab))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func icon(for tab: AppTab) -> SolarDuotone.Icon {
        switch tab {
        case .home: .home
        case .conversations: .journal
        case .insights: .chat
        case .profile: .profile
        }
    }

    private func label(for tab: AppTab) -> String {
        switch tab {
        case .home: "Home"
        case .conversations: "Journal"
        case .insights: "Chat"
        case .profile: "Profile"
        }
    }
}
