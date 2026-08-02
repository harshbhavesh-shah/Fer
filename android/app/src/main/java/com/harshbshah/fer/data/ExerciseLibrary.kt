package com.harshbshah.fer.data

import com.harshbshah.fer.data.model.Equipment
import com.harshbshah.fer.data.model.Exercise
import com.harshbshah.fer.data.model.Exercise.TrackingType
import com.harshbshah.fer.data.model.MuscleGroup
import com.harshbshah.fer.data.model.MuscleGroup.*

/**
 * Built-in seed exercise list. Loaded locally (no network needed) so the
 * library always works offline. IDs must stay byte-for-byte identical to
 * `Fer/Data/ExerciseLibrary.swift` on iOS (they're the join key used by
 * WorkoutSession.exercises[].exerciseId), so this list is a straight port —
 * same names, same slug rule (lowercase, spaces -> "-", apostrophes dropped).
 */
object ExerciseLibrary {
    val all: List<Exercise> = listOf(
        // Chest
        ex("Barbell Bench Press", chest, listOf(triceps, shoulders), Equipment.barbell),
        ex("Incline Barbell Bench Press", chest, listOf(shoulders, triceps), Equipment.barbell),
        ex("Dumbbell Bench Press", chest, listOf(triceps, shoulders), Equipment.dumbbell),
        ex("Incline Dumbbell Press", chest, listOf(shoulders, triceps), Equipment.dumbbell),
        ex("Cable Fly", chest, emptyList(), Equipment.cable),
        ex("Push Up", chest, listOf(triceps, abs), Equipment.bodyweight, TrackingType.bodyweightReps),
        ex("Chest Dip", chest, listOf(triceps), Equipment.bodyweight, TrackingType.bodyweightReps),
        ex("Machine Chest Press", chest, listOf(triceps), Equipment.machine),

        // Back
        ex("Deadlift", back, listOf(hamstrings, glutes, forearms), Equipment.barbell),
        ex("Pull Up", back, listOf(biceps), Equipment.bodyweight, TrackingType.bodyweightReps),
        ex("Chin Up", back, listOf(biceps), Equipment.bodyweight, TrackingType.bodyweightReps),
        ex("Lat Pulldown", back, listOf(biceps), Equipment.cable),
        ex("Barbell Row", back, listOf(biceps), Equipment.barbell),
        ex("Dumbbell Row", back, listOf(biceps), Equipment.dumbbell),
        ex("Seated Cable Row", back, listOf(biceps), Equipment.cable),
        ex("T-Bar Row", back, listOf(biceps), Equipment.barbell),

        // Shoulders
        ex("Overhead Press", shoulders, listOf(triceps), Equipment.barbell),
        ex("Dumbbell Shoulder Press", shoulders, listOf(triceps), Equipment.dumbbell),
        ex("Lateral Raise", shoulders, emptyList(), Equipment.dumbbell),
        ex("Front Raise", shoulders, emptyList(), Equipment.dumbbell),
        ex("Rear Delt Fly", shoulders, listOf(back), Equipment.dumbbell),
        ex("Face Pull", shoulders, listOf(back), Equipment.cable),
        ex("Arnold Press", shoulders, listOf(triceps), Equipment.dumbbell),

        // Arms
        ex("Barbell Curl", biceps, listOf(forearms), Equipment.barbell),
        ex("Dumbbell Curl", biceps, listOf(forearms), Equipment.dumbbell),
        ex("Hammer Curl", biceps, listOf(forearms), Equipment.dumbbell),
        ex("Preacher Curl", biceps, emptyList(), Equipment.barbell),
        ex("Cable Curl", biceps, emptyList(), Equipment.cable),
        ex("Tricep Pushdown", triceps, emptyList(), Equipment.cable),
        ex("Skull Crusher", triceps, emptyList(), Equipment.barbell),
        ex("Overhead Tricep Extension", triceps, emptyList(), Equipment.dumbbell),
        ex("Close Grip Bench Press", triceps, listOf(chest), Equipment.barbell),
        ex("Wrist Curl", forearms, emptyList(), Equipment.dumbbell),

        // Legs
        ex("Barbell Back Squat", quads, listOf(glutes, hamstrings), Equipment.barbell),
        ex("Front Squat", quads, listOf(glutes), Equipment.barbell),
        ex("Leg Press", quads, listOf(glutes, hamstrings), Equipment.machine),
        ex("Walking Lunge", quads, listOf(glutes), Equipment.dumbbell),
        ex("Leg Extension", quads, emptyList(), Equipment.machine),
        ex("Romanian Deadlift", hamstrings, listOf(glutes, back), Equipment.barbell),
        ex("Leg Curl", hamstrings, emptyList(), Equipment.machine),
        ex("Hip Thrust", glutes, listOf(hamstrings), Equipment.barbell),
        ex("Bulgarian Split Squat", quads, listOf(glutes), Equipment.dumbbell),
        ex("Standing Calf Raise", calves, emptyList(), Equipment.machine),
        ex("Seated Calf Raise", calves, emptyList(), Equipment.machine),

        // Abs
        ex("Plank", abs, emptyList(), Equipment.bodyweight, TrackingType.time),
        ex("Hanging Leg Raise", abs, emptyList(), Equipment.bodyweight, TrackingType.bodyweightReps),
        ex("Cable Crunch", abs, emptyList(), Equipment.cable),
        ex("Ab Wheel Rollout", abs, emptyList(), Equipment.other),
        ex("Sit Up", abs, emptyList(), Equipment.bodyweight, TrackingType.bodyweightReps),
        ex("Russian Twist", abs, emptyList(), Equipment.bodyweight, TrackingType.bodyweightReps),

        // Cardio / full body
        ex("Treadmill Run", cardio, emptyList(), Equipment.other, TrackingType.distanceTime),
        ex("Rowing Machine", cardio, listOf(back), Equipment.machine, TrackingType.distanceTime),
        ex("Stationary Bike", cardio, listOf(quads), Equipment.machine, TrackingType.distanceTime),
        ex("Kettlebell Swing", fullBody, listOf(glutes, back), Equipment.kettlebell),
        ex("Burpee", fullBody, emptyList(), Equipment.bodyweight, TrackingType.bodyweightReps),
        ex("Farmer's Carry", fullBody, listOf(forearms), Equipment.dumbbell, TrackingType.distanceTime)
    )

    private fun ex(
        name: String,
        primary: MuscleGroup,
        secondary: List<MuscleGroup>,
        equipment: Equipment,
        tracking: TrackingType = TrackingType.weightReps
    ): Exercise = Exercise(
        id = name.lowercase().replace(" ", "-").replace("'", ""),
        name = name,
        primaryMuscle = primary,
        secondaryMuscles = secondary,
        equipment = equipment,
        trackingType = tracking
    )

    fun byId(id: String): Exercise? = all.firstOrNull { it.id == id }
}
