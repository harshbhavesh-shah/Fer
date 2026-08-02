package com.harshbshah.fer.data.model

import com.google.firebase.firestore.Exclude
import java.util.Date
import java.util.UUID

/** A saved workout plan (e.g. "Push Day") the user can start from. */
data class RoutineTemplate @JvmOverloads constructor(
    @get:Exclude @set:Exclude
    var id: String? = null,

    var name: String = "",
    // Stored as the iOS SF Symbol name (e.g. "list.bullet.rectangle") so a routine
    // created on either platform renders a matching icon on the other — see
    // RoutineIcons.kt for the SF Symbol -> Material icon mapping used for display.
    var iconName: String = "list.bullet.rectangle",
    var exercises: List<RoutineExercise> = emptyList(),
    var createdAt: Date = Date(),
    var lastUsedAt: Date? = null,
    var ownerId: String = ""
)

data class RoutineExercise @JvmOverloads constructor(
    var id: String = UUID.randomUUID().toString(),
    var exerciseId: String = "",
    var exerciseName: String = "",
    var targetSets: Int = 3,
    var targetReps: Int = 10,
    var restSeconds: Int = 90,
    var notes: String = ""
)
