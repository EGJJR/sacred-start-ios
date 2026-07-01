//
//  SacredOrbQuickActionsSheet.swift
//  DevotionLock
//
//  Mobbin refs:
//  Pangea capsule fan-out — https://mobbin.com/screens/ad29ee8d-4b30-430b-9842-53d9e345bacd
//  Airwallex speed-dial labels — https://mobbin.com/screens/0713aaea-bea9-4810-8bdb-849772fd0246
//  Jobber FAB stack — https://mobbin.com/screens/85be30de-6c55-4b32-a446-5caff51d4595
//

import SwiftUI

enum SacredOrbQuickAction: String, Identifiable, CaseIterable {
    case morningDevotion
    case journalCapture
    case assistedWrite
    case voiceNote
    case eveningReflection
    case chaplain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morningDevotion: "Morning devotion"
        case .journalCapture: "Add to journal"
        case .assistedWrite: "Assisted write"
        case .voiceNote: "Voice note"
        case .eveningReflection: "Evening reflection"
        case .chaplain: "Talk with Chaplain"
        }
    }

    var subtitle: String {
        switch self {
        case .morningDevotion: "Guided scripture & gratitude"
        case .journalCapture: "Choose how to capture"
        case .assistedWrite: "Gentle writing prompts"
        case .voiceNote: "Speak, then transcribe"
        case .eveningReflection: "Close the day in stillness"
        case .chaplain: "Continue or begin anew"
        }
    }

    var icon: String {
        switch self {
        case .morningDevotion: "sun.horizon.fill"
        case .journalCapture: "square.and.pencil"
        case .assistedWrite: "text.quote"
        case .voiceNote: "waveform"
        case .eveningReflection: "moon.stars.fill"
        case .chaplain: "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .morningDevotion: ABY.Color.pillTeal
        case .journalCapture: ABY.Color.pillOrange
        case .assistedWrite: ABY.Color.pillPurple
        case .voiceNote: ABY.Color.pillPink
        case .eveningReflection: ABY.Color.pillPurple
        case .chaplain: ABY.Color.orbTeal
        }
    }
}

// MARK: - Overlay (pill fan from orb — Mobbin: Pangea / Airwallex / Jobber)

struct SacredOrbQuickActionsOverlay: View {
    @Environment(\.sanctuaryPalette) private var palette

    @Binding var isPresented: Bool
    var dismissSignal: Int = 0
    let actions: [SacredOrbQuickAction]
    var onSelect: (SacredOrbQuickAction) -> Void

    @State private var scrimPhase: CGFloat = 0
    @State private var menuPhase: CGFloat = 0
    @State private var isDismissing = false

    private let staggerStep: Double = 0.052
    private let navClearance: CGFloat = 92

    var body: some View {
        ZStack(alignment: .bottom) {
            scrim
                .opacity(Double(scrimPhase))
                .onTapGesture {
                    DevotionHaptics.soft()
                    dismissAnimated()
                }

            VStack(spacing: 10) {
                headerChip
                    .menuItemMotion(
                        phase: menuPhase,
                        index: 0,
                        total: actions.count + 1,
                        stagger: staggerStep,
                        reverseOrder: isDismissing
                    )

                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    SacredOrbQuickActionPill(action: action) {
                        DevotionHaptics.light()
                        dismissAnimated {
                            onSelect(action)
                        }
                    }
                    .menuItemMotion(
                        phase: menuPhase,
                        index: index + 1,
                        total: actions.count + 1,
                        stagger: staggerStep,
                        reverseOrder: isDismissing
                    )
                }
            }
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.bottom, navClearance)
            .frame(maxWidth: 400)
        }
        .accessibilityAddTraits(.isModal)
        .onAppear { animateIn() }
        .onChange(of: dismissSignal) { _, _ in
            guard isPresented, menuPhase > 0.5 else { return }
            dismissAnimated()
        }
        .onDisappear {
            scrimPhase = 0
            menuPhase = 0
            isDismissing = false
        }
    }

    private func animateIn() {
        isDismissing = false
        scrimPhase = 0
        menuPhase = 0

        withAnimation(.easeOut(duration: 0.22)) {
            scrimPhase = 1
        }

        withAnimation(AppTheme.springMenuReveal.delay(0.04)) {
            menuPhase = 1
        }
    }

    private func dismissAnimated(after: (() -> Void)? = nil) {
        isDismissing = true

        withAnimation(AppTheme.springMenuCollapse) {
            menuPhase = 0
        }

        withAnimation(.easeIn(duration: 0.2).delay(0.08)) {
            scrimPhase = 0
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            isPresented = false
            after?()
        }
    }

    private var scrim: some View {
        Color.black.opacity(palette.isNight ? 0.38 : 0.24)
            .ignoresSafeArea()
            .contentShape(Rectangle())
    }

    private var headerChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ABY.Color.meshSky, ABY.Color.meshPeriwinkle, ABY.Color.orbTeal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Sacred shortcuts")
                .font(ABY.Font.captionSemibold)
                .foregroundStyle(palette.textPrimary)

            Spacer(minLength: 0)

            Text("Hold orb anytime")
                .font(ABY.Font.captionMedium)
                .foregroundStyle(palette.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background { PillChromeBackground(cornerRadius: 14) }
    }
}

// MARK: - Floating action pill (Pangea / Airwallex row)

private struct SacredOrbQuickActionPill: View {
    @Environment(\.sanctuaryPalette) private var palette

    let action: SacredOrbQuickAction
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(action.tint.opacity(palette.isNight ? 0.22 : 0.14))

                    Image(systemName: action.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(action.tint)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(ABY.Font.calloutSemibold)
                        .foregroundStyle(palette.textPrimary)

                    Text(action.subtitle)
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.textTertiary.opacity(0.85))
            }
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
            .background { PillChromeBackground(cornerRadius: 20) }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(SacredOrbQuickActionPillStyle())
    }
}

private struct PillChromeBackground: View {
    @Environment(\.sanctuaryPalette) private var palette
    var cornerRadius: CGFloat

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        shape
            .fill(palette.cardFill)
            .overlay {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                palette.navBarStrokeTop.opacity(palette.isNight ? 0.55 : 0.9),
                                palette.navBarStrokeBottom.opacity(palette.isNight ? 0.25 : 0.35),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: .black.opacity(palette.isNight ? 0.42 : 0.10), radius: 18, y: 8)
            .shadow(color: ABY.Color.orbTeal.opacity(palette.isNight ? 0.06 : 0.04), radius: 12, y: 4)
    }
}

// MARK: - Orb-origin stagger motion

private struct MenuItemMotionModifier: ViewModifier {
    let phase: CGFloat
    let index: Int
    let total: Int
    let stagger: Double
    let reverseOrder: Bool

    private var motionIndex: Int {
        reverseOrder ? max(0, total - 1 - index) : index
    }

    private var localPhase: CGFloat {
        let step = CGFloat(stagger) * 3.2
        let start = CGFloat(motionIndex) * step
        let end = start + 0.42
        guard end > start else { return phase }
        return min(1, max(0, (phase - start) / (end - start)))
    }

    func body(content: Content) -> some View {
        let eased = cubicEase(localPhase)
        let yLift: CGFloat = 34 - eased * 34
        let scale = 0.84 + eased * 0.16
        let blur = (1 - eased) * 7

        content
            .opacity(Double(eased))
            .offset(y: yLift)
            .scaleEffect(scale, anchor: .bottom)
            .blur(radius: blur)
    }

    private func cubicEase(_ t: CGFloat) -> CGFloat {
        let clamped = min(1, max(0, t))
        return 1 - pow(1 - clamped, 3)
    }
}

private extension View {
    func menuItemMotion(
        phase: CGFloat,
        index: Int,
        total: Int,
        stagger: Double,
        reverseOrder: Bool
    ) -> some View {
        modifier(
            MenuItemMotionModifier(
                phase: phase,
                index: index,
                total: total,
                stagger: stagger,
                reverseOrder: reverseOrder
            )
        )
    }
}

// MARK: - Shared card (design tour / previews)

struct SacredOrbQuickActionsCard: View {
    @Environment(\.sanctuaryPalette) private var palette

    let actions: [SacredOrbQuickAction]
    var isVisible: Bool = true
    var onSelect: (SacredOrbQuickAction) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(actions) { action in
                SacredOrbQuickActionPill(action: action) {
                    onSelect(action)
                }
            }
        }
    }
}

// MARK: - Sheet (design tour / previews)

struct SacredOrbQuickActionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let actions: [SacredOrbQuickAction]
    var onSelect: (SacredOrbQuickAction) -> Void

    var body: some View {
        SacredOrbQuickActionsCard(actions: actions, isVisible: true, onSelect: onSelect)
            .padding(.horizontal, ABY.Spacing.screen)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .accessibilityAction(named: "Dismiss") { dismiss() }
    }
}

private struct SacredOrbQuickActionPillStyle: ButtonStyle {
    @Environment(\.sanctuaryPalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                if configuration.isPressed {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(palette.surfaceMuted.opacity(palette.isNight ? 0.35 : 0.45))
                }
            }
            .scaleEffect(configuration.isPressed ? 0.978 : 1)
            .animation(AppTheme.springSnappy, value: configuration.isPressed)
    }
}

#if DEBUG
#Preview("Overlay light") {
    @Previewable @State var presented = true
    ZStack(alignment: .bottom) {
        ABYFlatTabWashBackground()
        SacredOrbQuickActionsOverlay(
            isPresented: $presented,
            actions: SacredOrbQuickAction.allCases,
            onSelect: { _ in }
        )
    }
    .abyScreen()
}

#Preview("Overlay evening") {
    @Previewable @State var presented = true
    ZStack(alignment: .bottom) {
        ABYEveningReflectionBackground()
        SacredOrbQuickActionsOverlay(
            isPresented: $presented,
            actions: SacredOrbQuickAction.allCases,
            onSelect: { _ in }
        )
    }
    .environment(\.sanctuaryPalette, .night)
    .preferredColorScheme(.dark)
}

#Preview("Sheet") {
    SacredOrbQuickActionsSheet(
        actions: SacredOrbQuickAction.allCases,
        onSelect: { _ in }
    )
}
#endif
