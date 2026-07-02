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
    @Namespace private var tabSelection

    private let orbSize: CGFloat = 58
    private let barHeight: CGFloat = 64

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack(spacing: 12) {
                navGlassPill {
                    ForEach(AppTab.allCases) { tab in
                        navButton(tab: tab)
                    }
                }

                SacredOrbNavHoldButton(
                    orbState: orbState,
                    barHeight: barHeight,
                    orbSize: orbSize,
                    onTap: onOrbTap,
                    onHoldComplete: onOrbLongPress
                )
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .animation(AppTheme.springGentle, value: orbState)
    }

    private func navGlassPill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 6) {
            content()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(height: barHeight)
        .background {
            ABYGlassBarBackground()
        }
    }

    private func navButton(tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(AppTheme.springSnappy) { selectedTab = tab }
        } label: {
            HStack(spacing: isSelected ? 8 : 0) {
                ABYTabIcon(
                    systemName: isSelected ? tab.iconSelected : tab.icon,
                    isSelected: isSelected,
                    tint: palette.textPrimary,
                    size: 24
                )

                if isSelected {
                    Text(tab.label)
                        .font(ABY.Font.tabLabelSelected)
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .padding(.horizontal, isSelected ? 16 : 12)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    selectedTabHighlight
                        .matchedGeometryEffect(id: "tabHighlight", in: tabSelection)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Active-tab pill: neutral glass capsule with a restrained iridescent sheen — the
    /// one "jewel" moment allowed in the bar (see DESIGN-PHILOSOPHY). `matchedGeometryEffect`
    /// slides this whole stack between tabs so the sheen morphs with the selection.
    private var selectedTabHighlight: some View {
        ZStack {
            Capsule()
                .fill(palette.surface.opacity(0.96))

            IridescentBubble(intensity: palette.isNight ? 0.42 : 0.26)
                .clipShape(Capsule())

            Capsule()
                .strokeBorder(palette.divider.opacity(0.45), lineWidth: 0.5)
        }
    }
}

// MARK: - Orb hold interaction

private struct SacredOrbNavHoldButton: View {
    let orbState: SacredOrbState
    let barHeight: CGFloat
    let orbSize: CGFloat
    var onTap: () -> Void
    var onHoldComplete: () -> Void

    @State private var holdProgress: CGFloat = 0
    @State private var holdBloom: CGFloat = 1
    @State private var isPressing = false
    @State private var didCompleteHold = false
    @State private var pressBeganAt: Date?
    @State private var holdTask: Task<Void, Never>?

    private let holdDuration: TimeInterval = 0.52
    private let tapThreshold: TimeInterval = 0.28

    var body: some View {
        ZStack {
            if holdProgress > 0 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ABY.Color.orbTeal.opacity(0.32 * Double(holdProgress)),
                                ABY.Color.orbSage.opacity(0.12 * Double(holdProgress)),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: barHeight * 0.85
                        )
                    )
                    .frame(
                        width: barHeight + 28 * holdProgress,
                        height: barHeight + 28 * holdProgress
                    )
                    .blur(radius: 4)
            }

            Circle()
                .stroke(paletteTrack, lineWidth: 2.5)
                .frame(width: barHeight + 2, height: barHeight + 2)
                .opacity(holdProgress > 0 ? 1 : 0)

            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            ABY.Color.orbTeal,
                            ABY.Color.orbSage,
                            ABY.Color.pillPurple.opacity(0.9),
                            ABY.Color.orbTeal,
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: barHeight + 2, height: barHeight + 2)
                .opacity(holdProgress > 0 ? 1 : 0)

            SacredOrbShell(
                size: orbSize,
                visualStyle: isPressing ? .weaving : orbState.visualStyle,
                rhythmProgress: orbState.rhythmProgress,
                showsNudge: orbState.showsMorningFirstNudge,
                extraScale: holdBloom * (1 - 0.06 * holdProgress)
            )
        }
        .frame(width: barHeight, height: barHeight)
        .scaleEffect(holdBloom)
        .contentShape(Circle())
        .gesture(holdGesture)
        .accessibilityLabel(orbState.accessibilityLabel)
        .accessibilityHint("Press and hold for quick capture. \(orbState.microLabel ?? "")")
        .accessibilityAction(named: "Quick capture") {
            onHoldComplete()
        }
        .onDisappear {
            cancelHold(animated: false)
        }
    }

    private var paletteTrack: Color {
        Color.white.opacity(0.22)
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { _ in
                beginHoldIfNeeded()
            }
            .onEnded { _ in
                endHold()
            }
    }

    private func beginHoldIfNeeded() {
        guard !isPressing else { return }
        isPressing = true
        didCompleteHold = false
        pressBeganAt = Date()
        DevotionHaptics.soft()

        holdProgress = 0
        withAnimation(.linear(duration: holdDuration)) {
            holdProgress = 1
        }

        holdTask?.cancel()
        holdTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(holdDuration))
            guard !Task.isCancelled, isPressing else { return }

            didCompleteHold = true
            DevotionHaptics.medium()

            withAnimation(AppTheme.springSnappy) {
                holdBloom = 1.1
            }

            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled else { return }

            onHoldComplete()

            try? await Task.sleep(for: .milliseconds(160))
            guard !Task.isCancelled else { return }

            resetHoldVisuals()
            isPressing = false
            pressBeganAt = nil
        }
    }

    private func endHold() {
        let pressDuration = pressBeganAt.map { Date().timeIntervalSince($0) } ?? 0
        let shouldTap = !didCompleteHold && pressDuration < tapThreshold

        holdTask?.cancel()
        holdTask = nil
        isPressing = false
        pressBeganAt = nil

        resetHoldVisuals()

        if shouldTap {
            DevotionHaptics.light()
            onTap()
        }

        didCompleteHold = false
    }

    private func cancelHold(animated: Bool) {
        holdTask?.cancel()
        holdTask = nil
        isPressing = false
        pressBeganAt = nil
        didCompleteHold = false
        if animated {
            resetHoldVisuals()
        } else {
            holdProgress = 0
            holdBloom = 1
        }
    }

    private func resetHoldVisuals() {
        withAnimation(AppTheme.springSnappy) {
            holdProgress = 0
            holdBloom = 1
        }
    }
}

struct ABYTabIcon: View {
    let systemName: String
    var isSelected: Bool
    var tint: Color = ABY.Color.textPrimary
    var size: CGFloat = 21
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: isSelected ? .medium : .light))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(isSelected ? tint : palette.textTertiary)
            .frame(width: size + 4, height: size + 4)
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

#Preview("Journal selected") {
    ZStack(alignment: .bottom) {
        ABYFlatTabWashBackground()
        BottomNavigationBar(
            selectedTab: .constant(.conversations),
            orbState: SacredOrbState(
                shortLabel: "Capture",
                microLabel: nil,
                accessibilityLabel: "Quick capture",
                visualStyle: .calm,
                destination: .journalHub,
                showsMorningFirstNudge: false,
                rhythmProgress: 0.5
            ),
            onOrbTap: {}
        )
    }
}
