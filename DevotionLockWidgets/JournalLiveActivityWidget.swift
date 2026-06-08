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
            // Lock screen banner disabled for now — see GuidedJournalFlowView.
            // LiveActivityLockBanner(
            //     sessionTitle: context.attributes.sessionTitle,
            //     stepTitle: context.state.stepTitle,
            //     stepIndex: context.state.stepIndex,
            //     totalSteps: context.state.totalSteps,
            //     elapsedSeconds: context.state.elapsedSeconds
            // )
            // .activityBackgroundTint(WidgetPalette.liveActivityTint.opacity(0.5))
            // .activitySystemActionForegroundColor(WidgetPalette.pillPurple)
            // .widgetURL(DevotionDeepLink.url(host: .journal))
            EmptyView()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityStepIcon(icon: stepIcon(for: context.state.stepIndex), size: 36)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.stepTitle)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text("Step \(context.state.stepIndex + 1) of \(context.state.totalSteps)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formattedElapsed(context.state.elapsedSeconds))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(WidgetPalette.pillPurple)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityCompactProgress(
                        current: context.state.stepIndex,
                        total: context.state.totalSteps
                    )
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: stepIcon(for: context.state.stepIndex))
                    .foregroundStyle(WidgetPalette.pillTeal)
            } compactTrailing: {
                Text(formattedElapsed(context.state.elapsedSeconds))
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(WidgetPalette.pillPurple)
            } minimal: {
                Image(systemName: "sparkles")
                    .foregroundStyle(WidgetPalette.pillPurple)
            }
            .widgetURL(DevotionDeepLink.url(host: .journal))
        }
    }

    private func stepIcon(for index: Int) -> String {
        WidgetPalette.devotionSteps[min(index, WidgetPalette.devotionSteps.count - 1)].icon
    }

    private func formattedElapsed(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
