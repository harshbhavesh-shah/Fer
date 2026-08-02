@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.harshbshah.fer.ui.activeworkout

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.harshbshah.fer.data.model.LoggedExercise
import com.harshbshah.fer.data.model.SetEntry
import com.harshbshah.fer.data.model.UserProfile.WeightUnit
import com.harshbshah.fer.ui.components.EmptyState
import com.harshbshah.fer.ui.components.cardStyle
import com.harshbshah.fer.ui.nowplaying.NowPlayingPanel
import com.harshbshah.fer.ui.viewmodel.ActiveWorkoutViewModel
import com.harshbshah.fer.ui.viewmodel.NowPlayingViewModel
import com.harshbshah.fer.util.Formatters
import kotlinx.coroutines.launch

@Composable
fun ActiveWorkoutScreen(
    viewModel: ActiveWorkoutViewModel,
    nowPlayingViewModel: NowPlayingViewModel,
    weightUnit: WeightUnit,
    onAddExercise: () -> Unit,
    onFinished: () -> Unit,
    onDiscarded: () -> Unit
) {
    var nowPlayingOpen by remember { mutableStateOf(false) }
    var showDiscardConfirm by remember { mutableStateOf(false) }
    var showFinishConfirm by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    Box(modifier = Modifier.fillMaxSize()) {
        WorkoutContent(
            viewModel = viewModel,
            weightUnit = weightUnit,
            onAddExercise = onAddExercise,
            onDiscard = { showDiscardConfirm = true },
            onFinish = { showFinishConfirm = true }
        )

        if (!nowPlayingOpen) {
            Box(
                modifier = Modifier
                    .align(Alignment.CenterEnd)
                    .size(width = 28.dp, height = 72.dp)
                    .background(MaterialTheme.colorScheme.primary, RoundedCornerShape(topStart = 16.dp, bottomStart = 16.dp))
                    .draggable(
                        orientation = Orientation.Horizontal,
                        state = rememberDraggableState { delta -> if (delta < -8f) nowPlayingOpen = true }
                    ),
                contentAlignment = Alignment.Center
            ) {
                IconButton(onClick = { nowPlayingOpen = true }) {
                    Icon(Icons.Filled.MusicNote, contentDescription = "Now Playing", tint = Color.White)
                }
            }
        }

        AnimatedVisibility(
            visible = nowPlayingOpen,
            enter = slideInHorizontally(initialOffsetX = { it }),
            exit = slideOutHorizontally(targetOffsetX = { it })
        ) {
            NowPlayingPanel(viewModel = nowPlayingViewModel, onClose = { nowPlayingOpen = false })
        }
    }

    if (showDiscardConfirm) {
        AlertDialog(
            onDismissRequest = { showDiscardConfirm = false },
            title = { Text("Discard this workout?") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.discard()
                    showDiscardConfirm = false
                    onDiscarded()
                }) { Text("Discard Workout", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { showDiscardConfirm = false }) { Text("Keep Going") } }
        )
    }

    if (showFinishConfirm) {
        val totalSets = viewModel.totalSetsCompleted
        val totalVolume = viewModel.totalVolume
        AlertDialog(
            onDismissRequest = { showFinishConfirm = false },
            title = { Text("Finish workout?") },
            text = { Text("$totalSets sets · ${Formatters.weight(totalVolume, weightUnit)} ${weightUnit.label} total volume") },
            confirmButton = {
                TextButton(onClick = {
                    showFinishConfirm = false
                    scope.launch {
                        viewModel.finish()
                        onFinished()
                    }
                }) { Text("Finish") }
            },
            dismissButton = { TextButton(onClick = { showFinishConfirm = false }) { Text("Keep Going") } }
        )
    }
}

@Composable
private fun WorkoutContent(
    viewModel: ActiveWorkoutViewModel,
    weightUnit: WeightUnit,
    onAddExercise: () -> Unit,
    onDiscard: () -> Unit,
    onFinish: () -> Unit
) {
    val routineName by viewModel.routineName.collectAsStateWithLifecycle()
    val exercises by viewModel.exercises.collectAsStateWithLifecycle()
    val elapsedSeconds by viewModel.elapsedSeconds.collectAsStateWithLifecycle()
    val isResting by viewModel.isResting.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(Formatters.duration(elapsedSeconds), fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    TextButton(onClick = onDiscard) { Text("Discard", color = MaterialTheme.colorScheme.error) }
                },
                actions = {
                    TextButton(onClick = onFinish, enabled = viewModel.totalSetsCompleted > 0) { Text("Finish", fontWeight = FontWeight.SemiBold) }
                }
            )
        },
        bottomBar = {
            if (isResting) RestTimerBar(viewModel)
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item { Text(routineName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold) }

            itemsIndexed(exercises) { index, exercise ->
                ExerciseLogCard(
                    exercise = exercise,
                    weightUnit = weightUnit,
                    onAddSet = { viewModel.addSet(index) },
                    onToggleSet = { setIndex -> viewModel.toggleComplete(index, setIndex) },
                    onRemoveSet = { setIndex -> viewModel.removeSet(index, setIndex) },
                    onUpdateWeight = { setIndex, weight -> viewModel.updateWeight(index, setIndex, weight) },
                    onUpdateReps = { setIndex, reps -> viewModel.updateReps(index, setIndex, reps) },
                    onRemoveExercise = { viewModel.removeExercise(index) }
                )
            }

            item {
                Button(onClick = onAddExercise, modifier = Modifier.fillMaxWidth()) {
                    Icon(Icons.Filled.AddCircle, contentDescription = null)
                    Text("  Add Exercise")
                }
            }

            if (exercises.isEmpty()) {
                item {
                    EmptyState(
                        icon = Icons.Filled.AddCircle,
                        title = "Add your first exercise",
                        message = "Tap below to pick something from the library."
                    )
                }
            }
        }
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.itemsIndexed(
    list: List<LoggedExercise>,
    content: @Composable (Int, LoggedExercise) -> Unit
) {
    items(list.size, key = { list[it].id }) { index -> content(index, list[index]) }
}

@Composable
private fun RestTimerBar(viewModel: ActiveWorkoutViewModel) {
    val remaining by viewModel.restRemaining.collectAsStateWithLifecycle()
    val total by viewModel.restTotal.collectAsStateWithLifecycle()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.primary)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text("Resting", color = MaterialTheme.colorScheme.onPrimary, style = MaterialTheme.typography.labelMedium)
            Text(
                Formatters.duration(remaining.toLong()),
                color = MaterialTheme.colorScheme.onPrimary,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            TextButton(onClick = { viewModel.addRestTime(15) }) {
                Text("+15s", color = MaterialTheme.colorScheme.onPrimary)
            }
            TextButton(onClick = { viewModel.skipRest() }) {
                Text("Skip", color = MaterialTheme.colorScheme.onPrimary)
            }
        }
    }
}

@Composable
private fun ExerciseLogCard(
    exercise: LoggedExercise,
    weightUnit: WeightUnit,
    onAddSet: () -> Unit,
    onToggleSet: (Int) -> Unit,
    onRemoveSet: (Int) -> Unit,
    onUpdateWeight: (Int, Double) -> Unit,
    onUpdateReps: (Int, Int) -> Unit,
    onRemoveExercise: () -> Unit
) {
    var menuExpanded by remember { mutableStateOf(false) }
    Column(modifier = Modifier.cardStyle(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(exercise.exerciseName, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
            Box {
                IconButton(onClick = { menuExpanded = true }) {
                    Icon(Icons.Filled.MoreVert, contentDescription = "More", tint = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                DropdownMenu(expanded = menuExpanded, onDismissRequest = { menuExpanded = false }) {
                    DropdownMenuItem(
                        text = { Text("Remove Exercise") },
                        leadingIcon = { Icon(Icons.Filled.Delete, contentDescription = null) },
                        onClick = { menuExpanded = false; onRemoveExercise() }
                    )
                }
            }
        }

        Row {
            Text("SET", style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(0.6f))
            Text("WEIGHT (${weightUnit.label.uppercase()})", style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(1.4f))
            Text("REPS", style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(1f))
            Spacer(Modifier.size(36.dp))
        }

        exercise.sets.forEachIndexed { index, set ->
            SetRow(
                index = index + 1,
                set = set,
                weightUnit = weightUnit,
                onToggle = { onToggleSet(index) },
                onWeightChange = { onUpdateWeight(index, it) },
                onRepsChange = { onUpdateReps(index, it) },
                onDelete = { onRemoveSet(index) }
            )
        }

        TextButton(onClick = onAddSet) {
            Icon(Icons.Filled.AddCircle, contentDescription = null)
            Text("  Add Set")
        }
    }
}

@Composable
private fun SetRow(
    index: Int,
    set: SetEntry,
    weightUnit: WeightUnit,
    onToggle: () -> Unit,
    onWeightChange: (Double) -> Unit,
    onRepsChange: (Int) -> Unit,
    onDelete: () -> Unit
) {
    var weightText by remember(set.id) { mutableStateOf(if (set.weight > 0) Formatters.weight(set.weight, weightUnit) else "") }
    var repsText by remember(set.id) { mutableStateOf(if (set.reps > 0) "${set.reps}" else "") }

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .background(
                if (set.isCompleted) Color(0x1F4CAF50) else Color.Transparent,
                RoundedCornerShape(10.dp)
            )
            .padding(vertical = 4.dp)
    ) {
        Text("$index", modifier = Modifier.weight(0.6f), fontWeight = FontWeight.SemiBold)

        OutlinedTextField(
            value = weightText,
            onValueChange = {
                weightText = it
                onWeightChange(Formatters.toStorageWeight(it.toDoubleOrNull() ?: 0.0, weightUnit))
            },
            modifier = Modifier.weight(1.4f).padding(end = 4.dp),
            singleLine = true,
            placeholder = { Text("0") }
        )

        OutlinedTextField(
            value = repsText,
            onValueChange = {
                repsText = it
                onRepsChange(it.toIntOrNull() ?: 0)
            },
            modifier = Modifier.weight(1f).padding(end = 4.dp),
            singleLine = true,
            placeholder = { Text("0") }
        )

        IconButton(onClick = onToggle, modifier = Modifier.size(36.dp)) {
            Icon(
                if (set.isCompleted) Icons.Filled.CheckCircle else Icons.Filled.Circle,
                contentDescription = "Toggle complete",
                tint = if (set.isCompleted) Color(0xFF43A047) else MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        IconButton(onClick = onDelete, modifier = Modifier.size(36.dp)) {
            Icon(Icons.Filled.Delete, contentDescription = "Delete set", tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
