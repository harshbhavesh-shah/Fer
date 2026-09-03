//
//  WorkoutLiveActivityWidget.swift
//  FerLiveActivity
//
//  Lock Screen layout deliberately matches Hevy's: a "Workout" header row
//  with the running clock, an exercise row, then a bottom row pairing the
//  next set's target with a checkmark button you can complete right from
//  the Lock Screen — see CompleteSetIntent for what that button actually
//  does. No exercise photo art (we don't have Hevy's), substituted with a
//  plain dumbbell badge, matching the substitution already used elsewhere
//  in this app for the same reason.
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
                        Text(context.state.exerciseName)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ProgressStat(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        StatusLine(state: context.state)
                        Spacer()
                        if !context.state.isWorkoutComplete {
                            CompleteButton(state: context.state, compact: true)
                        }
                    }
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label {
                    Text(attributes.routineName)
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption)
                }
                .foregroundStyle(.white)

                Spacer()

                Text(timerInterval: state.elapsedStartDate...Date.now.addingTimeInterval(60 * 60 * 12), countsDown: false)
                    .monospacedDigit()
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack(spacing: 10) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.15)))

                VStack(alignment: .leading, spacing: 1) {
                    Text(state.exerciseName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if !state.isWorkoutComplete {
                        Text("Set \(state.setNumber) of \(state.setsInExercise)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()
                ProgressStat(state: state)
            }

            Divider().background(Color.white.opacity(0.15))

            HStack {
                StatusLine(state: state)
                Spacer()
                if !state.isWorkoutComplete {
                    CompleteButton(state: state, compact: false)
                }
            }
        }
        .padding(16)
    }
}

/// The interactive checkmark — `Button(intent:)` runs CompleteSetIntent
/// directly in this extension's process, no app launch needed.
private struct CompleteButton: View {
    let state: WorkoutActivityAttributes.ContentState
    let compact: Bool

    var body: some View {
        Button(intent: CompleteSetIntent(exerciseUUID: state.exerciseUUID, setID: state.setID)) {
            Image(systemName: "checkmark")
                .font(compact ? .caption2.weight(.bold) : .subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: compact ? 24 : 32, height: compact ? 24 : 32)
                .background(Circle().fill(Color.green))
        }
        .buttonStyle(.plain)
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
        } else if state.isWorkoutComplete {
            Label("All sets complete", systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
        } else {
            Text(state.setSummary)
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
