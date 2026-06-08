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
    @Binding var progress: CGFloat
    var isBrief = false

    private let quote = LoadingQuoteCatalog.today

    @State private var quoteRevealed = false
    @State private var referenceRevealed = false
    @State private var fieldVisible = false

    var body: some View {
        ZStack {
            ZStack {
                SanctuarySplashBackground()

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
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 18) {
                    Text("“")
                        .font(.system(size: 34, weight: .light, design: .serif))
                        .foregroundStyle(ABY.Color.pillPurple.opacity(0.35))
                        .opacity(quoteRevealed ? 1 : 0)

                    Text(quote.text)
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .foregroundStyle(ABY.Color.textPrimary.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 28)
                        .blur(radius: quoteRevealed ? 0 : 16)
                        .opacity(quoteRevealed ? 1 : 0)
                        .scaleEffect(quoteRevealed ? 1 : 1.03)

                    Text("— \(quote.reference)")
                        .font(ABY.Font.callout)
                        .foregroundStyle(ABY.Color.textSecondary)
                        .blur(radius: referenceRevealed ? 0 : 10)
                        .opacity(referenceRevealed ? 1 : 0)
                }
                .frame(maxWidth: 340)

                Spacer()

                VStack(spacing: 14) {
                    Capsule()
                        .fill(ABY.Color.track)
                        .frame(width: 120, height: 3)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [ABY.Color.pillTeal, ABY.Color.pillPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, 120 * progress))
                        }

                    Text("Devotion Lock")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(ABY.Color.textTertiary)
                        .opacity(referenceRevealed ? 0.8 : 0)
                }
                .padding(.bottom, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            SanctuarySplashBackground()
                .ignoresSafeArea()
        }
        .abyScreen()
        .onAppear { runRevealAnimation() }
    }

    private func runRevealAnimation() {
        let fieldDelay = isBrief ? 0 : 0.05
        let quoteDelay = isBrief ? 0.08 : 0.35
        let referenceDelay = isBrief ? 0.25 : 0.85

        withAnimation(.easeOut(duration: isBrief ? 0.5 : 0.9).delay(fieldDelay)) {
            fieldVisible = true
        }
        withAnimation(.easeOut(duration: isBrief ? 0.7 : 1.25).delay(quoteDelay)) {
            quoteRevealed = true
        }
        withAnimation(.easeOut(duration: isBrief ? 0.5 : 0.8).delay(referenceDelay)) {
            referenceRevealed = true
        }
    }
}

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSplash = true
    @State private var splashProgress: CGFloat = 0
    @State private var backgroundEnteredAt: Date?
    @State private var hasFinishedLaunchSplash = false
    @State private var isRefreshSplash = false

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
            await SyncCoordinator.shared.flushAll(force: true)
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
            Task { await SyncCoordinator.shared.onForeground() }
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
                            .foregroundStyle(ABY.Color.textPrimary)
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
                            .foregroundStyle(ABY.Color.textPrimary)
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
}

#Preview("Brief") {
    AppLoadingView(progress: .constant(0.7), isBrief: true)
}
