package com.harshbshah.fer.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
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

/** Drives the active workout screen — mirrors WorkoutSessionViewModel.swift. */
class ActiveWorkoutViewModel(
    private val repository: FirestoreRepository,
    routineName: String,
    initialExercises: List<LoggedExercise>,
    private val defaultRestSeconds: Int
) : ViewModel() {

    private val restSecondsByExerciseId = mutableMapOf<String, Int>()

    private val _routineName = MutableStateFlow(routineName)
    val routineName: StateFlow<String> = _routineName

    private val _exercises = MutableStateFlow(initialExercises)
    val exercises: StateFlow<List<LoggedExercise>> = _exercises

    val startedAt: Date = Date()

    private val _elapsedSeconds = MutableStateFlow(0L)
    val elapsedSeconds: StateFlow<Long> = _elapsedSeconds

    private val _restRemaining = MutableStateFlow(0)
    val restRemaining: StateFlow<Int> = _restRemaining

    private val _restTotal = MutableStateFlow(0)
    val restTotal: StateFlow<Int> = _restTotal

    private val _isResting = MutableStateFlow(false)
    val isResting: StateFlow<Boolean> = _isResting

    private var restJob: Job? = null

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
    }

    init {
        viewModelScope.launch {
            while (true) {
                delay(1000)
                _elapsedSeconds.value = (Date().time - startedAt.time) / 1000
            }
        }
    }

    fun setRestSecondsFor(routine: RoutineTemplate) {
        for (re in routine.exercises) restSecondsByExerciseId[re.exerciseId] = re.restSeconds
    }

    // MARK: - Editing

    fun addExercise(exercise: Exercise) {
        _exercises.update { it + LoggedExercise(exerciseId = exercise.id, exerciseName = exercise.name, sets = listOf(SetEntry())) }
        Haptics.light()
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
    }

    fun removeSet(exerciseIndex: Int, setIndex: Int) {
        _exercises.update { list ->
            if (exerciseIndex !in list.indices) return@update list
            val target = list[exerciseIndex]
            if (setIndex !in target.sets.indices) return@update list
            val newSets = target.sets.toMutableList().also { it.removeAt(setIndex) }
            list.toMutableList().also { it[exerciseIndex] = target.copy(sets = newSets) }
        }
    }

    fun removeExercise(index: Int) {
        _exercises.update { list -> list.toMutableList().also { if (index in it.indices) it.removeAt(index) } }
    }

    fun updateWeight(exerciseIndex: Int, setIndex: Int, weight: Double) {
        updateSet(exerciseIndex, setIndex) { it.copy(weight = weight) }
    }

    fun updateReps(exerciseIndex: Int, setIndex: Int, reps: Int) {
        updateSet(exerciseIndex, setIndex) { it.copy(reps = reps) }
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
            val exerciseId = target.exerciseId
            startRest(restSecondsByExerciseId[exerciseId] ?: defaultRestSeconds)
        } else {
            Haptics.selection()
        }
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
        restJob?.cancel()
        _isResting.value = false
        _restRemaining.value = 0
        Haptics.light()
    }

    fun addRestTime(seconds: Int) {
        _restRemaining.update { it + seconds }
        _restTotal.update { it + seconds }
        Haptics.light()
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
    }

    fun discard() {
        restJob?.cancel()
    }
}
