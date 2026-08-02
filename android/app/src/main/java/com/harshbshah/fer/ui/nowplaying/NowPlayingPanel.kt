package com.harshbshah.fer.ui.nowplaying

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.SkipPrevious
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.harshbshah.fer.ui.viewmodel.NowPlayingViewModel
import com.harshbshah.fer.util.Formatters

@Composable
fun NowPlayingPanel(viewModel: NowPlayingViewModel, onClose: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    LaunchedEffect(Unit) { viewModel.refresh() }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF141416))
    ) {
        Column(modifier = Modifier.fillMaxSize().padding(horizontal = 32.dp)) {
            Row(modifier = Modifier.fillMaxWidth().padding(top = 12.dp)) {
                IconButton(onClick = onClose) {
                    Icon(Icons.Filled.ChevronRight, contentDescription = "Close", tint = Color.White.copy(alpha = 0.8f))
                }
            }

            Column(
                modifier = Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                if (state.isAvailable) {
                    Box(
                        modifier = Modifier
                            .size(260.dp)
                            .clip(RoundedCornerShape(20.dp))
                            .background(Color.White.copy(alpha = 0.1f)),
                        contentAlignment = Alignment.Center
                    ) {
                        val artwork = state.artwork
                        if (artwork != null) {
                            Image(artwork.asImageBitmap(), contentDescription = null, modifier = Modifier.fillMaxSize())
                        } else {
                            Icon(Icons.Filled.MusicNote, contentDescription = null, tint = Color.White.copy(alpha = 0.5f), modifier = Modifier.size(60.dp))
                        }
                    }
                    Spacer(Modifier.height(24.dp))
                    Text(state.title, color = Color.White, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, maxLines = 1)
                    Text(state.artist, color = Color.White.copy(alpha = 0.7f), maxLines = 1)
                    Spacer(Modifier.height(16.dp))

                    val progress = if (state.durationMs > 0) (state.elapsedMs.toFloat() / state.durationMs) else 0f
                    LinearProgressIndicator(
                        progress = { progress.coerceIn(0f, 1f) },
                        modifier = Modifier.fillMaxWidth(),
                        color = Color.White,
                        trackColor = Color.White.copy(alpha = 0.2f)
                    )
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(Formatters.duration(state.elapsedMs / 1000), color = Color.White.copy(alpha = 0.6f), style = MaterialTheme.typography.labelSmall)
                        Text(Formatters.duration(state.durationMs / 1000), color = Color.White.copy(alpha = 0.6f), style = MaterialTheme.typography.labelSmall)
                    }

                    Spacer(Modifier.height(20.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(44.dp), verticalAlignment = Alignment.CenterVertically) {
                        IconButton(onClick = { viewModel.previous() }) {
                            Icon(Icons.Filled.SkipPrevious, contentDescription = "Previous", tint = Color.White, modifier = Modifier.size(32.dp))
                        }
                        IconButton(onClick = { if (state.isPlaying) viewModel.pause() else viewModel.play() }) {
                            Icon(
                                if (state.isPlaying) Icons.Filled.Pause else Icons.Filled.PlayCircle,
                                contentDescription = "Play/Pause",
                                tint = Color.White,
                                modifier = Modifier.size(56.dp)
                            )
                        }
                        IconButton(onClick = { viewModel.next() }) {
                            Icon(Icons.Filled.SkipNext, contentDescription = "Next", tint = Color.White, modifier = Modifier.size(32.dp))
                        }
                    }
                } else {
                    Icon(Icons.Filled.MusicNote, contentDescription = null, tint = Color.White.copy(alpha = 0.5f), modifier = Modifier.size(44.dp))
                    Spacer(Modifier.height(12.dp))
                    Text("Nothing playing", color = Color.White, fontWeight = FontWeight.Bold)
                    if (!viewModel.hasNotificationAccess()) {
                        Text(
                            "Grant Now Playing access in Settings to see what's playing here.",
                            color = Color.White.copy(alpha = 0.7f),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }

            Text(
                "Swipe right to go back to your workout",
                color = Color.White.copy(alpha = 0.6f),
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.padding(bottom = 20.dp).align(Alignment.CenterHorizontally)
            )
        }
    }
}
