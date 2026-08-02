package com.harshbshah.fer.data.model

import com.google.firebase.firestore.PropertyName

/** Represents a single exercise definition in the library (not a logged set). */
data class Exercise @JvmOverloads constructor(
    var id: String = "",
    var name: String = "",
    var primaryMuscle: MuscleGroup = MuscleGroup.fullBody,
    var secondaryMuscles: List<MuscleGroup> = emptyList(),
    var equipment: Equipment = Equipment.other,

    @get:PropertyName("isCustom") @set:PropertyName("isCustom")
    var isCustom: Boolean = false,

    var instructions: String? = null,

    /** Which fields make sense to log for this exercise. */
    var trackingType: TrackingType = TrackingType.weightReps
) {
    enum class TrackingType {
        weightReps,      // e.g. Bench Press: weight x reps
        bodyweightReps,  // e.g. Pull Up: reps only (optional added weight)
        time,            // e.g. Plank: duration
        distanceTime     // e.g. Running: distance + duration
    }
}
