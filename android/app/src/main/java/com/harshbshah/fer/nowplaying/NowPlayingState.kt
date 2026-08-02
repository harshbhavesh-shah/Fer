package com.harshbshah.fer.nowplaying

import android.graphics.Bitmap

data class NowPlayingState(
    val title: String = "",
    val artist: String = "",
    val artwork: Bitmap? = null,
    val isPlaying: Boolean = false,
    val elapsedMs: Long = 0,
    val durationMs: Long = 0,
    val isAvailable: Boolean = false
)
