//
//  BottomNavigationBar.swift
//  test1
//

import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: AppTab
    let orbState: SacredOrbState
    var isQuickMenuPresented: Bool = false
    var onOrbTap: () -> Void
    var onOrbLongPress: () -> Void = {}
    @Environment(\.sanctuaryPalette) private var palette
    @State private var tabFrames: [AppTab: CGRect] = [:]

    private let tabIconSize: CGFloat = 24
    private let orbSize: CGFloat = 26
    private let barHeight: CGFloat = 56

    private var leadingTabs: [AppTab] { [.home, .conversations] }
    private var trailingTabs: [AppTab] { [.insights, .profile] }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            navGlassPill {
                navTabRow()
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .animation(AppTheme.springMenu, value: isQuickMenuPresented)
        .animation(AppTheme.springGentle, value: orbState)
    }

    private func navGlassPill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                // One glass surface for the pill; selection chip is a fill overlay (Conor §4.2 — no glass-on-glass).
                GlassEffectContainer(spacing: 16) {
                    content()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(height: barHeight)
                .background(Color.clear, in: Capsule())
                .abyLiquidGlassCapsule(tint: liquidGlassBarTint)
                .contentShape(Capsule())
            } else {
                HStack(spacing: 6) {
                    content()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(height: barHeight)
                .sanctuaryNavBarGlass()
                .contentShape(Capsule())
            }
        }
    }

    @available(iOS 26.0, *)
    private var liquidGlassBarTint: Color {
        // Strategic tint — higher opacity on night twilight so icons stay legible.
        palette.isNight ? Color.white.opacity(0.38) : Color.white.opacity(0.82)
    }

    private var navIconSelectedTint: Color {
        palette.isNight ? .white : palette.textPrimary
    }

    private var navIconUnselectedTint: Color {
        palette.isNight ? Color.white.opacity(0.68) : palette.textSecondary
    }

    private func navButton(tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            ABYTabIcon(
                systemName: isSelected ? tab.iconSelected : tab.icon,
                isSelected: isSelected,
                tint: navIconSelectedTint,
                unselectedTint: navIconUnselectedTint,
                size: tabIconSize
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: NavTabFrameKey.self,
                        value: [tab: proxy.frame(in: .named("navBarTabs"))]
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func navTabRow() -> some View {
        ZStack(alignment: .topLeading) {
            if let frame = tabFrames[selectedTab] {
                let insetX: CGFloat = 4
                let insetY: CGFloat = 2
                NavTabSlidingGlassHighlight()
                    .frame(
                        width: max(0, frame.width - insetX * 2),
                        height: max(0, frame.height - insetY * 2)
                    )
                    .offset(x: frame.minX + insetX, y: frame.minY + insetY)
                    .allowsHitTesting(false)
            }

            HStack(spacing: 0) {
                ForEach(leadingTabs) { tab in
                    navButton(tab: tab)
                }

                SacredOrbNavHoldButton(
                    orbState: orbState,
                    barHeight: barHeight,
                    orbSize: orbSize,
                    isQuickMenuPresented: isQuickMenuPresented,
                    onTap: onOrbTap,
                    onHoldComplete: onOrbLongPress
                )
                .frame(maxWidth: .infinity)

                ForEach(trailingTabs) { tab in
                    navButton(tab: tab)
                }
            }
        }
        .coordinateSpace(name: "navBarTabs")
        .onPreferenceChange(NavTabFrameKey.self) { tabFrames = $0 }
        .animation(AppTheme.springSnappy, value: selectedTab)
    }
}

// MARK: - Tab frame tracking (sliding glass chip)

private struct NavTabFrameKey: PreferenceKey {
    static var defaultValue: [AppTab: CGRect] { [:] }

    static func reduce(value: inout [AppTab: CGRect], nextValue: () -> [AppTab: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

// MARK: - Sliding glass selection chip (inside nav pill)

private struct NavTabSlidingGlassHighlight: View {
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        if #available(iOS 26.0, *) {
            // Vibrancy fill on glass — not a second glass layer (Conor §4.2).
            Capsule()
                .fill(liquidGlassChipFill)
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .background {
                    Capsule()
                        .fill(palette.surface.opacity(palette.isNight ? 0.18 : 0.72))
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    palette.navBarStrokeTop.opacity(palette.isNight ? 0.55 : 0.9),
                                    palette.navBarStrokeBottom.opacity(0.35),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
        }
    }

    @available(iOS 26.0, *)
    private var liquidGlassChipFill: Color {
        palette.isNight ? Color.white.opacity(0.42) : Color.white.opacity(0.95)
    }
}

// MARK: - Orb hold interaction

private struct SacredOrbNavHoldButton: View {
    @Environment(\.sanctuaryPalette) private var palette

    let orbState: SacredOrbState
    let barHeight: CGFloat
    let orbSize: CGFloat
    var isQuickMenuPresented: Bool = false
    var onTap: () -> Void
    var onHoldComplete: () -> Void

    @State private var holdProgress: CGFloat = 0
    @State private var holdBloom: CGFloat = 1
    @State private var isPressing = false
    @State private var didCompleteHold = false
    @State private var pressBeganAt: Date?
    @State private var holdTask: Task<Void, Never>?

    private let holdDuration: TimeInterval = 0.48
    private let tapThreshold: TimeInterval = 0.26

    var body: some View {
        ZStack {
            if holdProgress > 0, !isQuickMenuPresented {
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        AngularGradient(
                            colors: holdRingColors,
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: orbSize + 8, height: orbSize + 8)
            }

            RadiantCaptureOrb(
                size: orbSize,
                rhythmProgress: 0,
                showsNudge: orbState.showsMorningFirstNudge && !isQuickMenuPresented,
                isMenuExpanded: isQuickMenuPresented,
                isPressing: isPressing,
                embeddedInBar: true,
                extraScale: menuScale * holdBloom
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        .scaleEffect(holdBloom)
        .contentShape(Rectangle())
        .gesture(isQuickMenuPresented ? nil : holdGesture)
        .onTapGesture {
            if isQuickMenuPresented {
                DevotionHaptics.soft()
                onTap()
            }
        }
        .accessibilityLabel(isQuickMenuPresented ? "Close sacred shortcuts" : orbState.accessibilityLabel)
        .accessibilityHint(
            isQuickMenuPresented
                ? "Closes the shortcuts sheet"
                : "Press and hold for sacred shortcuts. \(orbState.microLabel ?? "")"
        )
        .accessibilityAction(named: "Sacred shortcuts") {
            onHoldComplete()
        }
        .onDisappear {
            cancelHold(animated: false)
        }
    }

    private var menuScale: CGFloat {
        isQuickMenuPresented ? 0.96 : 1
    }

    private var holdRingColors: [Color] {
        [
            Color(red: 0.08, green: 0.76, blue: 0.94),
            Color(red: 0.10, green: 0.44, blue: 0.96),
            Color(red: 0.44, green: 0.32, blue: 0.92),
            Color(red: 0.76, green: 0.26, blue: 0.82),
            Color(red: 0.08, green: 0.76, blue: 0.94),
        ]
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
        withAnimation(.spring(response: holdDuration * 0.95, dampingFraction: 0.9)) {
            holdProgress = 1
        }

        holdTask?.cancel()
        holdTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(holdDuration))
            guard !Task.isCancelled, isPressing else { return }

            didCompleteHold = true
            DevotionHaptics.medium()

            withAnimation(AppTheme.springMenu) {
                holdBloom = 1.12
            }

            try? await Task.sleep(for: .milliseconds(70))
            guard !Task.isCancelled else { return }

            onHoldComplete()

            try? await Task.sleep(for: .milliseconds(140))
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
        withAnimation(AppTheme.springMenu) {
            holdProgress = 0
            holdBloom = 1
        }
    }
}

struct ABYTabIcon: View {
    let systemName: String
    var isSelected: Bool
    var tint: Color = ABY.Color.textPrimary
    var unselectedTint: Color?
    var size: CGFloat = 21
    @Environment(\.sanctuaryPalette) private var palette

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: isSelected ? .semibold : .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(isSelected ? tint : (unselectedTint ?? palette.textSecondary))
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
