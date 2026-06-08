//
//  AboutView.swift
//  test1
//

import SwiftUI

struct AboutView: View {
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        ABYScreenContainer {
            VStack(alignment: .leading, spacing: 0) {
                ABYDetailHeader(
                    title: "About",
                    subtitle: "Devotion Lock helps you begin each day with intention — before the world rushes in."
                )
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 24)

                VStack(spacing: 16) {
                    ShepherdLogoView(size: 100)
                    Text("Devotion Lock")
                        .font(ABY.Font.title2)
                        .foregroundStyle(palette.textPrimary)
                    Text("Version 1.0")
                        .font(ABY.Font.footnote)
                        .foregroundStyle(palette.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 28)

                ABYSettingsGroup {
                    NavigationLink(value: ProfileDestination.termsOfService) {
                        aboutRow(title: "Terms of Service")
                    }
                    .buttonStyle(.plain)
                    ABYSettingsDivider()
                    NavigationLink(value: ProfileDestination.privacyPolicy) {
                        aboutRow(title: "Privacy Policy")
                    }
                    .buttonStyle(.plain)
                    ABYSettingsDivider()
                    Link(destination: URL(string: "mailto:support@devotionlock.app")!) {
                        aboutRow(title: "Send feedback", showsExternal: true)
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar { ABYBackToolbar() }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutRow(title: String, showsExternal: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
            Spacer()
            Image(systemName: showsExternal ? "arrow.up.right" : "chevron.right")
                .font(ABY.Font.captionMedium)
                .foregroundStyle(palette.textTertiary)
        }
        .padding(.horizontal, ABY.Spacing.card)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        AboutView()
            .navigationDestination(for: ProfileDestination.self) { destination in
                switch destination {
                case .privacyPolicy: LegalDocumentView(document: .privacyPolicy)
                case .termsOfService: LegalDocumentView(document: .termsOfService)
                default: EmptyView()
                }
            }
    }
}
