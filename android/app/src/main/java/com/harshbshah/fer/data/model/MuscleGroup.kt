package com.harshbshah.fer.data.model

import androidx.compose.ui.graphics.Color

/**
 * Enum constants are deliberately lowercase (not SCREAMING_CASE) so that
 * Firestore's default `.name`-based enum serialization produces the exact
 * same raw values ("chest", "back", ...) as Swift's `Codable` on iOS —
 * required for the two platforms to read/write the same documents.
 */
enum class MuscleGroup {
    chest, back, shoulders, biceps, triceps, forearms,
    abs, quads, hamstrings, glutes, calves, cardio, fullBody;

    val displayName: String
        get() = when (this) {
            chest -> "Chest"
            back -> "Back"
            shoulders -> "Shoulders"
            biceps -> "Biceps"
            triceps -> "Triceps"
            forearms -> "Forearms"
            abs -> "Abs"
            quads -> "Quads"
            hamstrings -> "Hamstrings"
            glutes -> "Glutes"
            calves -> "Calves"
            cardio -> "Cardio"
            fullBody -> "Full Body"
        }

    val accentColor: Color
        get() = when (this) {
            chest -> Color(0xFFE53935)
            back -> Color(0xFF1E88E5)
            shoulders -> Color(0xFFFB8C00)
            biceps, triceps, forearms -> Color(0xFF8E24AA)
            abs -> Color(0xFFFDD835)
            quads, hamstrings, glutes -> Color(0xFF43A047)
            calves -> Color(0xFF00BFA5)
            cardio -> Color(0xFFD81B60)
            fullBody -> Color(0xFF00897B)
        }
}

enum class Equipment {
    barbell, dumbbell, machine, cable, bodyweight, kettlebell, band, other;

    val displayName: String
        get() = when (this) {
            barbell -> "Barbell"
            dumbbell -> "Dumbbell"
            machine -> "Machine"
            cable -> "Cable"
            bodyweight -> "Bodyweight"
            kettlebell -> "Kettlebell"
            band -> "Band"
            other -> "Other"
        }
}
