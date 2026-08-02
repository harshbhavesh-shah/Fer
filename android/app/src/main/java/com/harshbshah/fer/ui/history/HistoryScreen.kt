package com.harshbshah.fer.ui.history

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.harshbshah.fer.data.model.UserProfile.WeightUnit
import com.harshbshah.fer.data.model.WorkoutSession
import com.harshbshah.fer.ui.components.BarChart
import com.harshbshah.fer.ui.components.EmptyState
import com.harshbshah.fer.ui.components.WorkoutSummaryCard
import com.harshbshah.fer.ui.components.cardStyle
import com.harshbshah.fer.ui.viewmodel.HistoryViewModel
import com.harshbshah.fer.util.Formatters

@Composable
fun HistoryScreen(
    viewModel: HistoryViewModel,
    weightUnit: WeightUnit,
    bottomContentPadding: Dp = 0.dp,
    onOpenWorkout: (WorkoutSession) -> Unit
) {
    val workouts by viewModel.workouts.collectAsStateWithLifecycle()

    if (workouts.isEmpty()) {
        Box(modifier = Modifier.fillMaxSize()) {
            EmptyState(
                icon = Icons.Filled.History,
                title = "No workouts logged",
                message = "Finish a workout and it will show up here.",
                modifier = Modifier.align(Alignment.Center)
            )
        }
        return
    }

    val grouped = workouts.groupBy { Formatters.monthYear(it.startedAt) }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 16.dp + bottomContentPadding),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        item {
            val weeklyVolume = viewModel.weeklyVolume(8)
            val dateFormat = remember { java.text.SimpleDateFormat("d MMM", java.util.Locale.getDefault()) }
            Column(modifier = Modifier.cardStyle(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Weekly Volume", style = MaterialTheme.typography.titleMedium)
                BarChart(
                    values = weeklyVolume.map { Formatters.displayValue(it.second, weightUnit) },
                    // Every other week's date, like iOS's .stride(by: .weekOfYear, count: 2) —
                    // labeling all 8 bars would crowd the axis.
                    xLabels = weeklyVolume.mapIndexed { index, (weekStart, _) ->
                        if (index % 2 == 0) dateFormat.format(weekStart) else ""
                    },
                    showYAxisLabels = true
                )
            }
        }

        grouped.forEach { (month, monthWorkouts) ->
            item { Text(month, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold) }
            items(monthWorkouts, key = { it.id ?: it.startedAt.time.toString() }) { workout ->
                WorkoutSummaryCard(
                    workout,
                    weightUnit,
                    modifier = Modifier.fillMaxWidth().clickable { onOpenWorkout(workout) },
                    useAbsoluteDate = true
                )
            }
        }
    }
}
