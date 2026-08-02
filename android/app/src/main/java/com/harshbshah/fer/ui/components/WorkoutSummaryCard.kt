package com.harshbshah.fer.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Scale
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.harshbshah.fer.data.model.UserProfile.WeightUnit
import com.harshbshah.fer.data.model.WorkoutSession
import com.harshbshah.fer.util.Formatters

@Composable
fun WorkoutSummaryCard(
    workout: WorkoutSession,
    weightUnit: WeightUnit,
    modifier: Modifier = Modifier,
    useAbsoluteDate: Boolean = false
) {
    Column(modifier = modifier.cardStyle(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(workout.routineName, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            Text(
                if (useAbsoluteDate) Formatters.shortDate(workout.startedAt) else Formatters.relativeDate(workout.startedAt),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                style = MaterialTheme.typography.bodySmall
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            InfoChip(Icons.Filled.CheckCircle, "${workout.totalSetsCompleted} sets")
            InfoChip(
                Icons.Filled.Scale,
                "${Formatters.weight(workout.totalVolume, weightUnit)} ${weightUnit.label} vol"
            )
            InfoChip(Icons.Filled.Timer, Formatters.duration(workout.duration))
        }
    }
}

@Composable
private fun InfoChip(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String) {
    Row(
        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(14.dp)
        )
        Text(text, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
