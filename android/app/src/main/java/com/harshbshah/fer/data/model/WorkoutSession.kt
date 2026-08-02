package com.harshbshah.fer.data.model

import com.google.firebase.firestore.Exclude
import com.google.firebase.firestore.PropertyName
import java.util.Date
import java.util.UUID

/**
 * A completed (or in-progress) logged workout.
 *
 * `id` is assigned manually from the document reference after decoding
 * (mirrors iOS's FirestoreService), not via @DocumentId, so the shape here
 * is a plain mirror of the Firestore document.
 */
data class WorkoutSession @JvmOverloads constructor(
    @get:Exclude @set:Exclude
    var id: String? = null,

    var ownerId: String = "",
    var routineName: String = "",
    var startedAt: Date = Date(),
    var endedAt: Date? = null,
    var exercises: List<LoggedExercise> = emptyList(),
    var notes: String = ""
) {
    val duration: Long
        get() = ((endedAt ?: Date()).time - startedAt.time) / 1000

    val totalVolume: Double
        get() = exercises.sumOf { ex ->
            ex.sets.filter { it.isCompleted }.sumOf { it.weight * it.reps }
        }

    val totalSetsCompleted: Int
        get() = exercises.sumOf { ex -> ex.sets.count { it.isCompleted } }
}

data class LoggedExercise @JvmOverloads constructor(
    var id: String = UUID.randomUUID().toString(),
    var exerciseId: String = "",
    var exerciseName: String = "",
    var sets: List<SetEntry> = emptyList()
)

data class SetEntry @JvmOverloads constructor(
    var id: String = UUID.randomUUID().toString(),
    var weight: Double = 0.0,
    var reps: Int = 0,
    var rpe: Double? = null,

    @get:PropertyName("isCompleted") @set:PropertyName("isCompleted")
    var isCompleted: Boolean = false,

    @get:PropertyName("isWarmup") @set:PropertyName("isWarmup")
    var isWarmup: Boolean = false
)
