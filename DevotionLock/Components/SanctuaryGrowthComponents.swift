//
//  SanctuaryGrowthComponents.swift
//  DevotionLock
//
//  Mobbin: Forest garden, QUITTR life tree, Headway trophy hall, stoic. badges.
//

import SwiftUI

// MARK: - Growth artifact (Forest / QUITTR)

struct SanctuaryGrowthArtifact: View {
    let stage: SanctuaryGrowthStage
    var size: CGFloat = 72

    private var bowlColor: Color { Color(red: 0.72, green: 0.58, blue: 0.42) }
    private var soilColor: Color { Color(red: 0.45, green: 0.32, blue: 0.22) }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [stageGlow.opacity(0.35), Color.clear],
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.65
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)

            Ellipse()
                .fill(bowlColor)
                .frame(width: size * 0.85, height: size * 0.28)
                .offset(y: size * 0.28)

            Ellipse()
                .fill(soilColor)
                .frame(width: size * 0.7, height: size * 0.18)
                .offset(y: size * 0.2)

            plantSymbol
                .font(.system(size: size * plantScale, weight: .semibold))
                .foregroundStyle(plantGradient)
                .offset(y: size * plantYOffset)
        }
        .frame(width: size, height: size)
    }

    private var plantSymbol: Image {
        switch stage {
        case .seed: Image(systemName: "leaf")
        case .sprout: Image(systemName: "leaf.fill")
        case .bloom: Image(systemName: "camera.macro")
        case .sanctuary: Image(systemName: "tree.fill")
        }
    }

    private var plantScale: CGFloat {
        switch stage {
        case .seed: 0.32
        case .sprout: 0.38
        case .bloom: 0.42
        case .sanctuary: 0.48
        }
    }

    private var plantYOffset: CGFloat {
        switch stage {
        case .seed: -0.02
        case .sprout: -0.06
        case .bloom: -0.1
        case .sanctuary: -0.14
        }
    }

    private var stageGlow: Color {
        switch stage {
        case .seed: ABY.Color.meshSage
        case .sprout: ABY.Color.pillTeal
        case .bloom: ABY.Color.pillPurple
        case .sanctuary: StreakPalette.orange
        }
    }

    private var plantGradient: LinearGradient {
        switch stage {
        case .seed, .sprout:
            LinearGradient(
                colors: [ABY.Color.meshSage, ABY.Color.pillTeal],
                startPoint: .top,
                endPoint: .bottom
            )
        case .bloom:
            LinearGradient(
                colors: [ABY.Color.pillPurple, ABY.Color.pillTeal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sanctuary:
            LinearGradient(
                colors: [ABY.Color.meshSage, Color(red: 0.2, green: 0.55, blue: 0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Badge row (stoic. / Headway trophy hall)

struct SanctuaryGrowthBadgeRow: View {
    @Environment(\.sanctuaryPalette) private var palette
    let currentStage: SanctuaryGrowthStage

    private let tiers: [(days: Int, stage: SanctuaryGrowthStage, label: String)] = [
        (7, .sprout, "Anchor"),
        (30, .bloom, "Steady"),
        (100, .sanctuary, "Keeper"),
    ]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(tiers, id: \.days) { tier in
                badgeSlot(days: tier.days, stage: tier.stage, label: tier.label)
            }
        }
    }

    private func badgeSlot(days: Int, stage: SanctuaryGrowthStage, label: String) -> some View {
        let unlocked = stageRank(currentStage) >= stageRank(stage)

        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(unlocked ? palette.background : palette.surface)
                    .frame(width: 52, height: 52)
                    .overlay {
                        if unlocked {
                            SanctuaryGrowthArtifact(stage: stage, size: 40)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(palette.textTertiary)
                        }
                    }
                    .overlay {
                        Circle()
                            .stroke(unlocked ? ABY.Color.pillTeal.opacity(0.4) : palette.divider, lineWidth: 1.5)
                    }
                    .blur(radius: unlocked ? 0 : 0.5)
                    .opacity(unlocked ? 1 : 0.55)

                if unlocked {
                    Text("\(days)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(ABY.Color.pillTeal)
                        .clipShape(Capsule())
                        .offset(y: -28)
                }
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(unlocked ? palette.textPrimary : palette.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func stageRank(_ stage: SanctuaryGrowthStage) -> Int {
        SanctuaryGrowthStage.allCases.firstIndex(of: stage) ?? 0
    }
}

// MARK: - Identity card (QUITTR glass card)

struct SanctuaryIdentityCard: View {
    @Environment(\.sanctuaryPalette) private var palette
    let identity: StreakIdentity

    var body: some View {
        HStack(spacing: 16) {
            SanctuaryGrowthArtifact(stage: identity.stage, size: 64)

            VStack(alignment: .leading, spacing: 8) {
                Text(identity.statusName)
                    .font(ABY.Font.headline)
                    .foregroundStyle(palette.textPrimary)

                HStack(spacing: 4) {
                    Text("\(identity.streakDays)")
                        .font(ABY.Font.title2)
                        .foregroundStyle(StreakPalette.orange)
                    Text(identity.streakDays == 1 ? "day in the Word" : "days in the Word")
                        .font(ABY.Font.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                if let next = identity.nextMilestone {
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(palette.divider)
                                    .frame(height: 4)
                                Capsule()
                                    .fill(ABY.Color.pillTeal)
                                    .frame(width: geo.size.width * identity.progressToNext, height: 4)
                            }
                        }
                        .frame(height: 4)

                        Text("\(next - identity.streakDays) day\(next - identity.streakDays == 1 ? "" : "s") to next milestone")
                            .font(ABY.Font.caption)
                            .foregroundStyle(palette.textTertiary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ABY.Radius.cardLarge, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
    }
}

// MARK: - Milestone progress bar (Streak screen)

struct SanctuaryMilestoneProgressBar: View {
    @Environment(\.sanctuaryPalette) private var palette
    let identity: StreakIdentity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Next milestone")
                    .font(ABY.Font.captionMedium)
                    .foregroundStyle(palette.textSecondary)
                Spacer()
                if let next = identity.nextMilestone {
                    Text("\(identity.streakDays)/\(next) days")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(ABY.Color.pillTeal)
                } else {
                    Text("Sanctuary Keeper")
                        .font(ABY.Font.captionMedium)
                        .foregroundStyle(ABY.Color.pillTeal)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.divider)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [ABY.Color.pillTeal, ABY.Color.meshSage],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * identity.progressToNext)
                }
            }
            .frame(height: 6)
        }
    }
}
