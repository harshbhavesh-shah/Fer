@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class, dev.chrisbanes.haze.materials.ExperimentalHazeMaterialsApi::class)

package com.harshbshah.fer.ui.routines

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.harshbshah.fer.data.ExerciseLibrary
import com.harshbshah.fer.data.model.Exercise
import com.harshbshah.fer.data.model.MuscleGroup
import dev.chrisbanes.haze.HazeState
import dev.chrisbanes.haze.hazeEffect
import dev.chrisbanes.haze.hazeSource
import dev.chrisbanes.haze.materials.HazeMaterials

@Composable
fun ExercisePickerScreen(onPick: (Exercise) -> Unit, onClose: () -> Unit) {
    var search by remember { mutableStateOf("") }
    var selectedMuscle by remember { mutableStateOf<MuscleGroup?>(null) }
    val hazeState = remember { HazeState() }

    val filtered = remember(search, selectedMuscle) {
        ExerciseLibrary.all.filter { exercise ->
            val matchesSearch = search.isBlank() || exercise.name.contains(search, ignoreCase = true)
            val matchesMuscle = selectedMuscle == null || exercise.primaryMuscle == selectedMuscle
            matchesSearch && matchesMuscle
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Add Exercise") },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent),
                modifier = Modifier.hazeEffect(state = hazeState, style = HazeMaterials.thin())
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .hazeSource(hazeState)
                .padding(top = padding.calculateTopPadding(), bottom = padding.calculateBottomPadding())
        ) {
            OutlinedTextField(
                value = search,
                onValueChange = { search = it },
                label = { Text("Search exercises") },
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                singleLine = true
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip("All", selectedMuscle == null) { selectedMuscle = null }
                MuscleGroup.entries.forEach { muscle ->
                    FilterChip(muscle.displayName, selectedMuscle == muscle) { selectedMuscle = muscle }
                }
            }

            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(filtered, key = { it.id }) { exercise ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onPick(exercise); onClose() }
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(Icons.Filled.FitnessCenter, contentDescription = null, tint = exercise.primaryMuscle.accentColor)
                        Column {
                            Text(exercise.name)
                            Text(
                                exercise.primaryMuscle.displayName,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun FilterChip(title: String, isSelected: Boolean, onClick: () -> Unit) {
    Surface(
        shape = RoundedCornerShape(50),
        color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
        modifier = Modifier.clickable(onClick = onClick)
    ) {
        Text(
            title,
            color = if (isSelected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
            style = MaterialTheme.typography.labelMedium
        )
    }
}
