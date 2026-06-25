//
//  BottomNavigationBar.swift
//  test1
//

import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: AppTab
    let orbState: SacredOrbState
    var onOrbTap: () -> Void
    var onOrbLongPress: () -> Void = {}
    @Environment(\.sanctuaryPalette) private var palette
    @State private var orbHoldProgress: CGFloat = 0
    @State private var orbLongPressTriggered = false

    var body: some View {
        HStack(spacing: 10) {
            navGlassPill {
                navButton(tab: .home)
                navButton(tab: .conversations)
            }

            sacredOrbButton

            navGlassPill {
                navButton(tab: .insights)
                navButton(tab: .profile)
            }
        }
        .padding(.horizontal, ABY.Spacing.screen)
        .padding(.bottom, 6)
        .animation(AppTheme.springGentle, value: orbState)
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
                        Capsule()
                            .fill(palette.surface.opacity(0.94))
                            .overlay {
                                Capsule()
                                    .strokeBorder(palette.divider.opacity(0.4), lineWidth: 0.5)
                            }
                            .frame(width: 52, height: 36)
                            .transition(.scale.combined(with: .opacity))
                    }

                    ABYTabIcon(
                        systemName: isSelected ? tab.iconSelected : tab.icon,
                        isSelected: isSelected,
                        tint: palette.textPrimary
                    )
                    .scaleEffect(isSelected ? 1 : 0.94)
                    .animation(AppTheme.springSnappy, value: isSelected)
                }
                .frame(height: 44)

                Text(tab.label)
                    .font(isSelected ? ABY.Font.tabLabelSelected : ABY.Font.tabLabel)
                    .foregroundStyle(isSelected ? palette.textPrimary : palette.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var sacredOrbButton: some View {
        VStack(spacing: 4) {
            Button {
                guard !orbLongPressTriggered else {
                    orbLongPressTriggered = false
                    return
                }
                DevotionHaptics.light()
                onOrbTap()
            } label: {
                ZStack {
                    if orbHoldProgress > 0 {
                        Circle()
                            .trim(from: 0, to: orbHoldProgress)
                            .stroke(ABY.Color.pillTeal.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 58, height: 58)
                    }

                    SacredOrbShell(
                        size: 52,
                        visualStyle: orbState.visualStyle,
                        rhythmProgress: orbState.rhythmProgress,
                        showsNudge: orbState.showsMorningFirstNudge,
                        extraScale: orbHoldProgress > 0 ? 0.94 : 1
                    )
                }
                .offset(y: -2)
            }
            .buttonStyle(ScaleButtonStyle())
            .onLongPressGesture(minimumDuration: 0.45, pressing: { pressing in
                withAnimation(.easeOut(duration: 0.25)) {
                    orbHoldProgress = pressing ? 1 : 0
                }
                if pressing {
                    DevotionHaptics.soft()
                }
            }, perform: {
                orbLongPressTriggered = true
                DevotionHaptics.medium()
                onOrbLongPress()
            })
            .accessibilityLabel(orbState.accessibilityLabel)
            .accessibilityAction(named: "Quick capture") {
                onOrbLongPress()
            }

            if let microLabel = orbState.microLabel {
                Text(microLabel)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        orbState.showsMorningFirstNudge
                            ? ABY.Color.pillOrange
                            : palette.textSecondary
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(minWidth: 58)
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

#Preview("Begin") {
    ZStack(alignment: .bottom) {
        ABYFlatTabWashBackground()
        BottomNavigationBar(
            selectedTab: .constant(.home),
            orbState: SacredOrbState(
                shortLabel: "Begin",
                microLabel: "Begin",
                accessibilityLabel: "Begin devotion",
                visualStyle: .pulse,
                destination: .guidedDevotion,
                showsMorningFirstNudge: false,
                rhythmProgress: 0.25
            ),
            onOrbTap: {}
        )
    }
}

#Preview("Rest") {
    ZStack(alignment: .bottom) {
        ABYFlatTabWashBackground()
        BottomNavigationBar(
            selectedTab: .constant(.insights),
            orbState: SacredOrbState(
                shortLabel: "Continue",
                microLabel: "Rest well",
                accessibilityLabel: "Talk with Chaplain",
                visualStyle: .rest,
                destination: .chaplain(starter: nil, resumeConversationID: nil),
                showsMorningFirstNudge: false,
                rhythmProgress: 1
            ),
            onOrbTap: {}
        )
    }
}
