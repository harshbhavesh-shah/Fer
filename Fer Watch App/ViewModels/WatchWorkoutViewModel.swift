//
//  WatchWorkoutViewModel.swift
//  Fer Watch App
//
//  Drives a standalone workout logged entirely from the Watch (phone not
//  reachable, or user just prefers logging from the wrist). Mirrors the
//  iPhone target's WorkoutSessionViewModel logic but without any
//  PhoneConnectivityManager coupling, and uses WatchHaptics instead of the
//  UIKit-based Haptics.
//

import Foundation
import Combine

@MainActor
final class WatchWorkoutViewModel: ObservableObject, Identifiable {
    let id = UUID()

    @Published var routineName: String
    @Published var exercises: [LoggedExercise]
    @Published var startedAt = Date()
    @Published var elapsed: TimeInterval = 0

    @Published var restRemaining: Int = 0
    @Published var isResting = false

    private var timer: AnyCancellable?
    private var restTimer: AnyCancellable?

    init(routineName: String, exercises: [LoggedExercise]) {
        self.routineName = routineName
        self.exercises = exercises
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            self.elapsed = Date().timeIntervalSince(self.startedAt)
        }
    }

    convenience init(from routine: RoutineTemplate) {
        let exercises = routine.exercises.map { re in
            LoggedExercise(exerciseId: re.exerciseId, exerciseName: re.exerciseName,
                            sets: (0..<re.targetSets).map { _ in SetEntry(reps: re.targetReps) })
        }
        self.init(routineName: routine.name, exercises: exercises)
    }

    func toggleComplete(exerciseIndex: Int, setIndex: Int, restSeconds: Int = 90) {
        guard exercises.indices.contains(exerciseIndex),
              exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
        if exercises[exerciseIndex].sets[setIndex].isCompleted {
            WatchHaptics.success()
            startRest(seconds: restSeconds)
        } else {
            WatchHaptics.click()
        }
    }

    func addSet(to exerciseIndex: Int) {
        guard exercises.indices.contains(exerciseIndex) else { return }
        exercises[exerciseIndex].sets.append(SetEntry())
        WatchHaptics.click()
    }

    private func startRest(seconds: Int) {
        restTimer?.cancel()
        restRemaining = seconds
        isResting = true
        restTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            if self.restRemaining > 0 {
                self.restRemaining -= 1
                if self.restRemaining == 0 {
                    WatchHaptics.notification()
                    self.isResting = false
                }
            }
        }
    }

    func skipRest() {
        restTimer?.cancel()
        isResting = false
        restRemaining = 0
        WatchHaptics.click()
    }

    var totalSetsCompleted: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
    }

    func finish() async {
        timer?.cancel()
        restTimer?.cancel()
        let session = WorkoutSession(
            routineName: routineName,
            startedAt: startedAt,
            endedAt: Date(),
            exercises: exercises
        )
        // The Watch can't write to Firestore directly (no watchOS Firestore
        // SDK) — hand it to the phone, which saves it and it shows up in
        // History as soon as the phone is reachable.
        WatchConnectivityManager.shared.sendStandaloneWorkout(session)
    }

    func discard() {
        timer?.cancel()
        restTimer?.cancel()
    }
}
