//
//  CompleteSetIntent.swift
//  FerLiveActivity
//
//  Backs the Lock Screen/Dynamic Island checkmark button — runs entirely in
//  this widget extension's process (openAppWhenRun = false), so tapping it
//  doesn't launch or foreground Fer. It mutates the shared WorkoutDraft (the
//  same file WorkoutSessionViewModel autosaves to) and pushes the resulting
//  state straight to the running Activity, so the Lock Screen updates
//  immediately even though the app itself may be suspended and won't see
//  this change until it's next foregrounded (ActiveWorkoutView resyncs from
//  the draft on scenePhase becoming active).
//

import AppIntents
import ActivityKit

@MainActor
struct CompleteSetIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Set"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Exercise ID")
    var exerciseUUID: String

    @Parameter(title: "Set ID")
    var setID: String

    init() {
        exerciseUUID = ""
        setID = ""
    }

    init(exerciseUUID: String, setID: String) {
        self.exerciseUUID = exerciseUUID
        self.setID = setID
    }

    func perform() async throws -> some IntentResult {
        guard var draft = WorkoutDraftStore.load(),
              let exerciseIndex = draft.exercises.firstIndex(where: { $0.id == exerciseUUID }),
              let setIndex = draft.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) else {
            return .result()
        }

        draft.exercises[exerciseIndex].sets[setIndex].isCompleted = true
        WorkoutDraftStore.save(draft)

        var isResting = false
        var restEndDate: Date?
        if let restSeconds = draft.restSecondsByExerciseId[draft.exercises[exerciseIndex].exerciseId], restSeconds > 0 {
            isResting = true
            restEndDate = Date().addingTimeInterval(TimeInterval(restSeconds))
        }

        let newState = LiveActivityContent.build(from: draft, isResting: isResting, restEndDate: restEndDate)
        if let activity = Activity<WorkoutActivityAttributes>.activities.first {
            await activity.update(.init(state: newState, staleDate: nil))
        }

        return .result()
    }
}
