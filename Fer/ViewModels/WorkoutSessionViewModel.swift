//
//  WorkoutSessionViewModel.swift
//  Fer
//
//  Drives the active workout screen: tracks in-progress sets, runs the
//  rest timer, and saves the finished session to Firestore.
//

import Foundation
import Combine
import FirebaseFirestore

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

    // MARK: - Cross-device live sync (Android, or another iOS device)

    private var activeSessionListener: ListenerRegistration?
    /// The `updatedAt` of the last snapshot *this device* pushed — a listener
    /// firing with this same timestamp is just our own write echoing back,
    /// not a genuine edit from another device.
    private var lastPushedUpdatedAt: Date?

    init(routineName: String, exercises: [LoggedExercise], startedAt: Date = Date()) {
        self.routineName = routineName
        self.exercises = exercises
        self.startedAt = startedAt
        startClock()
        PhoneConnectivityManager.shared.attach(self)
        LiveActivityManager.shared.start(routineName: routineName, contentState: liveActivityContentState)
        persistDraft()
        listenForCrossDeviceUpdates()
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
        persistDraft()
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

    func updateWeight(exerciseIndex: Int, setIndex: Int, weight: Double) {
        guard exercises.indices.contains(exerciseIndex),
              exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        exercises[exerciseIndex].sets[setIndex].weight = weight
        updateLiveActivity()
        persistDraft()
    }

    func updateReps(exerciseIndex: Int, setIndex: Int, reps: Int) {
        guard exercises.indices.contains(exerciseIndex),
              exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        exercises[exerciseIndex].sets[setIndex].reps = reps
        updateLiveActivity()
        persistDraft()
    }

    func toggleWarmup(exerciseIndex: Int, setIndex: Int) {
        guard exercises.indices.contains(exerciseIndex),
              exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }
        exercises[exerciseIndex].sets[setIndex].isWarmup.toggle()
        updateLiveActivity()
        persistDraft()
    }

    func updateNotes(exerciseIndex: Int, notes: String) {
        guard exercises.indices.contains(exerciseIndex) else { return }
        exercises[exerciseIndex].notes = notes
        persistDraft()
    }

    func updateRestSeconds(exerciseId: String, seconds: Int) {
        restSecondsByExerciseId[exerciseId] = seconds
        persistDraft()
    }

    // MARK: - Rest timer

    func startRest(seconds: Int) {
        beginRestTimer(seconds: seconds)
        notifyChange()
        updateLiveActivity()
        persistDraft()
    }

    /// Just the timer mechanics, with no cross-device push — used both by
    /// `startRest` (a local action, which does push) and by the remote-update
    /// listener (adopting another device's rest state, which must not).
    private func beginRestTimer(seconds: Int) {
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
    }

    func skipRest() {
        endRestTimer()
        Haptics.light()
        notifyChange()
        updateLiveActivity()
        persistDraft()
    }

    private func endRestTimer() {
        restTimer?.cancel()
        isResting = false
        restRemaining = 0
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
        activeSessionListener?.remove()
        let session = buildSession()
        try? await FirestoreService.shared.saveWorkout(session)
        HealthKitWriter.shared.save(session)
        PhoneConnectivityManager.shared.detach()
        LiveActivityManager.shared.end()
        WorkoutDraftStore.clear()
        FirestoreService.shared.clearActiveSession()
    }

    func discard() {
        timer?.cancel()
        restTimer?.cancel()
        activeSessionListener?.remove()
        PhoneConnectivityManager.shared.detach()
        LiveActivityManager.shared.end()
        WorkoutDraftStore.clear()
        FirestoreService.shared.clearActiveSession()
    }

    // MARK: - Watch mirroring / Live Activity

    private var currentExerciseIndex: Int {
        exercises.firstIndex { ex in ex.sets.contains { !$0.isCompleted } } ?? max(exercises.count - 1, 0)
    }

    var currentExerciseName: String? {
        exercises.indices.contains(currentExerciseIndex) ? exercises[currentExerciseIndex].exerciseName : nil
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
        LiveActivityContent.build(
            exercises: exercises,
            startedAt: startedAt,
            isResting: isResting,
            restEndDate: isResting ? Date().addingTimeInterval(TimeInterval(restRemaining)) : nil,
            weightUnit: SettingsStore.shared.weightUnit
        )
    }

    /// Picks up any set completions made from the Lock Screen's checkmark
    /// button while the app was suspended (CompleteSetIntent writes those
    /// straight to the shared draft, not to this in-memory array) — called
    /// when the active workout screen comes back to the foreground.
    func refreshFromExternalUpdates() {
        guard let draft = WorkoutDraftStore.load(), draft.startedAt == startedAt else { return }
        guard draft.exercises != exercises else { return }
        exercises = draft.exercises
        notifyChange()
        updateLiveActivity()
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
            restSecondsByExerciseId: restSecondsByExerciseId,
            weightUnitRaw: SettingsStore.shared.weightUnit.rawValue
        ))
        pushActiveSessionToCloud()
    }

    private func pushActiveSessionToCloud() {
        let now = Date()
        lastPushedUpdatedAt = now
        FirestoreService.shared.pushActiveSession(ActiveSessionSnapshot(
            routineName: routineName,
            exercises: exercises,
            startedAt: startedAt,
            isResting: isResting,
            restEndDate: isResting ? Date().addingTimeInterval(TimeInterval(restRemaining)) : nil,
            restSecondsByExerciseId: restSecondsByExerciseId,
            weightUnitRaw: SettingsStore.shared.weightUnit.rawValue,
            updatedAt: now
        ))
    }

    /// Listens for edits made from another device (e.g. Android joining this
    /// same live session) and adopts them locally — without re-pushing,
    /// which would otherwise ping-pong the two devices' writes forever.
    private func listenForCrossDeviceUpdates() {
        activeSessionListener = FirestoreService.shared.activeSessionListener { [weak self] snapshot in
            guard let self, let snapshot else { return }
            // A stray doc from a different session — compare with slack since Date round-trips
            // through Firestore's Timestamp type can lose sub-millisecond precision.
            guard abs(snapshot.startedAt.timeIntervalSince(self.startedAt)) < 1 else { return }
            guard let lastPushed = self.lastPushedUpdatedAt, snapshot.updatedAt > lastPushed else { return }
            self.lastPushedUpdatedAt = snapshot.updatedAt
            self.exercises = snapshot.exercises
            self.restSecondsByExerciseId = snapshot.restSecondsByExerciseId
            if snapshot.isResting, let restEndDate = snapshot.restEndDate {
                self.beginRestTimer(seconds: max(0, Int(restEndDate.timeIntervalSinceNow)))
            } else if self.isResting && !snapshot.isResting {
                self.endRestTimer()
            }
            self.notifyChange()
            self.updateLiveActivity()
            WorkoutDraftStore.save(WorkoutDraft(
                routineName: self.routineName,
                exercises: self.exercises,
                startedAt: self.startedAt,
                restSecondsByExerciseId: self.restSecondsByExerciseId,
                weightUnitRaw: SettingsStore.shared.weightUnit.rawValue
            ))
        }
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
