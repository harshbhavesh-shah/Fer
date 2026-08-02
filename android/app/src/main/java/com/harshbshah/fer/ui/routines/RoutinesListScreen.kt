package com.harshbshah.fer.ui.routines

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.ListAlt
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.harshbshah.fer.data.model.RoutineTemplate
import com.harshbshah.fer.ui.components.EmptyState
import com.harshbshah.fer.ui.components.cardStyle
import com.harshbshah.fer.ui.theme.RoutineIcons
import com.harshbshah.fer.ui.viewmodel.RoutinesViewModel

@Composable
fun RoutinesListScreen(
    viewModel: RoutinesViewModel,
    onStart: (RoutineTemplate) -> Unit,
    onEdit: (RoutineTemplate) -> Unit
) {
    val routines by viewModel.routines.collectAsStateWithLifecycle()

    Box(modifier = Modifier.fillMaxSize()) {
        if (routines.isEmpty()) {
            EmptyState(
                icon = Icons.Filled.ListAlt,
                title = "No routines yet",
                message = "Create a routine template so you can start a workout in one tap.",
                modifier = Modifier.align(Alignment.Center)
            )
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(routines, key = { it.id ?: it.name }) { routine ->
                    RoutineCard(
                        routine = routine,
                        onStart = {
                            viewModel.markUsed(routine)
                            onStart(routine)
                        },
                        onEdit = { onEdit(routine) },
                        onDelete = { viewModel.delete(routine) }
                    )
                }
            }
        }
    }
}

@Composable
private fun RoutineCard(
    routine: RoutineTemplate,
    onStart: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    var menuExpanded by remember { mutableStateOf(false) }
    Column(modifier = Modifier.cardStyle(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(RoutineIcons.iconFor(routine.iconName), contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.size(8.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(routine.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(
                    "${routine.exercises.size} exercises",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Box {
                IconButton(onClick = { menuExpanded = true }) {
                    Icon(Icons.Filled.MoreVert, contentDescription = "More")
                }
                DropdownMenu(expanded = menuExpanded, onDismissRequest = { menuExpanded = false }) {
                    DropdownMenuItem(
                        text = { Text("Edit") },
                        leadingIcon = { Icon(Icons.Filled.Edit, contentDescription = null) },
                        onClick = { menuExpanded = false; onEdit() }
                    )
                    DropdownMenuItem(
                        text = { Text("Delete") },
                        leadingIcon = { Icon(Icons.Filled.Delete, contentDescription = null) },
                        onClick = { menuExpanded = false; onDelete() }
                    )
                }
            }
        }

        if (routine.exercises.isNotEmpty()) {
            Text(
                routine.exercises.joinToString(" · ") { it.exerciseName },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 2
            )
        }

        Button(onClick = onStart, modifier = Modifier.fillMaxWidth()) {
            Icon(Icons.Filled.PlayArrow, contentDescription = null)
            Spacer(Modifier.size(6.dp))
            Text("Start Workout")
        }
    }
}
