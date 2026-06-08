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
                .font(.system(size: prominent ? 18 : 16, weight: .medium))
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
