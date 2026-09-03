//
//  LiveActivitySync.swift
//  Fer
//
//  Shared with the FerLiveActivity widget extension (see its target's
//  membership exceptions in project.pbxproj) — this is the one place that
//  turns a workout's exercises into the Live Activity's ContentState, so
//  the main app and the extension's CompleteSetIntent always agree on which
//  set is "current" after a completion toggles from the Lock Screen.
//

import Foundation

enum LiveActivityContent {
    static func build(
        exercises: [LoggedExercise],
        startedAt: Date,
        isResting: Bool,
        restEndDate: Date?,
        weightUnit: UserProfile.WeightUnit
    ) -> WorkoutActivityAttributes.ContentState {
        let completedSets = exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
        let totalSets = exercises.reduce(0) { $0 + $1.sets.count }

        for exercise in exercises {
            guard let setIndex = exercise.sets.firstIndex(where: { !$0.isCompleted }) else { continue }
            let set = exercise.sets[setIndex]
            let summary = set.weight > 0
                ? "\(Formatters.weight(set.weight, unit: weightUnit)) \(weightUnit.label) × \(set.reps)"
                : "\(set.reps) reps"
            return WorkoutActivityAttributes.ContentState(
                exerciseName: exercise.exerciseName,
                exerciseUUID: exercise.id,
                setID: set.id,
                setNumber: setIndex + 1,
                setsInExercise: exercise.sets.count,
                setSummary: summary,
                completedSets: completedSets,
                totalSets: totalSets,
                isResting: isResting,
                restEndDate: restEndDate,
                elapsedStartDate: startedAt,
                isWorkoutComplete: false
            )
        }

        return WorkoutActivityAttributes.ContentState(
            exerciseName: exercises.last?.exerciseName ?? "Workout",
            exerciseUUID: "",
            setID: "",
            setNumber: 0,
            setsInExercise: 0,
            setSummary: "All sets complete",
            completedSets: completedSets,
            totalSets: totalSets,
            isResting: isResting,
            restEndDate: restEndDate,
            elapsedStartDate: startedAt,
            isWorkoutComplete: true
        )
    }

    /// Convenience for callers (namely CompleteSetIntent) that only have a
    /// WorkoutDraft, not a live view model, to hand to.
    static func build(from draft: WorkoutDraft, isResting: Bool = false, restEndDate: Date? = nil) -> WorkoutActivityAttributes.ContentState {
        build(
            exercises: draft.exercises,
            startedAt: draft.startedAt,
            isResting: isResting,
            restEndDate: restEndDate,
            weightUnit: UserProfile.WeightUnit(rawValue: draft.weightUnitRaw) ?? .lb
        )
    }
}
