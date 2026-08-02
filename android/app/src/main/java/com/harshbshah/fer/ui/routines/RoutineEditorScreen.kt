@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class, dev.chrisbanes.haze.materials.ExperimentalHazeMaterialsApi::class)

package com.harshbshah.fer.ui.routines

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.harshbshah.fer.data.model.RoutineExercise
import com.harshbshah.fer.data.model.RoutineTemplate
import com.harshbshah.fer.ui.theme.RoutineIcons
import com.harshbshah.fer.ui.viewmodel.RoutinesViewModel
import dev.chrisbanes.haze.HazeState
import dev.chrisbanes.haze.hazeEffect
import dev.chrisbanes.haze.hazeSource
import dev.chrisbanes.haze.materials.HazeMaterials

@Composable
fun RoutineEditorScreen(
    viewModel: RoutinesViewModel,
    initialRoutine: RoutineTemplate,
    defaultRestSeconds: Int,
    onPickExercise: (onPicked: (com.harshbshah.fer.data.model.Exercise) -> Unit) -> Unit,
    onClose: () -> Unit
) {
    var routine by remember { mutableStateOf(initialRoutine) }
    val hazeState = remember { HazeState() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (initialRoutine.id == null) "New Routine" else "Edit Routine") },
                navigationIcon = { TextButton(onClick = onClose) { Text("Cancel") } },
                actions = {
                    TextButton(
                        onClick = {
                            viewModel.save(routine)
                            onClose()
                        },
                        enabled = routine.name.isNotBlank()
                    ) { Text("Save") }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent),
                modifier = Modifier.hazeEffect(state = hazeState, style = HazeMaterials.thin())
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().hazeSource(hazeState),
            contentPadding = PaddingValues(
                start = 16.dp, end = 16.dp,
                top = padding.calculateTopPadding() + 16.dp,
                bottom = padding.calculateBottomPadding() + 16.dp
            ),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                OutlinedTextField(
                    value = routine.name,
                    onValueChange = { routine = routine.copy(name = it) },
                    label = { Text("Routine name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
            item {
                Row(
                    modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    RoutineIcons.options.forEach { icon ->
                        val selected = routine.iconName == icon
                        Icon(
                            RoutineIcons.iconFor(icon),
                            contentDescription = null,
                            tint = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(4.dp)
                        )
                    }
                }
            }

            item {
                Text("Exercises", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            }

            items(routine.exercises, key = { it.id }) { item ->
                RoutineExerciseRow(
                    item = item,
                    onChange = { updated ->
                        routine = routine.copy(exercises = routine.exercises.map { if (it.id == item.id) updated else it })
                    },
                    onDelete = {
                        routine = routine.copy(exercises = routine.exercises.filter { it.id != item.id })
                    }
                )
                HorizontalDivider()
            }

            item {
                Button(onClick = {
                    onPickExercise { exercise ->
                        routine = routine.copy(
                            exercises = routine.exercises + RoutineExercise(
                                exerciseId = exercise.id,
                                exerciseName = exercise.name,
                                restSeconds = defaultRestSeconds
                            )
                        )
                    }
                }, modifier = Modifier.fillMaxWidth()) {
                    Icon(Icons.Filled.Add, contentDescription = null)
                    Text("  Add Exercise")
                }
            }

            if (initialRoutine.id != null) {
                item {
                    Button(
                        onClick = { viewModel.delete(routine); onClose() },
                        colors = androidx.compose.material3.ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Delete Routine")
                    }
                }
            }
        }
    }
}

@Composable
private fun RoutineExerciseRow(item: RoutineExercise, onChange: (RoutineExercise) -> Unit, onDelete: () -> Unit) {
    Column(modifier = Modifier.padding(vertical = 4.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(item.exerciseName, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            IconButton(onClick = onDelete) { Icon(Icons.Filled.Delete, contentDescription = "Remove") }
        }
        Stepper("Sets", item.targetSets, 1..10) { onChange(item.copy(targetSets = it)) }
        Stepper("Reps", item.targetReps, 1..30) { onChange(item.copy(targetReps = it)) }
        Stepper("Rest (s)", item.restSeconds, 15..300, step = 15) { onChange(item.copy(restSeconds = it)) }
    }
}

@Composable
private fun Stepper(label: String, value: Int, range: IntRange, step: Int = 1, onChange: (Int) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        Text("$label: $value", modifier = Modifier.weight(1f))
        IconButton(onClick = { onChange((value - step).coerceIn(range)) }) { Icon(Icons.Filled.Remove, contentDescription = "Decrease $label") }
        IconButton(onClick = { onChange((value + step).coerceIn(range)) }) { Icon(Icons.Filled.Add, contentDescription = "Increase $label") }
    }
}
