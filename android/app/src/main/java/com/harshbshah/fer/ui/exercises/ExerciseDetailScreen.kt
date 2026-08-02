package com.harshbshah.fer.ui.exercises

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
import com.harshbshah.fer.data.model.Exercise
import com.harshbshah.fer.data.model.UserProfile.WeightUnit
import com.harshbshah.fer.ui.components.BarChart
import com.harshbshah.fer.ui.components.EmptyState
import com.harshbshah.fer.ui.components.cardStyle
import com.harshbshah.fer.ui.viewmodel.HistoryViewModel
import com.harshbshah.fer.util.Formatters
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ShowChart

@Composable
fun ExerciseDetailScreen(exercise: Exercise, historyVM: HistoryViewModel, weightUnit: WeightUnit) {
    val history = historyVM.history(exercise.id)

    Column(modifier = Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text(exercise.name, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Text(
            "${exercise.primaryMuscle.displayName} · ${exercise.equipment.displayName}",
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        if (history.isEmpty()) {
            EmptyState(
                icon = Icons.Filled.ShowChart,
                title = "No history yet",
                message = "Log this exercise in a workout to start tracking progress."
            )
        } else {
            Column(modifier = Modifier.cardStyle(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Best set weight over time", style = MaterialTheme.typography.titleMedium)
                BarChart(values = history.map { Formatters.displayValue(it.second.weight, weightUnit) })
            }

            history.reversed().forEach { (date, set) ->
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(Formatters.mediumDate(date), color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text("${Formatters.weight(set.weight, weightUnit)} ${weightUnit.label} x ${set.reps}", fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}
