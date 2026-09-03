//
//  WorkoutActivityAttributes.swift
//  Fer
//
//  Shared between the Fer app and the FerLiveActivity widget extension.
//  Content state names one specific set (the next incomplete one, in
//  exercise order) so the Lock Screen/Dynamic Island can show — and let the
//  user complete — exactly the set they'd tap next in the app, mirroring
//  Hevy's interactive Live Activity. `exerciseUUID`/`setID` are the stable
//  LoggedExercise/SetEntry ids (not array indices), so the CompleteSetIntent
//  running in the widget extension can find the right set in the shared
//  WorkoutDraft even if the in-app array has since been reordered.
//

import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var exerciseName: String
        var exerciseUUID: String
        var setID: String
        var setNumber: Int
        var setsInExercise: Int
        var setSummary: String
        var completedSets: Int
        var totalSets: Int
        var isResting: Bool
        var restEndDate: Date?
        var elapsedStartDate: Date
        /// True once every set in the workout is complete — the widget hides
        /// the checkmark button rather than pointing at a nonexistent set.
        var isWorkoutComplete: Bool
    }

    var routineName: String
}
