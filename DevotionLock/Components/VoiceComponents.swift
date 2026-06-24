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

// MARK: - Inline dictation (assisted journal + AI chat)

struct ABYInlineDictationCapture: View {
    @Environment(\.sanctuaryPalette) private var palette
    @Binding var text: String
    @Binding var isActive: Bool

    @State private var transcription = SpeechTranscriptionService()
    @State private var elapsed: TimeInterval = 0
    @State private var speechStarted = false
    @State private var tickTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 10) {
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
        .onAppear {
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
        let authorized = await transcription.requestAuthorization()
        guard authorized else {
            isActive = false
            return
        }
        speechStarted = true
        try? transcription.start()
    }

    private func cancelDictation() {
        _ = transcription.stop()
        isActive = false
    }

    private func finishDictation() {
        let spoken = transcription.stop().trimmingCharacters(in: .whitespacesAndNewlines)
        if !spoken.isEmpty {
            if text.isEmpty {
                text = spoken
            } else if !text.hasSuffix(" ") {
                text += " " + spoken
            } else {
                text += spoken
            }
        }
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
