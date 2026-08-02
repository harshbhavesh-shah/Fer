package com.harshbshah.fer.ui.theme

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.ViewList
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Routine icons are stored as iOS SF Symbol names (see RoutineTemplate.iconName)
 * so a routine created on either platform shows a matching icon on both. This
 * maps the small fixed set offered by the routine editor to Material icons.
 */
object RoutineIcons {
    val options = listOf(
        "list.bullet.rectangle",
        "flame.fill",
        "bolt.fill",
        "figure.strengthtraining.traditional",
        "figure.run"
    )

    fun iconFor(sfSymbolName: String): ImageVector = when (sfSymbolName) {
        "flame.fill" -> Icons.Filled.LocalFireDepartment
        "bolt.fill" -> Icons.Filled.Bolt
        "figure.strengthtraining.traditional" -> Icons.Filled.FitnessCenter
        "figure.run" -> Icons.Filled.DirectionsRun
        else -> Icons.Filled.ViewList
    }
}
