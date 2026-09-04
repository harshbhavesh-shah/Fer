package com.harshbshah.fer.data.model

import com.google.firebase.firestore.PropertyName
import java.util.Date

/**
 * The cross-device live-workout document, shared with iOS via Firestore at
 * users/{uid}/activeSession/current — mirrors Fer/Models/ActiveSessionSnapshot.swift
 * field-for-field. Whichever device is active writes the complete state here;
 * `updatedAt` is what lets each side tell its own echo apart from a genuine
 * edit made on the other device.
 */
data class ActiveSessionSnapshot @JvmOverloads constructor(
    var routineName: String = "",
    var exercises: List<LoggedExercise> = emptyList(),
    var startedAt: Date = Date(),

    @get:PropertyName("isResting") @set:PropertyName("isResting")
    var isResting: Boolean = false,

    var restEndDate: Date? = null,
    var restSecondsByExerciseId: Map<String, Int> = emptyMap(),
    var weightUnitRaw: String = "lb",
    var updatedAt: Date = Date()
)
