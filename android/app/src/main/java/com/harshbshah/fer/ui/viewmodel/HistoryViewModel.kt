package com.harshbshah.fer.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.harshbshah.fer.data.ExerciseLibrary
import com.harshbshah.fer.data.model.MuscleGroup
import com.harshbshah.fer.data.model.SetEntry
import com.harshbshah.fer.data.model.WorkoutSession
import com.harshbshah.fer.data.repository.FirestoreRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Date

class HistoryViewModel(private val repository: FirestoreRepository) : ViewModel() {
    private val _workouts = MutableStateFlow<List<WorkoutSession>>(emptyList())
    val workouts: StateFlow<List<WorkoutSession>> = _workouts

    init {
        viewModelScope.launch {
            repository.workoutsFlow().collect { _workouts.value = it }
        }
    }

    private fun startOfDay(date: Date): Date {
        val cal = Calendar.getInstance()
        cal.time = date
        cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)
        return cal.time
    }

    val currentStreak: Int
        get() {
            val days = _workouts.value.map { startOfDay(it.startedAt) }.toSet()
            var streak = 0
            var cursor = startOfDay(Date())
            while (days.contains(cursor)) {
                streak++
                val cal = Calendar.getInstance(); cal.time = cursor; cal.add(Calendar.DAY_OF_YEAR, -1)
                cursor = cal.time
            }
            return streak
        }

    val workoutsThisWeek: Int
        get() {
            val cal = Calendar.getInstance(); cal.add(Calendar.DAY_OF_YEAR, -7)
            val weekAgo = cal.time
            return _workouts.value.count { it.startedAt >= weekAgo }
        }

    fun delete(workout: WorkoutSession) {
        val id = workout.id ?: return
        viewModelScope.launch { runCatching { repository.deleteWorkout(id) } }
    }

    fun history(exerciseId: String): List<Pair<Date, SetEntry>> =
        repository.history(exerciseId, _workouts.value)

    fun workoutDates(lastDays: Int): Set<Date> {
        val cal = Calendar.getInstance(); cal.add(Calendar.DAY_OF_YEAR, -(lastDays - 1))
        val cutoff = startOfDay(cal.time)
        return _workouts.value.mapNotNull { w ->
            val day = startOfDay(w.startedAt)
            if (day >= cutoff) day else null
        }.toSet()
    }

    fun dailyVolume(lastDays: Int): List<Pair<Date, Double>> {
        val today = startOfDay(Date())
        val volumeByDay = mutableMapOf<Date, Double>()
        for (w in _workouts.value) {
            val day = startOfDay(w.startedAt)
            volumeByDay[day] = (volumeByDay[day] ?: 0.0) + w.totalVolume
        }
        return (0 until lastDays).reversed().map { offset ->
            val cal = Calendar.getInstance(); cal.time = today; cal.add(Calendar.DAY_OF_YEAR, -offset)
            val day = cal.time
            day to (volumeByDay[day] ?: 0.0)
        }
    }

    fun weeklyVolume(weeks: Int): List<Pair<Date, Double>> {
        fun weekStart(date: Date): Date {
            val cal = Calendar.getInstance()
            cal.firstDayOfWeek = Calendar.MONDAY
            cal.time = date
            cal.set(Calendar.DAY_OF_WEEK, cal.firstDayOfWeek)
            cal.set(Calendar.HOUR_OF_DAY, 0); cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0); cal.set(Calendar.MILLISECOND, 0)
            return cal.time
        }
        val thisWeekStart = weekStart(Date())
        val volumeByWeek = mutableMapOf<Date, Double>()
        for (w in _workouts.value) {
            val ws = weekStart(w.startedAt)
            volumeByWeek[ws] = (volumeByWeek[ws] ?: 0.0) + w.totalVolume
        }
        return (0 until weeks).reversed().map { offset ->
            val cal = Calendar.getInstance(); cal.time = thisWeekStart; cal.add(Calendar.WEEK_OF_YEAR, -offset)
            val ws = cal.time
            ws to (volumeByWeek[ws] ?: 0.0)
        }
    }

    fun volumeByMuscleGroup(): List<Pair<MuscleGroup, Double>> {
        val exercisesById = ExerciseLibrary.all.associateBy { it.id }
        val volumeByMuscle = mutableMapOf<MuscleGroup, Double>()
        for (workout in _workouts.value) {
            for (exercise in workout.exercises) {
                val muscle = exercisesById[exercise.exerciseId]?.primaryMuscle ?: continue
                val volume = exercise.sets.filter { it.isCompleted }.sumOf { it.weight * it.reps }
                volumeByMuscle[muscle] = (volumeByMuscle[muscle] ?: 0.0) + volume
            }
        }
        return volumeByMuscle.filter { it.value > 0 }.map { it.key to it.value }.sortedByDescending { it.second }
    }
}
