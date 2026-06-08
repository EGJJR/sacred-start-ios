//
//  BottomNavigationBar.swift
//  test1
//

import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: AppTab
    var onRecordTap: () -> Void
    @Environment(\.sanctuaryPalette) private var palette
    @State private var orbPulse = false

    var body: some View {
        HStack(spacing: 10) {
            navGlassPill {
                navButton(tab: .home)
                navButton(tab: .conversations)
            }

            recordButton

            navGlassPill {
                navButton(tab: .insights)
                navButton(tab: .profile)
            }
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.bottom, 6)
    }

    private func navGlassPill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 2) {
            content()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background {
            ABYGlassBarBackground()
        }
    }

    private func navButton(tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(AppTheme.springSnappy) { selectedTab = tab }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(tab.activeTint.opacity(0.16))
                            .frame(width: 44, height: 44)
                            .transition(.scale.combined(with: .opacity))
                    }

                    ABYTabIcon(
                        systemName: isSelected ? tab.iconSelected : tab.icon,
                        isSelected: isSelected,
                        tint: tab.activeTint
                    )
                    .scaleEffect(isSelected ? 1 : 0.92)
                    .animation(AppTheme.springSnappy, value: isSelected)
                }
                .frame(height: 44)

                Text(tab.label)
                    .font(isSelected ? ABY.Font.tabLabelSelected : ABY.Font.tabLabel)
                    .foregroundStyle(isSelected ? tab.activeTint : palette.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var recordButton: some View {
        Button(action: onRecordTap) {
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                ABY.Color.orbTeal,
                                ABY.Color.orbSage,
                                ABY.Color.pillPurple.opacity(0.9),
                                ABY.Color.meshSky.opacity(0.85),
                                ABY.Color.orbTeal,
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.28),
                                        Color.clear,
                                    ],
                                    center: .init(x: 0.35, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 28
                                )
                            )
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.75),
                                        Color.white.opacity(0.25),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: ABY.Color.orbTeal.opacity(0.32), radius: 14, y: 5)
                    .scaleEffect(orbPulse ? 1.04 : 0.96)

                DotPatternIcon(dotColor: .white.opacity(0.95))
                    .frame(width: 22, height: 22)
            }
            .offset(y: -2)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Begin devotion")
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                orbPulse = true
            }
        }
    }
}

struct ABYTabIcon: View {
    let systemName: String
    var isSelected: Bool
    var tint: Color = ABY.Color.textPrimary
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 21, weight: isSelected ? .medium : .light))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(isSelected ? tint : palette.textTertiary)
            .frame(width: 24, height: 24)
            .contentTransition(.symbolEffect(.replace))
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        ABYCleanGradientBackground()
        BottomNavigationBar(selectedTab: .constant(.insights), onRecordTap: {})
    }
}
