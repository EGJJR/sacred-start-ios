//
//  PrayerBreathEngine.swift
//  DevotionLock
//
//  Single TimelineView-driven breath clock for guided prayer flows.
//

import SwiftUI

struct PrayerBreathProfile: Equatable {
    var inhale: TimeInterval
    var holdAfterInhale: TimeInterval
    var exhale: TimeInterval
    var holdAfterExhale: TimeInterval

    static let threshold = PrayerBreathProfile(
        inhale: 2.2, holdAfterInhale: 0.8, exhale: 2.4, holdAfterExhale: 0.45
    )
    static let liturgy = PrayerBreathProfile(
        inhale: 2.0, holdAfterInhale: 0.55, exhale: 2.6, holdAfterExhale: 0.35
    )
    static let calming = PrayerBreathProfile(
        inhale: 3.0, holdAfterInhale: 1.0, exhale: 4.0, holdAfterExhale: 0.5
    )

    var cycleDuration: TimeInterval {
        inhale + holdAfterInhale + exhale + holdAfterExhale
    }
}

enum PrayerBreathPhase: Equatable {
    case inhale
    case holdIn
    case exhale
    case holdOut
    case still
}

struct PrayerBreathSnapshot: Equatable {
    let phase: PrayerBreathPhase
    let phaseProgress: CGFloat
    let cycleProgress: CGFloat
    let cycleIndex: Int
    let ringScale: CGFloat
    let atmosphereScale: CGFloat
    let orbitDegrees: Double
    let phaseLabel: String

    var legacyPhase: PrayerBreathRing.BreathPhase {
        switch phase {
        case .inhale: .inhale
        case .holdIn: .hold
        case .exhale: .exhale
        case .holdOut, .still: .still
        }
    }

    /// Fires once per completed exhale (start of hold-out).
    var exhaleBoundaryKey: String { "\(cycleIndex)-exhale" }
}

enum PrayerBreathClock {
    static func snapshot(
        at date: Date,
        anchor: Date,
        profile: PrayerBreathProfile,
        reduceMotion: Bool
    ) -> PrayerBreathSnapshot {
        if reduceMotion {
            return PrayerBreathSnapshot(
                phase: .still,
                phaseProgress: 0,
                cycleProgress: 0,
                cycleIndex: 0,
                ringScale: 1,
                atmosphereScale: 1,
                orbitDegrees: 0,
                phaseLabel: "Stay"
            )
        }

        let elapsed = max(0, date.timeIntervalSince(anchor))
        let duration = max(profile.cycleDuration, 0.01)
        let cycleIndex = Int(elapsed / duration)
        let t = elapsed.truncatingRemainder(dividingBy: duration)

        let segments: [(PrayerBreathPhase, TimeInterval, String)] = [
            (.inhale, profile.inhale, "Inhale"),
            (.holdIn, profile.holdAfterInhale, "Hold"),
            (.exhale, profile.exhale, "Exhale"),
            (.holdOut, profile.holdAfterExhale, "Stay"),
        ]

        var cursor: TimeInterval = 0
        for (phase, segmentDuration, label) in segments where segmentDuration > 0 {
            if t < cursor + segmentDuration {
                let progress = CGFloat((t - cursor) / segmentDuration)
                let scale = ringScale(phase: phase, progress: progress)
                return PrayerBreathSnapshot(
                    phase: phase,
                    phaseProgress: progress,
                    cycleProgress: CGFloat(t / duration),
                    cycleIndex: cycleIndex,
                    ringScale: scale,
                    atmosphereScale: scale * 0.97,
                    orbitDegrees: orbitDegrees(elapsed: elapsed, phase: phase, segmentStart: cursor, segmentDuration: segmentDuration),
                    phaseLabel: label
                )
            }
            cursor += segmentDuration
        }

        return PrayerBreathSnapshot(
            phase: .still,
            phaseProgress: 0,
            cycleProgress: 1,
            cycleIndex: cycleIndex,
            ringScale: 0.92,
            atmosphereScale: 0.9,
            orbitDegrees: 0,
            phaseLabel: "Stay"
        )
    }

    private static func ringScale(phase: PrayerBreathPhase, progress: CGFloat) -> CGFloat {
        switch phase {
        case .inhale: 0.92 + 0.16 * progress
        case .holdIn: 1.08
        case .exhale: 1.08 - 0.16 * progress
        case .holdOut, .still: 0.92
        }
    }

    private static func orbitDegrees(
        elapsed: TimeInterval,
        phase: PrayerBreathPhase,
        segmentStart: TimeInterval,
        segmentDuration: TimeInterval
    ) -> Double {
        let base = elapsed * 42
        let phaseBoost: Double = switch phase {
        case .exhale: 18
        case .inhale: 10
        default: 0
        }
        let local = Double((elapsed - segmentStart) / max(segmentDuration, 0.01)) * phaseBoost
        return (base + local).truncatingRemainder(dividingBy: 360)
    }
}

/// Drives child views from one breath clock; calls back when an exhale completes.
struct PrayerBreathTimeline<Content: View>: View {
    let profile: PrayerBreathProfile
    let anchor: Date
    var onExhaleEnded: (() -> Void)?
    @ViewBuilder var content: (PrayerBreathSnapshot) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var firedExhaleCycles = Set<Int>()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let snapshot = PrayerBreathClock.snapshot(
                at: timeline.date,
                anchor: anchor,
                profile: profile,
                reduceMotion: reduceMotion
            )
            content(snapshot)
                .onChange(of: snapshot.cycleIndex) { _, _ in
                    detectExhaleCompletion(snapshot)
                }
                .onChange(of: snapshot.phase) { _, _ in
                    detectExhaleCompletion(snapshot)
                }
                .onAppear {
                    detectExhaleCompletion(snapshot)
                }
        }
    }

    private func detectExhaleCompletion(_ snapshot: PrayerBreathSnapshot) {
        guard snapshot.phase == .holdOut, snapshot.phaseProgress < 0.12 else { return }
        guard !firedExhaleCycles.contains(snapshot.cycleIndex) else { return }
        firedExhaleCycles.insert(snapshot.cycleIndex)
        onExhaleEnded?()
    }
}
