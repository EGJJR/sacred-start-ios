//
//  AppLoadingView.swift
//  DevotionLock
//

import SwiftUI

enum SplashTiming {
    static let launchDuration: TimeInterval = 1.8
    static let refreshDuration: TimeInterval = 1.1
    static let refreshThreshold: TimeInterval = 20
}

struct AppLoadingView: View {
    @Environment(\.sanctuaryPalette) private var palette
    @AppStorage(SanctuaryGradientMode.storageKey) private var sanctuaryModeRaw = SanctuaryGradientMode.light.rawValue
    @Binding var progress: CGFloat
    var isBrief = false

    private let quote = LoadingQuoteCatalog.today

    @State private var quoteRevealed = false
    @State private var referenceRevealed = false
    @State private var fieldVisible = false

    private var isEvening: Bool {
        let mode = SanctuaryGradientMode(rawValue: sanctuaryModeRaw) ?? .light
        return SanctuaryGradientMode.resolved(mode) == .night
    }

    private var progressFill: Color {
        isEvening ? ABY.Color.starlight : Color(red: 0.42, green: 0.62, blue: 0.88)
    }

    var body: some View {
        ZStack {
            splashBackdrop
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                quoteBlock
                    .frame(maxWidth: 340)

                Spacer()

                footerChrome
                    .padding(.bottom, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            splashBackdrop
                .ignoresSafeArea()
        }
        .abyScreen()
        .onAppear { runRevealAnimation() }
    }

    @ViewBuilder
    private var splashBackdrop: some View {
        ZStack {
            SanctuarySplashBackground()

            if isEvening {
                eveningAccentGlow
            } else {
                SoftLightFieldView(intensity: fieldVisible ? 1 : 0.2)
                    .opacity(fieldVisible ? 1 : 0)
                    .blur(radius: fieldVisible ? 0 : 8)

                RadialGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color.white.opacity(0.08),
                        Color.clear,
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 220
                )
            }
        }
    }

    private var eveningAccentGlow: some View {
        RadialGradient(
            colors: [
                ABY.Color.orbTeal.opacity(0.12),
                ABY.Color.pillPurple.opacity(0.06),
                Color.clear,
            ],
            center: .center,
            startRadius: 40,
            endRadius: 200
        )
        .blur(radius: 24)
    }

    private var quoteBlock: some View {
        VStack(spacing: 18) {
            Text("“")
                .font(ABY.Font.editorialLargeTitle)
                .foregroundStyle(isEvening ? ABY.Color.starlight.opacity(0.7) : ABY.Color.pillPurple.opacity(0.35))
                .opacity(quoteRevealed ? 1 : 0)

            Text(quote.text)
                .font(ABY.Font.editorialTitle)
                .foregroundStyle(isEvening ? Color.white.opacity(0.96) : palette.textPrimary.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 28)
                .modifier(SplashTextReveal(isRevealed: quoteRevealed, isEvening: isEvening))

            Text("— \(quote.reference)")
                .font(ABY.Font.callout)
                .foregroundStyle(isEvening ? Color.white.opacity(0.72) : palette.textSecondary)
                .modifier(SplashTextReveal(isRevealed: referenceRevealed, isEvening: isEvening, blurRadius: 6))
        }
    }

    private var footerChrome: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(isEvening ? Color.white.opacity(0.14) : palette.track)
                .frame(width: 120, height: 3)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(progressFill)
                        .frame(width: max(8, 120 * progress))
                }

            Text("Sacred Start")
                .font(ABY.Font.captionMedium)
                .foregroundStyle(isEvening ? Color.white.opacity(0.55) : palette.textTertiary)
                .opacity(referenceRevealed ? 1 : 0)
        }
    }

    private func runRevealAnimation() {
        let fieldDelay = isBrief ? 0 : 0.05
        let quoteDelay = isBrief ? 0.08 : (isEvening ? 0.2 : 0.35)
        let referenceDelay = isBrief ? 0.25 : (isEvening ? 0.55 : 0.85)

        if !isEvening {
            withAnimation(.easeOut(duration: isBrief ? 0.5 : 0.9).delay(fieldDelay)) {
                fieldVisible = true
            }
        }
        withAnimation(.easeOut(duration: isBrief ? 0.7 : (isEvening ? 0.9 : 1.25)).delay(quoteDelay)) {
            quoteRevealed = true
        }
        withAnimation(.easeOut(duration: isBrief ? 0.5 : (isEvening ? 0.65 : 0.8)).delay(referenceDelay)) {
            referenceRevealed = true
        }
    }
}

/// Evening splash uses a soft fade; light mode keeps the blur reveal.
private struct SplashTextReveal: ViewModifier {
    let isRevealed: Bool
    var isEvening: Bool
    var blurRadius: CGFloat = 12

    func body(content: Content) -> some View {
        if isEvening {
            content
                .opacity(isRevealed ? 1 : 0)
                .offset(y: isRevealed ? 0 : 6)
        } else {
            content
                .blurReveal(isRevealed, blurRadius: blurRadius, scale: 1.02)
        }
    }
}

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSplash: Bool
    @State private var splashProgress: CGFloat = 0
    @State private var backgroundEnteredAt: Date?
    @State private var hasFinishedLaunchSplash: Bool
    @State private var isRefreshSplash = false

    init() {
        #if DEBUG
        let skipSplash = DesignTour.isActive
        _showSplash = State(initialValue: !skipSplash)
        _hasFinishedLaunchSplash = State(initialValue: skipSplash)
        #else
        _showSplash = State(initialValue: true)
        _hasFinishedLaunchSplash = State(initialValue: false)
        #endif
    }

    private let launchDuration = SplashTiming.launchDuration
    private let refreshDuration = SplashTiming.refreshDuration
    private let refreshThreshold = SplashTiming.refreshThreshold

    var body: some View {
        ZStack {
            ContentView()
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                AppLoadingView(progress: $splashProgress, isBrief: isRefreshSplash)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .zIndex(1)
            }
        }
        .animation(AppTheme.springGentle, value: showSplash)
        .task {
            NotificationManager.shared.configure()
            await runLaunchSplash()
            SharedDataSync.refreshSharedStores()
            SyncCoordinator.shared.scheduleFlush(force: true)
            AppShieldManager.shared.syncShieldState()
            PersonalInsightStore.shared.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background:
            backgroundEnteredAt = Date()
        case .active:
            guard hasFinishedLaunchSplash, let entered = backgroundEnteredAt else { return }
            let away = Date().timeIntervalSince(entered)
            backgroundEnteredAt = nil
            if away >= refreshThreshold {
                Task { await runRefreshSplash() }
            }
            SyncCoordinator.shared.scheduleFlush(force: false)
            AppShieldManager.shared.syncShieldState()
        default:
            break
        }
    }

    @MainActor
    private func runLaunchSplash() async {
        isRefreshSplash = false
        splashProgress = 0
        withAnimation(.easeInOut(duration: launchDuration)) {
            splashProgress = 1
        }
        try? await Task.sleep(for: .seconds(launchDuration + 0.15))
        withAnimation(AppTheme.springGentle) {
            showSplash = false
        }
        hasFinishedLaunchSplash = true
    }

    @MainActor
    private func runRefreshSplash() async {
        isRefreshSplash = true
        splashProgress = 0
        showSplash = true
        withAnimation(.easeInOut(duration: refreshDuration)) {
            splashProgress = 1
        }
        try? await Task.sleep(for: .seconds(refreshDuration + 0.1))
        withAnimation(AppTheme.springGentle) {
            showSplash = false
        }
        splashProgress = 0
        isRefreshSplash = false
    }
}

struct LoadingScreenPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sanctuaryPalette) private var palette

    @State private var progress: CGFloat = 0
    @State private var replayToken = UUID()

    var body: some View {
        ZStack {
            AppLoadingView(progress: $progress)
                .id(replayToken)

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(ABY.Font.callout)
                            .foregroundStyle(palette.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Button {
                        replay()
                    } label: {
                        Label("Replay", systemImage: "arrow.clockwise")
                            .font(ABY.Font.callout)
                            .foregroundStyle(palette.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, ABY.Spacing.screen)
                .padding(.top, 8)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            SanctuarySplashBackground()
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .abyScreen()
        .task(id: replayToken) {
            await runPreviewAnimation()
        }
    }

    private func replay() {
        progress = 0
        replayToken = UUID()
    }

    @MainActor
    private func runPreviewAnimation() async {
        progress = 0
        withAnimation(.easeInOut(duration: SplashTiming.launchDuration)) {
            progress = 1
        }
    }
}

#Preview("Launch") {
    AppLoadingView(progress: .constant(0.45))
        .abyScreen()
}

#Preview("Brief") {
    AppLoadingView(progress: .constant(0.7), isBrief: true)
        .abyScreen()
}

#Preview("Launch evening") {
    AppLoadingView(progress: .constant(0.45))
        .environment(\.sanctuaryPalette, .night)
        .preferredColorScheme(.dark)
}
