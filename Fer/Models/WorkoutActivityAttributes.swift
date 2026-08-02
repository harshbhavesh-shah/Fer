//
//  WorkoutActivityAttributes.swift
//  Fer
//
//  Shared between the Fer app and the FerLiveActivity widget extension.
//  Content state carries start/end Dates rather than raw counters so the
//  widget can render live countdowns/counts-up via Text(timerInterval:)
//  without the app having to push a per-second update.
//

import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentExerciseName: String
        var completedSets: Int
        var totalSets: Int
        var isResting: Bool
        var restEndDate: Date?
        var elapsedStartDate: Date
    }

    var routineName: String
}
