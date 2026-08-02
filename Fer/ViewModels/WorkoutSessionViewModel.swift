//
//  WorkoutSessionViewModel.swift
//  Fer
//
//  Drives the active workout screen: tracks in-progress sets, runs the
//  rest timer, and saves the finished session to Firestore.
//

import Foundation
import Combine

@MainActor
final class WorkoutSessionViewModel: ObservableObject, Identifiable {
    let id = UUID()

    @Published var routineName: String
    @Published var exercises: [LoggedExercise]
    @Published var startedAt = Date()
    @Published var elapsed: TimeInterval = 0

    @Published var restRemaining: Int = 0
    @Published var restTotal: Int = 0
    @Published var isResting = false

    var restSecondsByExerciseId: [String: Int] = [:]

    private var timer: AnyCancellable?
    private var restTimer: AnyCancellable?

    init(routineName: String, exercises: [LoggedExercise], startedAt: Date = Date()) {
        self.routineName = routineName
        self.exercises = exercises
        self.startedAt = startedAt
        startClock()
        PhoneConnectivityManager.shared.attach(self)
        LiveActivityManager.shared.start(routineName: routineName, contentState: liveActivityContentState)
    }

    convenience init(from routine: RoutineTemplate) {
        let exercises = routine.exercises.map { re in
            LoggedExercise(
                exerciseId: re.exerciseId,
                exerciseName: re.exerciseName,
                sets: (0..<re.targetSets).map { _ in SetEntry(reps: re.targetReps) }
            )
        }
        self.init(routineName: routine.name, exercises: exercises)
        for re in routine.exercises {
            restSecondsByExerciseId[re.exerciseId] = re.restSeconds
        }
    }

    convenience init(blank: Bool = true) {
        self.init(routineName: "Quick Workout", exercises: [])
    }

    /// Restores a session from a locally autosaved draft (e.g. after the app
    /// was force-quit mid-workout) — preserves the original start time so
    /// elapsed duration and the Live Activity stay accurate across the gap.
    convenience init(draft: WorkoutDraft) {
        self.init(routineName: draft.routineName, exercises: draft.exercises, startedAt: draft.startedAt)
        self.restSecondsByExerciseId = draft.restSecondsByExerciseId
    }

    private func startClock() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            self.elapsed = Date().timeIntervalSince(self.startedAt)
        }
    }

    // MARK: - Editing

    func addExercise(_ exercise: Exercise) {
        exercises.append(LoggedExercise(exerciseId: exercise.id, exerciseName: exercise.name, sets: [SetEntry()]))
        Haptics.light()
        notifyChange()
        updateLiveActivity()
        persistDraft()
    }

    func addSet(to exerciseIndex: Int) {
        guard exercises.indices.contains(exerciseIndex) else { return }
        let last = exercises[exerciseIndex].sets.last
        var newSet = SetEntry()
        if let last { newSet.weight = last.weight; newSet.reps = last.reps }
        exercises[exerciseIndex].sets.append(newSet)
        Haptics.light()
        notifyChange()
        updateLiveActivity()
        persistDraft()
    }

    func removeSet(exerciseIndex: Int, setIndex: Int) {
        guard exercises.indices.contains(exerciseIndex),
              exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        exercises[exerciseIndex].sets.remove(at: setIndex)
        updateLiveActivity()
        persistDraft()
    }

    func removeExercise(at index: Int) {
        guard exercises.indices.contains(index) else { return }
        exercises.remove(at: index)
        updateLiveActivity()
        persistDraft()
    }

    func toggleComplete(exerciseIndex: Int, setIndex: Int) {
        guard exercises.indices.contains(exerciseIndex),
              exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
        if exercises[exerciseIndex].sets[setIndex].isCompleted {
            Haptics.success()
            let exerciseId = exercises[exerciseIndex].exerciseId
            let restSeconds = restSecondsByExerciseId[exerciseId] ?? SettingsStore.shared.defaultRestSeconds
            startRest(seconds: restSeconds)
        } else {
            Haptics.selection()
        }
        notifyChange()
        updateLiveActivity()
        persistDraft()
    }

    // MARK: - Rest timer

    func startRest(seconds: Int) {
        restTimer?.cancel()
        restTotal = seconds
        restRemaining = seconds
        isResting = true
        restTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            if self.restRemaining > 0 {
                self.restRemaining -= 1
                if self.restRemaining <= 3 && self.restRemaining > 0 { Haptics.soft() }
                if self.restRemaining == 0 {
                    Haptics.success()
                    self.isResting = false
                    self.updateLiveActivity()
                }
                self.notifyChange()
            }
        }
        notifyChange()
        updateLiveActivity()
        persistDraft()
    }

    func skipRest() {
        restTimer?.cancel()
        isResting = false
        restRemaining = 0
        Haptics.light()
        notifyChange()
        updateLiveActivity()
        persistDraft()
    }

    func addRestTime(_ seconds: Int) {
        restRemaining += seconds
        restTotal += seconds
        Haptics.light()
        notifyChange()
        updateLiveActivity()
        persistDraft()
    }

    // MARK: - Completion

    var totalSetsCompleted: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
    }

    var totalVolume: Double {
        exercises.reduce(0) { partial, ex in
            partial + ex.sets.filter(\.isCompleted).reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }

    func buildSession() -> WorkoutSession {
        WorkoutSession(
            routineName: routineName,
            startedAt: startedAt,
            endedAt: Date(),
            exercises: exercises
        )
    }

    func finish() async {
        timer?.cancel()
        restTimer?.cancel()
        let session = buildSession()
        try? await FirestoreService.shared.saveWorkout(session)
        PhoneConnectivityManager.shared.detach()
        LiveActivityManager.shared.end()
        WorkoutDraftStore.clear()
    }

    func discard() {
        timer?.cancel()
        restTimer?.cancel()
        PhoneConnectivityManager.shared.detach()
        LiveActivityManager.shared.end()
        WorkoutDraftStore.clear()
    }

    // MARK: - Watch mirroring / Live Activity

    private var currentExerciseIndex: Int {
        exercises.firstIndex { ex in ex.sets.contains { !$0.isCompleted } } ?? max(exercises.count - 1, 0)
    }

    var snapshot: WorkoutMirrorSnapshot {
        WorkoutMirrorSnapshot(
            routineName: routineName,
            exercises: exercises,
            elapsed: elapsed,
            isResting: isResting,
            restRemaining: restRemaining,
            restTotal: restTotal,
            currentExerciseIndex: currentExerciseIndex
        )
    }

    var liveActivityContentState: WorkoutActivityAttributes.ContentState {
        WorkoutActivityAttributes.ContentState(
            currentExerciseName: exercises.indices.contains(currentExerciseIndex) ? exercises[currentExerciseIndex].exerciseName : routineName,
            completedSets: totalSetsCompleted,
            totalSets: exercises.reduce(0) { $0 + $1.sets.count },
            isResting: isResting,
            restEndDate: isResting ? Date().addingTimeInterval(TimeInterval(restRemaining)) : nil,
            elapsedStartDate: startedAt
        )
    }

    private func notifyChange() {
        PhoneConnectivityManager.shared.pushMirror(snapshot)
    }

    private func updateLiveActivity() {
        LiveActivityManager.shared.update(liveActivityContentState)
    }

    private func persistDraft() {
        WorkoutDraftStore.save(WorkoutDraft(
            routineName: routineName,
            exercises: exercises,
            startedAt: startedAt,
            restSecondsByExerciseId: restSecondsByExerciseId
        ))
    }

    /// Applies an action that originated from the Watch app.
    func apply(_ action: WatchAction) {
        switch action {
        case .toggleSet(let exerciseIndex, let setIndex):
            toggleComplete(exerciseIndex: exerciseIndex, setIndex: setIndex)
        case .addSet(let exerciseIndex):
            addSet(to: exerciseIndex)
        case .skipRest:
            skipRest()
        case .addRestTime(let seconds):
            addRestTime(seconds)
        case .finish, .discard:
            break // Finishing/discarding from the Watch is handled by the phone's active workout screen prompting the user, to avoid silently ending a session.
        }
    }
}
