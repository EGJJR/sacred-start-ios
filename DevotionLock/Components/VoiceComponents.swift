//
//  VoiceComponents.swift
//  test1
//

import SwiftUI

enum VoiceOrbState {
    case idle
    case listening
    case speaking
}

// Mobbin: ChatGPT voice orb — fluid gradient circle, no waveform bars
struct VoiceOrb: View {
    var state: VoiceOrbState = .idle
    var size: CGFloat = 260

    @State private var breathe = false
    @State private var driftA = false
    @State private var driftB = false

    private var intensity: CGFloat {
        switch state {
        case .idle: 0.7
        case .listening: 1.0
        case .speaking: 0.85
        }
    }

    private var pulseScale: CGFloat {
        switch state {
        case .idle: breathe ? 1.02 : 0.98
        case .listening: breathe ? 1.08 : 1.0
        case .speaking: breathe ? 1.05 : 0.97
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ABY.Color.orbTeal.opacity(0.25 * intensity),
                            ABY.Color.orbSage.opacity(0.12 * intensity),
                            .clear,
                        ],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.65
                    )
                )
                .frame(width: size * 1.3, height: size * 1.3)
                .blur(radius: 30)
                .scaleEffect(pulseScale)

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            ABY.Color.orbTeal,
                            ABY.Color.orbSage,
                            ABY.Color.pillPurple,
                            ABY.Color.orbTeal.opacity(0.8),
                            ABY.Color.orbSage.opacity(0.9),
                            ABY.Color.orbTeal,
                        ],
                        center: driftA ? .topLeading : .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    ABY.Color.orbTeal.opacity(0.5),
                                    ABY.Color.pillPurple.opacity(0.8),
                                    DevotionTheme.sage.opacity(0.6),
                                ],
                                center: driftB ? .init(x: 0.35, y: 0.3) : .init(x: 0.65, y: 0.7),
                                startRadius: 0,
                                endRadius: size * 0.55
                            )
                        )
                        .blur(radius: 8)
                }
                .overlay {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(state == .listening ? 0.25 : 0.12),
                                    .clear,
                                ],
                                center: .init(x: 0.4, y: 0.35),
                                startRadius: 0,
                                endRadius: size * 0.35
                            )
                        )
                }
                .clipShape(Circle())
                .shadow(color: ABY.Color.orbTeal.opacity(0.25), radius: state == .listening ? 24 : 12)
                .scaleEffect(pulseScale)

            if state == .listening {
                Circle()
                    .stroke(ABY.Color.orbSage.opacity(breathe ? 0.4 : 0.15), lineWidth: 2)
                    .frame(width: size * 1.15, height: size * 1.15)
                    .scaleEffect(breathe ? 1.05 : 1.0)
            }
        }
        .onAppear {
            breathe = true
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                driftA = true
            }
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                driftB = true
            }
        }
        .animation(.easeInOut(duration: 0.4), value: state)
    }
}

// MARK: - ABY voice entry (Mobbin ref)

struct ABYVoiceWaveformBars: View {
    var active: Bool = true
    var barCount: Int = 38

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    let normalized = CGFloat(index) / CGFloat(max(barCount - 1, 1))
                    let envelope = sin(normalized * .pi)
                    let wave = abs(sin(t * 4.2 + Double(index) * 0.34))
                    let height: CGFloat = active
                        ? 8 + envelope * (6 + wave * 24)
                        : 6 + envelope * 5
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(ABY.Color.textSecondary.opacity(active ? 0.82 : 0.42))
                        .frame(width: 3, height: height)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
    }
}

struct ABYVoiceEntryTopBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    let sessionTime: String
    let onDismiss: () -> Void
    let onDone: () -> Void

    var body: some View {
        HStack {
            Button(action: onDismiss) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.down")
                        .font(ABY.Font.footnoteSemibold)
                    Text(sessionTime)
                        .font(ABY.Font.calloutMedium)
                }
                .foregroundStyle(palette.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Done", action: onDone)
                .font(ABY.Font.calloutMedium)
                .foregroundStyle(palette.textPrimary)
                .buttonStyle(.plain)
        }
    }
}

struct ABYVoiceCaptureCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let timerText: String
    var isListening: Bool
    let onCancel: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(timerText)
                .font(ABY.Font.captionMedium)
                .foregroundStyle(palette.textSecondary)

            HStack(spacing: 14) {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(ABY.Font.bodySemibold)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())

                ABYVoiceWaveformBars(active: isListening)

                Button(action: onSubmit) {
                    Image(systemName: "arrow.up")
                        .font(ABY.Font.headline)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(palette.isNight ? palette.surfaceElevated : Color(red: 0.97, green: 0.97, blue: 0.99))
        }
        .shadow(color: .black.opacity(palette.isNight ? 0.24 : 0.08), radius: 20, y: 8)
    }
}

// MARK: - Speech tidy presence (gentle polish loading)

enum ABYSpeechTidyPhase: Equatable {
    case arranging
    case smoothing
    case almostReady

    var statusCopy: String {
        switch self {
        case .arranging: "Arranging your words…"
        case .smoothing: "Smoothing the edges…"
        case .almostReady: "Almost ready…"
        }
    }
}

/// Compact weaving orb for speech tidy — shared sacred shell at mini size.
struct ABYSpeechTidyOrb: View {
    var size: CGFloat = 28

    var body: some View {
        SacredOrbShell(
            size: size,
            visualStyle: .weaving,
            showsNudge: false
        )
    }
}

struct ABYSpeechTidyPresence: View {
    @Environment(\.sanctuaryPalette) private var palette
    let phase: ABYSpeechTidyPhase

    var body: some View {
        HStack(spacing: 10) {
            ABYSpeechTidyOrb()
            Text(phase.statusCopy)
                .font(ABY.Font.caption)
                .foregroundStyle(palette.textSecondary)
                .contentTransition(.opacity)
                .animation(AppTheme.springGentle, value: phase)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(palette.isNight ? 0.2 : 0.06), radius: 8, y: 3)
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

private struct SpeechPolishBlurPulse: ViewModifier {
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let wave = sin(t * 2.2) * 0.5 + 0.5
            let radius = 1.5 + wave * 2.8
            content.blur(radius: radius)
        }
    }
}

private extension View {
    func speechPolishBlurPulse() -> some View {
        modifier(SpeechPolishBlurPulse())
    }
}

// MARK: - Inline dictation (assisted journal + AI chat)

/// Post-speech choice — keep raw words or tidy with blur reveal (Mobbin ABY journal psychology).
struct ABYSpeechPolishReview: View {
    @Environment(\.sanctuaryPalette) private var palette

    let rawTranscript: String
    let onKeepRaw: () -> Void
    let onTidyComplete: (String) -> Void
    let onCancel: () -> Void

    @State private var previewOrganized = ""
    @State private var isPolishing = false
    @State private var tidyPhase: ABYSpeechTidyPhase = .arranging
    @State private var showOrganizedPreview = false
    @State private var revealed = false

    private var displayText: String {
        showOrganizedPreview ? previewOrganized : rawTranscript
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your words are here")
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(palette.textPrimary)
                Text("Keep them exactly as spoken, or let us tidy spacing — never changing what you meant.")
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineSpacing(3)
            }

            ZStack(alignment: .topLeading) {
                Group {
                    if isPolishing {
                        Text(displayText)
                            .speechPolishBlurPulse()
                    } else {
                        Text(displayText)
                            .blurReveal(revealed, blurRadius: showOrganizedPreview ? 10 : 0, scale: 1.01)
                    }
                }
                .font(ABY.Font.body)
                .foregroundStyle(palette.textPrimary)
                .lineSpacing(7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(AppTheme.springGentle, value: showOrganizedPreview)
            }
            .padding(16)
            .frame(minHeight: 140, alignment: .topLeading)
            .background(Color.white.opacity(palette.isNight ? 0.12 : 0.98))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(palette.divider.opacity(0.5), lineWidth: 1)
            }
            .overlay {
                if isPolishing {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(palette.isNight ? 0.28 : 0.22)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .bottom) {
                if isPolishing {
                    ABYSpeechTidyPresence(phase: tidyPhase)
                }
            }
            .animation(AppTheme.springGentle, value: isPolishing)

            VStack(spacing: 10) {
                Button(action: beginTidyGently) {
                    HStack(spacing: 8) {
                        Image(systemName: "text.alignleft")
                        Text("Tidy gently")
                    }
                    .font(ABY.Font.calloutSemibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(palette.buttonFill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isPolishing)

                Button(action: onKeepRaw) {
                    Text("Keep my words")
                        .font(ABY.Font.calloutMedium)
                        .foregroundStyle(palette.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(palette.surfaceMuted.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isPolishing)

                Button("Discard", action: onCancel)
                    .font(ABY.Font.caption)
                    .foregroundStyle(palette.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 2)
        .onAppear {
            previewOrganized = TranscriptPolishService.tidyOnDevice(rawTranscript)
            withAnimation(AppTheme.springGentle.delay(0.05)) { revealed = true }
            DevotionHaptics.light()
        }
    }

    private func beginTidyGently() {
        DevotionHaptics.medium()
        isPolishing = true
        tidyPhase = .arranging
        revealed = false
        showOrganizedPreview = false

        let needsAI = rawTranscript.count >= 48 && AuthManager.shared.isAuthenticated
        let startedAt = Date()

        Task {
            let baseline = TranscriptPolishService.tidyOnDevice(rawTranscript)

            await MainActor.run {
                previewOrganized = baseline
                withAnimation(AppTheme.springGentle) {
                    showOrganizedPreview = true
                }
                DevotionHaptics.soft()
            }

            var polished = baseline

            if needsAI {
                await MainActor.run {
                    withAnimation(AppTheme.springGentle) { tidyPhase = .smoothing }
                    DevotionHaptics.soft()
                }

                polished = await TranscriptPolishService.tidyWithAIRefinement(
                    baseline: baseline,
                    raw: rawTranscript
                )
            }

            await MainActor.run {
                withAnimation(AppTheme.springGentle) { tidyPhase = .almostReady }
            }

            let elapsed = Date().timeIntervalSince(startedAt)
            if elapsed < 0.65 {
                try? await Task.sleep(nanoseconds: UInt64((0.65 - elapsed) * 1_000_000_000))
            }

            await MainActor.run {
                previewOrganized = polished
                isPolishing = false
                withAnimation(.easeOut(duration: 0.45)) {
                    revealed = true
                }
                DevotionHaptics.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                    onTidyComplete(polished)
                }
            }
        }
    }
}

struct ABYInlineDictationCapture: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var text: String
    @Binding var isActive: Bool
    var offersPolishChoice: Bool = false

    @State private var transcription = SpeechTranscriptionService()
    @State private var elapsed: TimeInterval = 0
    @State private var speechStarted = false
    @State private var tickTask: Task<Void, Never>?
    @State private var dictationBase = ""
    @State private var pendingSpoken: String?

    var body: some View {
        VStack(spacing: 10) {
            if let pendingSpoken {
                ABYSpeechPolishReview(
                    rawTranscript: pendingSpoken,
                    onKeepRaw: { applySpoken(pendingSpoken) },
                    onTidyComplete: { polished in applySpoken(polished) },
                    onCancel: cancelPolishReview
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                if !transcription.transcript.isEmpty {
                    Text(transcription.transcript)
                        .font(ABY.Font.callout)
                        .foregroundStyle(palette.textPrimary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .animation(AppTheme.springGentle, value: transcription.transcript)
                }

                ABYVoiceCaptureCard(
                    timerText: timerText,
                    isListening: transcription.isListening,
                    onCancel: cancelDictation,
                    onSubmit: finishDictation
                )
            }
        }
        .onAppear {
            dictationBase = text
            Task { await beginDictation() }
            startElapsedTimer()
        }
        .onDisappear {
            tickTask?.cancel()
            tickTask = nil
            _ = transcription.stop()
        }
    }

    private func startElapsedTimer() {
        tickTask?.cancel()
        tickTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, isActive, transcription.isListening else { continue }
                await MainActor.run { elapsed += 1 }
            }
        }
    }

    private var timerText: String {
        let seconds = Int(elapsed)
        if seconds < 60 { return String(format: "0:%02d", seconds) }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func beginDictation() async {
        guard !speechStarted else { return }
        DevotionHaptics.light()
        let authorized = await transcription.requestAuthorization()
        guard authorized else {
            isActive = false
            return
        }
        speechStarted = true
        try? transcription.start()
        DevotionHaptics.medium()
    }

    private func cancelDictation() {
        _ = transcription.stop()
        pendingSpoken = nil
        isActive = false
        DevotionHaptics.light()
    }

    private func finishDictation() {
        let spoken = transcription.stop().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !spoken.isEmpty else {
            isActive = false
            return
        }

        if offersPolishChoice, JournalTranscriptOrganizer.worthPolishChoice(spoken) {
            pendingSpoken = spoken
            DevotionHaptics.light()
            return
        }

        text = JournalTranscriptOrganizer.merge(base: dictationBase, spoken: spoken)
        isActive = false
        DevotionHaptics.success()
    }

    private func applySpoken(_ spoken: String) {
        text = JournalTranscriptOrganizer.merge(base: dictationBase, spoken: spoken)
        pendingSpoken = nil
        isActive = false
        DevotionHaptics.success()
    }

    private func cancelPolishReview() {
        pendingSpoken = nil
        isActive = false
        DevotionHaptics.light()
    }
}

struct VoiceWaveformIcon: View {
    var active: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { i in
                    let base: CGFloat = active ? 6 : 4
                    let height = base + abs(sin(t * 5 + Double(i) * 1.1)) * (active ? 12 : 4)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(active ? ABY.Color.orbSage : ABY.Color.textTertiary)
                        .frame(width: 3, height: height)
                }
            }
        }
        .frame(width: 24, height: 24)
    }
}

struct VoiceControlButton: View {
    let icon: String
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(AppFont.font(size: prominent ? 18 : 16, weight: .medium))
                .foregroundStyle(prominent ? Color.black : AppTheme.textPrimary)
                .frame(width: prominent ? 56 : 48, height: prominent ? 56 : 48)
                .background(prominent ? Color.white : Color.white.opacity(0.10))
                .clipShape(Circle())
                .overlay {
                    if !prominent {
                        Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    }
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ChaplainVoice: Identifiable, Hashable {
    let id: String
    let name: String
    let personality: String

    static let options: [ChaplainVoice] = [
        ChaplainVoice(id: "grace", name: "Grace", personality: "Calm & gentle"),
        ChaplainVoice(id: "hope", name: "Hope", personality: "Warm & pastoral"),
        ChaplainVoice(id: "still", name: "Still", personality: "Quiet & reflective"),
    ]
}
