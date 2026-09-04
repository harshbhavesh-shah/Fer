package com.harshbshah.fer.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.harshbshah.fer.data.model.ActiveSessionSnapshot
import com.harshbshah.fer.data.model.Exercise
import com.harshbshah.fer.data.model.LoggedExercise
import com.harshbshah.fer.data.model.RoutineTemplate
import com.harshbshah.fer.data.model.SetEntry
import com.harshbshah.fer.data.model.WorkoutSession
import com.harshbshah.fer.data.repository.FirestoreRepository
import com.harshbshah.fer.util.Haptics
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.Date
import kotlin.math.abs
import kotlin.math.max

/**
 * Drives the active workout screen — mirrors WorkoutSessionViewModel.swift,
 * including its cross-device live sync: every mutation pushes the full state
 * to users/{uid}/activeSession/current in Firestore, and a listener adopts
 * edits made from another device (e.g. the same workout opened live on iOS)
 * without re-pushing, which would otherwise ping-pong the two devices' writes
 * forever — see `lastPushedUpdatedAt` / `applyRemoteSnapshot`.
 *
 * [isRemoteSession] is true when this screen was opened by *joining* a
 * session already running elsewhere (see [fromRemoteSession]) — Finish/Discard
 * stay disabled in that case, same as the Watch can't finish/discard a
 * phone-owned session, to avoid two devices independently saving the same
 * workout as two separate documents.
 */
class ActiveWorkoutViewModel(
    private val repository: FirestoreRepository,
    routineName: String,
    initialExercises: List<LoggedExercise>,
    private val defaultRestSeconds: Int,
    /** Snapshot of prior workouts at session start, for the "Previous" set reference column. */
    private val pastWorkouts: List<WorkoutSession> = emptyList(),
    startedAt: Date = Date(),
    private val weightUnitRaw: String = "lb",
    val isRemoteSession: Boolean = false
) : ViewModel() {

    private val _restSecondsByExerciseId = MutableStateFlow<Map<String, Int>>(emptyMap())
    val restSecondsByExerciseId: StateFlow<Map<String, Int>> = _restSecondsByExerciseId

    /** Sets from the most recent past workout that logged this exercise, same order —
     *  set N's "Previous" is that workout's set N, matching Hevy's reference column. */
    fun previousSets(exerciseId: String): List<SetEntry> {
        return pastWorkouts
            .filter { workout -> workout.exercises.any { it.exerciseId == exerciseId } }
            .maxByOrNull { it.startedAt }
            ?.exercises
            ?.firstOrNull { it.exerciseId == exerciseId }
            ?.sets
            .orEmpty()
    }

    private val _routineName = MutableStateFlow(routineName)
    val routineName: StateFlow<String> = _routineName

    private val _exercises = MutableStateFlow(initialExercises)
    val exercises: StateFlow<List<LoggedExercise>> = _exercises

    val startedAt: Date = startedAt

    private val _elapsedSeconds = MutableStateFlow(0L)
    val elapsedSeconds: StateFlow<Long> = _elapsedSeconds

    private val _restRemaining = MutableStateFlow(0)
    val restRemaining: StateFlow<Int> = _restRemaining

    private val _restTotal = MutableStateFlow(0)
    val restTotal: StateFlow<Int> = _restTotal

    private val _isResting = MutableStateFlow(false)
    val isResting: StateFlow<Boolean> = _isResting

    private var restJob: Job? = null

    // MARK: - Cross-device live sync

    /** The `updatedAt` of the last snapshot *this device* pushed — a listener firing
     *  with this same timestamp is just our own write echoing back, not a genuine
     *  edit from another device. */
    private var lastPushedUpdatedAt: Date? = null

    companion object {
        fun fromRoutine(routine: RoutineTemplate): Pair<String, List<LoggedExercise>> {
            val exercises = routine.exercises.map { re ->
                LoggedExercise(
                    exerciseId = re.exerciseId,
                    exerciseName = re.exerciseName,
                    sets = (0 until re.targetSets).map { SetEntry(reps = re.targetReps) }
                )
            }
            return routine.name to exercises
        }

        /** Builds the (routineName, exercises, startedAt) a joining device needs to
         *  construct an ActiveWorkoutViewModel already caught up to a live session. */
        fun fromRemoteSession(snapshot: ActiveSessionSnapshot): Triple<String, List<LoggedExercise>, Date> =
            Triple(snapshot.routineName, snapshot.exercises, snapshot.startedAt)
    }

    init {
        viewModelScope.launch {
            while (true) {
                delay(1000)
                _elapsedSeconds.value = (Date().time - startedAt.time) / 1000
            }
        }
        viewModelScope.launch {
            repository.activeSessionFlow().collect { snapshot -> applyRemoteSnapshot(snapshot) }
        }
        pushActiveSessionToCloud()
    }

    private fun applyRemoteSnapshot(snapshot: ActiveSessionSnapshot?) {
        if (snapshot == null) return
        // A stray doc from a different session — compare with slack since Date
        // round-trips through Firestore's Timestamp type can lose precision.
        if (abs(snapshot.startedAt.time - startedAt.time) >= 1000) return
        val lastPushed = lastPushedUpdatedAt
        if (lastPushed != null && !snapshot.updatedAt.after(lastPushed)) return // our own echo

        lastPushedUpdatedAt = snapshot.updatedAt
        _exercises.value = snapshot.exercises
        _restSecondsByExerciseId.value = snapshot.restSecondsByExerciseId
        val restEndDate = snapshot.restEndDate
        if (snapshot.isResting && restEndDate != null) {
            beginRestTimer(max(0, ((restEndDate.time - System.currentTimeMillis()) / 1000).toInt()))
        } else if (_isResting.value && !snapshot.isResting) {
            endRestTimer()
        }
    }

    private fun pushActiveSessionToCloud() {
        val now = Date()
        lastPushedUpdatedAt = now
        repository.pushActiveSession(
            ActiveSessionSnapshot(
                routineName = _routineName.value,
                exercises = _exercises.value,
                startedAt = startedAt,
                isResting = _isResting.value,
                restEndDate = if (_isResting.value) Date(System.currentTimeMillis() + _restRemaining.value * 1000L) else null,
                restSecondsByExerciseId = _restSecondsByExerciseId.value,
                weightUnitRaw = weightUnitRaw,
                updatedAt = now
            )
        )
    }

    fun setRestSecondsFor(routine: RoutineTemplate) {
        _restSecondsByExerciseId.update { current ->
            current + routine.exercises.associate { it.exerciseId to it.restSeconds }
        }
    }

    /** Seeds rest-time overrides when joining a session already running elsewhere. */
    fun setRestSecondsMap(map: Map<String, Int>) {
        _restSecondsByExerciseId.value = map
    }

    fun setRestSeconds(exerciseId: String, seconds: Int) {
        _restSecondsByExerciseId.update { it + (exerciseId to seconds) }
        Haptics.selection()
        pushActiveSessionToCloud()
    }

    fun restSecondsFor(exerciseId: String): Int = _restSecondsByExerciseId.value[exerciseId] ?: defaultRestSeconds

    // MARK: - Editing

    fun addExercise(exercise: Exercise) {
        _exercises.update { it + LoggedExercise(exerciseId = exercise.id, exerciseName = exercise.name, sets = listOf(SetEntry())) }
        Haptics.light()
        pushActiveSessionToCloud()
    }

    fun addSet(exerciseIndex: Int) {
        _exercises.update { list ->
            if (exerciseIndex !in list.indices) return@update list
            val target = list[exerciseIndex]
            val last = target.sets.lastOrNull()
            val newSet = SetEntry(weight = last?.weight ?: 0.0, reps = last?.reps ?: 0)
            list.toMutableList().also { it[exerciseIndex] = target.copy(sets = target.sets + newSet) }
        }
        Haptics.light()
        pushActiveSessionToCloud()
    }

    fun removeSet(exerciseIndex: Int, setIndex: Int) {
        _exercises.update { list ->
            if (exerciseIndex !in list.indices) return@update list
            val target = list[exerciseIndex]
            if (setIndex !in target.sets.indices) return@update list
            val newSets = target.sets.toMutableList().also { it.removeAt(setIndex) }
            list.toMutableList().also { it[exerciseIndex] = target.copy(sets = newSets) }
        }
        pushActiveSessionToCloud()
    }

    fun removeExercise(index: Int) {
        _exercises.update { list -> list.toMutableList().also { if (index in it.indices) it.removeAt(index) } }
        pushActiveSessionToCloud()
    }

    fun updateWeight(exerciseIndex: Int, setIndex: Int, weight: Double) {
        updateSet(exerciseIndex, setIndex) { it.copy(weight = weight) }
        pushActiveSessionToCloud()
    }

    fun updateReps(exerciseIndex: Int, setIndex: Int, reps: Int) {
        updateSet(exerciseIndex, setIndex) { it.copy(reps = reps) }
        pushActiveSessionToCloud()
    }

    fun toggleComplete(exerciseIndex: Int, setIndex: Int) {
        val list = _exercises.value
        if (exerciseIndex !in list.indices) return
        val target = list[exerciseIndex]
        if (setIndex !in target.sets.indices) return
        val nowCompleted = !target.sets[setIndex].isCompleted
        updateSet(exerciseIndex, setIndex) { it.copy(isCompleted = nowCompleted) }
        if (nowCompleted) {
            Haptics.success()
            startRest(restSecondsFor(target.exerciseId))
        } else {
            Haptics.selection()
            pushActiveSessionToCloud()
        }
    }

    fun toggleWarmup(exerciseIndex: Int, setIndex: Int) {
        val list = _exercises.value
        if (exerciseIndex !in list.indices || setIndex !in list[exerciseIndex].sets.indices) return
        val nowWarmup = !list[exerciseIndex].sets[setIndex].isWarmup
        updateSet(exerciseIndex, setIndex) { it.copy(isWarmup = nowWarmup) }
        Haptics.selection()
        pushActiveSessionToCloud()
    }

    fun updateNotes(exerciseIndex: Int, notes: String) {
        _exercises.update { list ->
            if (exerciseIndex !in list.indices) return@update list
            list.toMutableList().also { it[exerciseIndex] = it[exerciseIndex].copy(notes = notes) }
        }
        pushActiveSessionToCloud()
    }

    private fun updateSet(exerciseIndex: Int, setIndex: Int, transform: (SetEntry) -> SetEntry) {
        _exercises.update { list ->
            if (exerciseIndex !in list.indices) return@update list
            val target = list[exerciseIndex]
            if (setIndex !in target.sets.indices) return@update list
            val newSets = target.sets.toMutableList().also { it[setIndex] = transform(it[setIndex]) }
            list.toMutableList().also { it[exerciseIndex] = target.copy(sets = newSets) }
        }
    }

    // MARK: - Rest timer

    fun startRest(seconds: Int) {
        beginRestTimer(seconds)
        pushActiveSessionToCloud()
    }

    /** Just the timer mechanics, with no cross-device push — used both by [startRest]
     *  (a local action, which does push) and by [applyRemoteSnapshot] (adopting
     *  another device's rest state, which must not). */
    private fun beginRestTimer(seconds: Int) {
        restJob?.cancel()
        _restTotal.value = seconds
        _restRemaining.value = seconds
        _isResting.value = true
        restJob = viewModelScope.launch {
            while (_restRemaining.value > 0) {
                delay(1000)
                _restRemaining.value = (_restRemaining.value - 1).coerceAtLeast(0)
                if (_restRemaining.value in 1..3) Haptics.soft()
                if (_restRemaining.value == 0) {
                    Haptics.success()
                    _isResting.value = false
                }
            }
        }
    }

    fun skipRest() {
        endRestTimer()
        Haptics.light()
        pushActiveSessionToCloud()
    }

    private fun endRestTimer() {
        restJob?.cancel()
        _isResting.value = false
        _restRemaining.value = 0
    }

    fun addRestTime(seconds: Int) {
        _restRemaining.update { it + seconds }
        _restTotal.update { it + seconds }
        Haptics.light()
        pushActiveSessionToCloud()
    }

    // MARK: - Completion

    val totalSetsCompleted: Int get() = _exercises.value.sumOf { ex -> ex.sets.count { it.isCompleted } }
    val totalVolume: Double get() = _exercises.value.sumOf { ex -> ex.sets.filter { it.isCompleted }.sumOf { it.weight * it.reps } }

    fun buildSession(): WorkoutSession = WorkoutSession(
        routineName = _routineName.value,
        startedAt = startedAt,
        endedAt = Date(),
        exercises = _exercises.value
    )

    suspend fun finish() {
        restJob?.cancel()
        runCatching { repository.saveWorkout(buildSession()) }
        repository.clearActiveSession()
    }

    fun discard() {
        restJob?.cancel()
        repository.clearActiveSession()
    }
}
