//
//  WorkoutLiveActivityWidget.swift
//  FerLiveActivity
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenBanner(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.routineName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(context.state.currentExerciseName)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ProgressStat(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    StatusLine(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
            } compactTrailing: {
                if context.state.isResting, let restEndDate = context.state.restEndDate {
                    Text(timerInterval: Date.now...restEndDate, countsDown: true)
                        .monospacedDigit()
                        .font(.caption2)
                        .frame(width: 40)
                } else {
                    Text("\(context.state.completedSets)/\(context.state.totalSets)")
                        .font(.caption2.monospacedDigit())
                }
            } minimal: {
                Image(systemName: "dumbbell.fill")
            }
        }
    }
}

private struct LockScreenBanner: View {
    let attributes: WorkoutActivityAttributes
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.white.opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                Text(attributes.routineName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(state.currentExerciseName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                StatusLine(state: state)
            }

            Spacer()
            ProgressStat(state: state)
        }
        .padding(16)
    }
}

private struct StatusLine: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        if state.isResting, let restEndDate = state.restEndDate {
            Label {
                Text(timerInterval: Date.now...restEndDate, countsDown: true)
                    .monospacedDigit()
            } icon: {
                Image(systemName: "timer")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.orange)
        } else {
            Label {
                Text(timerInterval: state.elapsedStartDate...Date.now.addingTimeInterval(60 * 60 * 12), countsDown: false)
                    .monospacedDigit()
            } icon: {
                Image(systemName: "clock")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.8))
        }
    }
}

private struct ProgressStat: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 2) {
            Text("\(state.completedSets)/\(state.totalSets)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
            Text("sets")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
