//
//  JournalLiveActivityWidget.swift
//  DevotionLockWidgets
//

import ActivityKit
import SwiftUI
import WidgetKit

struct JournalLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: JournalActivityAttributes.self) { context in
            LiveActivityLockBanner(
                sessionTitle: context.attributes.sessionTitle,
                stepTitle: context.state.stepTitle,
                stepIndex: context.state.stepIndex,
                totalSteps: context.state.totalSteps,
                elapsedSeconds: context.state.elapsedSeconds,
                session: context.state.session,
                breathsRemaining: context.state.breathsRemaining,
                breathPhaseLabel: context.state.breathPhaseLabel
            )
            .activityBackgroundTint(WidgetPalette.liveActivityTint.opacity(0.5))
            .activitySystemActionForegroundColor(WidgetPalette.pillPurple)
            .widgetURL(deepLink(for: context.state.session))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityStepIcon(
                        icon: leadingIcon(for: context.state),
                        size: 36
                    )
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.stepTitle)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        if context.state.session == .prayerBreath, context.state.breathsRemaining > 0 {
                            Text("\(context.state.breathsRemaining) breaths left")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Step \(context.state.stepIndex + 1) of \(context.state.totalSteps)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.session == .prayerBreath {
                        Text(context.state.breathPhaseLabel)
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(WidgetPalette.pillTeal)
                    } else {
                        Text(formattedElapsed(context.state.elapsedSeconds))
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(WidgetPalette.pillPurple)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityCompactProgress(
                        current: context.state.stepIndex,
                        total: context.state.totalSteps
                    )
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: leadingIcon(for: context.state))
                    .foregroundStyle(
                        context.state.session == .prayerBreath
                            ? WidgetPalette.pillTeal
                            : WidgetPalette.pillTeal
                    )
            } compactTrailing: {
                if context.state.session == .prayerBreath {
                    Text(context.state.breathPhaseLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WidgetPalette.pillPurple)
                        .lineLimit(1)
                } else {
                    Text(formattedElapsed(context.state.elapsedSeconds))
                        .font(.caption2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(WidgetPalette.pillPurple)
                }
            } minimal: {
                Image(systemName: context.state.session == .prayerBreath ? "wind" : "sparkles")
                    .foregroundStyle(WidgetPalette.pillPurple)
            }
            .widgetURL(deepLink(for: context.state.session))
        }
    }

    private func leadingIcon(for state: JournalActivityAttributes.ContentState) -> String {
        switch state.session {
        case .prayerBreath:
            switch state.breathPhaseLabel.lowercased() {
            case "inhale": "arrow.up.circle.fill"
            case "hold": "pause.circle.fill"
            case "exhale": "arrow.down.circle.fill"
            default: "wind"
            }
        case .morningDevotion:
            WidgetPalette.devotionSteps[min(state.stepIndex, WidgetPalette.devotionSteps.count - 1)].icon
        }
    }

    private func formattedElapsed(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func deepLink(for session: SanctuaryLiveSession) -> URL? {
        switch session {
        case .morningDevotion:
            DevotionDeepLink.url(host: .journal)
        case .prayerBreath:
            DevotionDeepLink.url(host: .chaplain)
        }
    }
}
