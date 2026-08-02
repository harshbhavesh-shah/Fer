package com.harshbshah.fer.ui.exercises

import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.harshbshah.fer.data.ExerciseLibrary
import com.harshbshah.fer.data.model.Exercise
import com.harshbshah.fer.data.model.MuscleGroup
import com.harshbshah.fer.ui.components.DonutChart
import com.harshbshah.fer.ui.components.cardStyle
import com.harshbshah.fer.ui.routines.FilterChip
import com.harshbshah.fer.ui.viewmodel.HistoryViewModel

@Composable
fun ExerciseLibraryScreen(
    historyVM: HistoryViewModel,
    bottomContentPadding: Dp = 0.dp,
    onOpenExercise: (Exercise) -> Unit
) {
    var search by remember { mutableStateOf("") }
    var selectedMuscle by remember { mutableStateOf<MuscleGroup?>(null) }

    val filtered = remember(search, selectedMuscle) {
        ExerciseLibrary.all.filter { exercise ->
            val matchesSearch = search.isBlank() || exercise.name.contains(search, ignoreCase = true)
            val matchesMuscle = selectedMuscle == null || exercise.primaryMuscle == selectedMuscle
            matchesSearch && matchesMuscle
        }
    }

    val breakdown = historyVM.volumeByMuscleGroup().take(6)

    Column(modifier = Modifier.fillMaxSize()) {
        OutlinedTextField(
            value = search,
            onValueChange = { search = it },
            label = { Text("Search exercises") },
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            singleLine = true
        )

        if (breakdown.isNotEmpty() && search.isBlank()) {
            MuscleBreakdownCard(breakdown, Modifier.padding(horizontal = 16.dp, vertical = 4.dp))
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            FilterChip("All", selectedMuscle == null) { selectedMuscle = null }
            MuscleGroup.entries.forEach { muscle ->
                FilterChip(muscle.displayName, selectedMuscle == muscle) { selectedMuscle = muscle }
            }
        }

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = bottomContentPadding)
        ) {
            itemsIndexed(filtered, key = { _, exercise -> exercise.id }) { index, exercise ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onOpenExercise(exercise) }
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(Icons.Filled.FitnessCenter, contentDescription = null, tint = exercise.primaryMuscle.accentColor)
                    Column(modifier = Modifier.weight(1f)) {
                        Text(exercise.name)
                        Text(
                            exercise.primaryMuscle.displayName,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Icon(
                        Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                if (index < filtered.lastIndex) {
                    HorizontalDivider(modifier = Modifier.padding(start = 52.dp))
                }
            }
        }
    }
}

@Composable
private fun MuscleBreakdownCard(breakdown: List<Pair<MuscleGroup, Double>>, modifier: Modifier = Modifier) {
    Column(modifier = modifier.cardStyle(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Volume by Muscle Group", style = MaterialTheme.typography.titleMedium)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(20.dp)) {
            DonutChart(
                slices = breakdown.map { it.second to it.first.accentColor },
                modifier = Modifier.size(110.dp).padding(4.dp)
            )
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                breakdown.forEach { (muscle, _) ->
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Icon(Icons.Filled.FitnessCenter, contentDescription = null, tint = muscle.accentColor, modifier = Modifier.size(8.dp))
                        Text(muscle.displayName, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
    }
}
