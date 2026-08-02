package com.harshbshah.fer.ui.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
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
import com.harshbshah.fer.data.model.RoutineTemplate
import com.harshbshah.fer.data.model.UserProfile.WeightUnit
import com.harshbshah.fer.data.model.WorkoutSession
import com.harshbshah.fer.ui.components.BarChart
import com.harshbshah.fer.ui.components.WorkoutSummaryCard
import com.harshbshah.fer.ui.components.cardStyle
import com.harshbshah.fer.ui.theme.RoutineIcons
import com.harshbshah.fer.util.Formatters
import com.harshbshah.fer.ui.viewmodel.HistoryViewModel
import com.harshbshah.fer.ui.viewmodel.RoutinesViewModel
import java.util.Calendar

@Composable
fun DashboardScreen(
    routinesVM: RoutinesViewModel,
    historyVM: HistoryViewModel,
    weightUnit: WeightUnit,
    bottomContentPadding: Dp = 0.dp,
    onStartBlank: () -> Unit,
    onStartRoutine: (RoutineTemplate) -> Unit,
    onOpenWorkout: (WorkoutSession) -> Unit
) {
    val routines by routinesVM.routines.collectAsStateWithLifecycle()
    val workouts by historyVM.workouts.collectAsStateWithLifecycle()

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 16.dp + bottomContentPadding),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        item {
            // Mirrors iOS's inline `.navigationTitle("Fer")` nav-bar title —
            // titleLarge/Bold, not titleMedium/SemiBold, so it doesn't read as
            // an afterthought next to the much bigger "Good morning" below it.
            Text(
                "Fer",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.fillMaxWidth(),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
        item { DashboardHeader() }

        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                StatPill(Icons.Filled.LocalFireDepartment, "${historyVM.currentStreak}", "Day streak", Modifier.weight(1f))
                StatPill(Icons.Filled.CalendarMonth, "${historyVM.workoutsThisWeek}", "This week", Modifier.weight(1f))
                StatPill(Icons.Filled.EmojiEvents, "${workouts.size}", "All time", Modifier.weight(1f))
            }
        }

        if (workouts.isNotEmpty()) {
            item { WeeklyTrendCard(historyVM, weightUnit) }
        }

        item {
            Button(onClick = onStartBlank, modifier = Modifier.fillMaxWidth()) {
                Icon(Icons.Filled.AddCircle, contentDescription = null)
                Spacer(Modifier.size(8.dp))
                Text("Start Empty Workout")
            }
        }

        if (routines.isNotEmpty()) {
            item { Text("Your Routines", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold) }
            items(routines.take(3)) { routine ->
                RoutineQuickStartRow(routine) {
                    routinesVM.markUsed(routine)
                    onStartRoutine(routine)
                }
            }
        }

        workouts.firstOrNull()?.let { recent ->
            item { Text("Last Workout", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold) }
            item {
                WorkoutSummaryCard(
                    recent,
                    weightUnit,
                    modifier = Modifier.clickable { onOpenWorkout(recent) }
                )
            }
        }
    }
}

@Composable
private fun DashboardHeader() {
    val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
    val greeting = when {
        hour < 12 -> "Good morning"
        hour < 17 -> "Good afternoon"
        else -> "Good evening"
    }
    Column {
        Text(greeting, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Text(Formatters.mediumDate(java.util.Date()), color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun StatPill(icon: androidx.compose.ui.graphics.vector.ImageVector, value: String, label: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.cardStyle(padding = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun WeeklyTrendCard(historyVM: HistoryViewModel, weightUnit: WeightUnit) {
    val dailyVolume = historyVM.dailyVolume(7)
    val workoutDates = historyVM.workoutDates(7)
    val weekdayFormat = remember { java.text.SimpleDateFormat("EEEEE", java.util.Locale.getDefault()) }
    Column(modifier = Modifier.cardStyle(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("This Week", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        BarChart(
            values = dailyVolume.map { Formatters.displayValue(it.second, weightUnit) },
            xLabels = dailyVolume.map { (date, _) -> weekdayFormat.format(date) },
            activeIndicators = dailyVolume.map { (date, _) -> workoutDates.contains(date) }
        )
    }
}

@Composable
private fun RoutineQuickStartRow(routine: RoutineTemplate, onStart: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .cardStyle(padding = 12.dp)
            .clickable(onClick = onStart),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(RoutineIcons.iconFor(routine.iconName), contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        Column(modifier = Modifier.weight(1f)) {
            Text(routine.name, fontWeight = FontWeight.SemiBold)
            Text(
                "${routine.exercises.size} exercises",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Icon(Icons.Filled.PlayCircle, contentDescription = "Start", tint = MaterialTheme.colorScheme.primary)
    }
}
