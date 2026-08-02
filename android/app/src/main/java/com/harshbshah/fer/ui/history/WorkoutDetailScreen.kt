package com.harshbshah.fer.ui.history

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.harshbshah.fer.data.model.UserProfile.WeightUnit
import com.harshbshah.fer.data.model.WorkoutSession
import com.harshbshah.fer.ui.components.cardStyle
import com.harshbshah.fer.util.Formatters

@Composable
fun WorkoutDetailScreen(workout: WorkoutSession, weightUnit: WeightUnit) {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text(workout.routineName, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Text(
            "${Formatters.mediumDate(workout.startedAt)} · ${Formatters.duration(workout.duration)} · ${workout.totalSetsCompleted} sets",
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        workout.exercises.forEach { exercise ->
            Column(modifier = Modifier.cardStyle(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(exercise.exerciseName, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                exercise.sets.forEachIndexed { index, set ->
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(
                            "Set ${index + 1}${if (set.isWarmup) " (warmup)" else ""}",
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            "${Formatters.weight(set.weight, weightUnit)} ${weightUnit.label} x ${set.reps}",
                            fontWeight = if (set.isCompleted) FontWeight.SemiBold else FontWeight.Normal,
                            color = if (set.isCompleted) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }

        if (workout.notes.isNotBlank()) {
            Column(modifier = Modifier.cardStyle()) {
                Text("Notes", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(workout.notes)
            }
        }
    }
}
