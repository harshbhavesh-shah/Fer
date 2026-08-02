@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class, dev.chrisbanes.haze.materials.ExperimentalHazeMaterialsApi::class)

package com.harshbshah.fer.ui.activeworkout

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyItemScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Check
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
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.platform.LocalFocusManager
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
import dev.chrisbanes.haze.HazeState
import dev.chrisbanes.haze.hazeEffect
import dev.chrisbanes.haze.hazeSource
import dev.chrisbanes.haze.materials.HazeMaterials
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
    // Separate from WorkoutContent's own top-bar HazeState — this one lets the
    // Now Playing panel blur the workout screen behind it, like iOS's
    // NowPlayingView floating over a still-visible ActiveWorkoutView.
    val nowPlayingHazeState = remember { HazeState() }

    Box(modifier = Modifier.fillMaxSize()) {
        Box(modifier = Modifier.hazeSource(nowPlayingHazeState)) {
            WorkoutContent(
                viewModel = viewModel,
                weightUnit = weightUnit,
                onAddExercise = onAddExercise,
                onDiscard = { showDiscardConfirm = true },
                onFinish = { showFinishConfirm = true }
            )
        }

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
            NowPlayingPanel(viewModel = nowPlayingViewModel, hazeState = nowPlayingHazeState, onClose = { nowPlayingOpen = false })
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
        // Derived from the observed `exercises` state (not viewModel.totalSetsCompleted
        // directly) — that plain computed property gave no Compose subscription to
        // recompose on, which is why Finish stayed permanently disabled regardless
        // of what was actually checked off.
        val exercises by viewModel.exercises.collectAsStateWithLifecycle()
        val totalSets = exercises.sumOf { ex -> ex.sets.count { it.isCompleted } }
        val totalVolume = exercises.sumOf { ex -> ex.sets.filter { it.isCompleted }.sumOf { it.weight * it.reps } }
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
    val hazeState = remember { HazeState() }
    // Derived from the observed `exercises` state above, not viewModel.totalSetsCompleted
    // directly — see the matching comment on the Finish-confirmation dialog for why.
    val totalSetsCompleted = exercises.sumOf { ex -> ex.sets.count { it.isCompleted } }
    val totalVolume = exercises.sumOf { ex -> ex.sets.filter { it.isCompleted }.sumOf { it.weight * it.reps } }
    val hasCompletedSet = totalSetsCompleted > 0

    Scaffold(
        topBar = {
            WorkoutHeader(
                durationText = Formatters.duration(elapsedSeconds),
                totalVolume = totalVolume,
                weightUnit = weightUnit,
                totalSets = totalSetsCompleted,
                exerciseCount = exercises.size,
                canFinish = hasCompletedSet,
                onDiscard = onDiscard,
                onFinish = onFinish,
                hazeState = hazeState
            )
        },
        bottomBar = {
            if (isResting) RestTimerBar(viewModel)
        }
    ) { padding ->
        // contentPadding (not a wrapping Modifier.padding) so the LazyColumn's
        // pixels still render up under the transparent header for Haze to
        // blur, with items themselves visually starting below it.
        LazyColumn(
            modifier = Modifier.fillMaxSize().hazeSource(hazeState),
            contentPadding = PaddingValues(
                start = 16.dp, end = 16.dp,
                top = padding.calculateTopPadding() + 16.dp,
                bottom = padding.calculateBottomPadding() + 16.dp
            ),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item { Text(routineName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold) }

            itemsIndexed(exercises) { index, exercise ->
                ExerciseLogCard(
                    exercise = exercise,
                    weightUnit = weightUnit,
                    previousSets = viewModel.previousSets(exercise.exerciseId),
                    onAddSet = { viewModel.addSet(index) },
                    onToggleSet = { setIndex -> viewModel.toggleComplete(index, setIndex) },
                    onRemoveSet = { setIndex -> viewModel.removeSet(index, setIndex) },
                    onUpdateWeight = { setIndex, weight -> viewModel.updateWeight(index, setIndex, weight) },
                    onUpdateReps = { setIndex, reps -> viewModel.updateReps(index, setIndex, reps) },
                    onRemoveExercise = { viewModel.removeExercise(index) },
                    modifier = Modifier.animateItem()
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
    content: @Composable LazyItemScope.(Int, LoggedExercise) -> Unit
) {
    items(list.size, key = { list[it].id }) { index -> content(index, list[index]) }
}

/** Sticky header: Discard/Finish action row, plus a Duration/Volume/Sets/Exercises
 *  stats row below it — mirrors Hevy's "Log Workout" header. */
@Composable
private fun WorkoutHeader(
    durationText: String,
    totalVolume: Double,
    weightUnit: WeightUnit,
    totalSets: Int,
    exerciseCount: Int,
    canFinish: Boolean,
    onDiscard: () -> Unit,
    onFinish: () -> Unit,
    hazeState: HazeState
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .statusBarsPadding()
            .hazeEffect(state = hazeState, style = HazeMaterials.thin())
            .padding(horizontal = 16.dp, vertical = 4.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onDiscard) { Text("Discard", color = MaterialTheme.colorScheme.error) }
            Spacer(modifier = Modifier.weight(1f))
            TextButton(onClick = onFinish, enabled = canFinish) { Text("Finish", fontWeight = FontWeight.SemiBold) }
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            HeaderStat("Duration", durationText)
            HeaderStat("Volume", "${Formatters.weight(totalVolume, weightUnit)} ${weightUnit.label}")
            HeaderStat("Sets", "$totalSets")
            HeaderStat("Exercises", "$exerciseCount")
        }
    }
}

@Composable
private fun HeaderStat(label: String, value: String) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
    }
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
    previousSets: List<SetEntry>,
    onAddSet: () -> Unit,
    onToggleSet: (Int) -> Unit,
    onRemoveSet: (Int) -> Unit,
    onUpdateWeight: (Int, Double) -> Unit,
    onUpdateReps: (Int, Int) -> Unit,
    onRemoveExercise: () -> Unit,
    modifier: Modifier = Modifier
) {
    var menuExpanded by remember { mutableStateOf(false) }
    Column(
        modifier = modifier.cardStyle().animateContentSize(),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
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

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("SET", style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(0.5f))
            Text("PREVIOUS", style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(1f))
            Text("${weightUnit.label.uppercase()}", style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(0.9f))
            Text("REPS", style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(0.8f))
            Spacer(Modifier.size(32.dp))
            Spacer(Modifier.size(32.dp))
        }

        exercise.sets.forEachIndexed { index, set ->
            SetRow(
                index = index + 1,
                set = set,
                previous = previousSets.getOrNull(index),
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
    previous: SetEntry?,
    weightUnit: WeightUnit,
    onToggle: () -> Unit,
    onWeightChange: (Double) -> Unit,
    onRepsChange: (Int) -> Unit,
    onDelete: () -> Unit
) {
    var weightText by remember(set.id) { mutableStateOf(if (set.weight > 0) Formatters.weight(set.weight, weightUnit) else "") }
    var repsText by remember(set.id) { mutableStateOf(if (set.reps > 0) "${set.reps}" else "") }
    val focusManager = LocalFocusManager.current

    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier
            .fillMaxWidth()
            .background(
                if (set.isCompleted) Color(0x1F4CAF50) else Color.Transparent,
                RoundedCornerShape(10.dp)
            )
            .padding(vertical = 4.dp)
    ) {
        Text("$index", modifier = Modifier.weight(0.5f), fontWeight = FontWeight.SemiBold)

        // Last time's performance for this same set position — reference only,
        // not editable — matching Hevy's "Previous" column so entries never
        // start from a blank field.
        Text(
            if (previous != null && previous.weight > 0) {
                "${Formatters.weight(previous.weight, weightUnit)}x${previous.reps}"
            } else {
                "—"
            },
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.weight(1f)
        )

        OutlinedTextField(
            value = weightText,
            onValueChange = {
                weightText = it
                onWeightChange(Formatters.toStorageWeight(it.toDoubleOrNull() ?: 0.0, weightUnit))
            },
            modifier = Modifier.weight(0.9f),
            singleLine = true,
            placeholder = { Text("0") },
            textStyle = MaterialTheme.typography.bodyMedium,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal, imeAction = ImeAction.Next),
            keyboardActions = KeyboardActions(onNext = { focusManager.moveFocus(FocusDirection.Next) })
        )

        OutlinedTextField(
            value = repsText,
            onValueChange = {
                repsText = it
                onRepsChange(it.toIntOrNull() ?: 0)
            },
            modifier = Modifier.weight(0.8f),
            singleLine = true,
            placeholder = { Text("0") },
            textStyle = MaterialTheme.typography.bodyMedium,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
            keyboardActions = KeyboardActions(onDone = { focusManager.clearFocus() })
        )

        // A clear checkbox affordance, not a bare circle icon — the previous
        // Icons.Filled.Circle rendered as a solid gray dot for an *incomplete*
        // set, which read as "already marked" rather than "tap to complete."
        // That ambiguity was the actual reason Finish stayed disabled: sets
        // were never actually getting toggled. The scale pop on toggle gives
        // the tap a felt result beyond just the (now-correct) haptic.
        val checkScale by animateFloatAsState(
            targetValue = if (set.isCompleted) 1f else 0.85f,
            animationSpec = spring(dampingRatio = 0.5f),
            label = "checkScale"
        )
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(if (set.isCompleted) Color(0xFF43A047) else MaterialTheme.colorScheme.surfaceVariant)
                .then(
                    if (set.isCompleted) Modifier
                    else Modifier.border(1.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(8.dp))
                )
                .clickable(onClick = onToggle),
            contentAlignment = Alignment.Center
        ) {
            if (set.isCompleted) {
                Icon(
                    Icons.Filled.Check,
                    contentDescription = "Mark incomplete",
                    tint = Color.White,
                    modifier = Modifier
                        .size(18.dp)
                        .graphicsLayer(scaleX = checkScale, scaleY = checkScale)
                )
            }
        }
        IconButton(onClick = onDelete, modifier = Modifier.size(32.dp)) {
            Icon(
                Icons.Filled.Delete,
                contentDescription = "Delete set",
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}
