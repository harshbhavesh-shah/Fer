@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.harshbshah.fer.ui.settings

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.Scale
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.harshbshah.fer.data.model.UserProfile.WeightUnit
import com.harshbshah.fer.ui.components.cardStyle
import com.harshbshah.fer.ui.theme.ferGradient
import com.harshbshah.fer.ui.viewmodel.SettingsViewModel

@Composable
fun SettingsScreen(viewModel: SettingsViewModel, bottomContentPadding: Dp = 0.dp) {
    val currentUser by viewModel.currentUser.collectAsStateWithLifecycle()
    val weightUnit by viewModel.weightUnit.collectAsStateWithLifecycle()
    val defaultRestSeconds by viewModel.defaultRestSeconds.collectAsStateWithLifecycle()
    var showSignOutConfirm by remember { mutableStateOf(false) }
    val context = LocalContext.current

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
            .padding(bottom = bottomContentPadding),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        ProfileHeader(name = currentUser?.displayName, email = currentUser?.email)

        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                "Preferences",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 4.dp, bottom = 4.dp)
            )

            Column(modifier = Modifier.cardStyle(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Scale, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.size(12.dp))
                    Text("Weight Unit", modifier = Modifier.weight(1f))
                    SingleChoiceSegmentedButtonRow {
                        WeightUnit.entries.forEachIndexed { index, unit ->
                            SegmentedButton(
                                selected = weightUnit == unit,
                                onClick = { viewModel.setWeightUnit(unit) },
                                shape = androidx.compose.material3.SegmentedButtonDefaults.itemShape(index, WeightUnit.entries.size)
                            ) { Text(unit.label.uppercase()) }
                        }
                    }
                }

                HorizontalDivider()

                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Timer, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                        Spacer(Modifier.size(12.dp))
                        Text("Default Rest Time", modifier = Modifier.weight(1f))
                        Text("${defaultRestSeconds}s", fontWeight = FontWeight.SemiBold)
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf(30, 60, 90, 120, 180).forEach { seconds ->
                            val selected = defaultRestSeconds == seconds
                            Text(
                                "${seconds}s",
                                modifier = Modifier
                                    .clip(androidx.compose.foundation.shape.RoundedCornerShape(50))
                                    .clickable { viewModel.setDefaultRestSeconds(seconds) }
                                    .background(
                                        if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
                                        androidx.compose.foundation.shape.RoundedCornerShape(50)
                                    )
                                    .padding(horizontal = 14.dp, vertical = 8.dp),
                                color = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                HorizontalDivider()

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.MusicNote, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.size(12.dp))
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text("Now Playing Access")
                        Text(
                            if (viewModel.hasNowPlayingAccess()) "Enabled" else "Grant access to show now-playing during workouts",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    if (!viewModel.hasNowPlayingAccess()) {
                        TextButton(onClick = { openNotificationAccessSettings(context) }) { Text("Grant") }
                    }
                }
            }
        }

        Button(
            onClick = { showSignOutConfirm = true },
            colors = androidx.compose.material3.ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(Icons.Filled.Logout, contentDescription = null)
            Text("  Sign Out")
        }

        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Info, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.size(8.dp))
            Text("Version", modifier = Modifier.weight(1f))
            Text("1.0.0", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }

    if (showSignOutConfirm) {
        AlertDialog(
            onDismissRequest = { showSignOutConfirm = false },
            title = { Text("Sign out of Fer?") },
            confirmButton = {
                TextButton(onClick = {
                    showSignOutConfirm = false
                    viewModel.signOut()
                }) { Text("Sign Out", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { showSignOutConfirm = false }) { Text("Cancel") } }
        )
    }
}

private fun openNotificationAccessSettings(context: Context) {
    val intent = android.content.Intent(android.provider.Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
    context.startActivity(intent)
}

@Composable
private fun ProfileHeader(name: String?, email: String?) {
    val initials = remember(name, email) {
        if (!name.isNullOrBlank()) {
            name.split(" ").take(2).mapNotNull { it.firstOrNull() }.joinToString("").uppercase()
        } else {
            email?.firstOrNull()?.uppercase() ?: "?"
        }
    }
    Row(modifier = Modifier.cardStyle(), verticalAlignment = Alignment.CenterVertically) {
        Column(
            modifier = Modifier
                .size(56.dp)
                .background(ferGradient(MaterialTheme.colorScheme.primary), CircleShape),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(initials, color = MaterialTheme.colorScheme.onPrimary, fontWeight = FontWeight.Bold)
        }
        Spacer(Modifier.size(16.dp))
        Column {
            if (!name.isNullOrBlank()) Text(name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            if (!email.isNullOrBlank()) Text(email, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
