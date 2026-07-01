//
//  VoiceSettingsView.swift
//  test1
//

import SwiftUI

struct VoiceSettingsView: View {
    @AppStorage("selectedChaplainVoice") private var selectedVoiceID = "grace"

    var body: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                ABYDetailHeader(
                    title: "Chaplain",
                    subtitle: "Choose the voice that shapes your morning devotion."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 20)

                SacredOrbShell(size: 72, visualStyle: .calm)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)

                ABYSectionHeader(title: "Voice")
                    .padding(.horizontal, ABY.Spacing.screen)
                    .padding(.bottom, 8)

                VStack(spacing: 8) {
                    ForEach(ChaplainVoice.options) { voice in
                        ABYSelectionChip(
                            label: voice.name,
                            trailing: voice.personality,
                            isSelected: selectedVoiceID == voice.id
                        ) {
                            withAnimation(AppTheme.springSnappy) { selectedVoiceID = voice.id }
                            Task { await UserPreferencesSync.shared.pushPreferences(chaplainVoiceID: voice.id) }
                        }
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
            }
        }
        .abySettingsBackNavigation()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        VoiceSettingsView()
    }
}
