package com.harshbshah.fer.ui.viewmodel

import androidx.lifecycle.ViewModel
import com.harshbshah.fer.nowplaying.MediaSessionNowPlayingSource
import com.harshbshah.fer.nowplaying.NowPlayingState
import kotlinx.coroutines.flow.StateFlow

class NowPlayingViewModel(private val source: MediaSessionNowPlayingSource) : ViewModel() {
    val state: StateFlow<NowPlayingState> = source.state

    fun refresh() = source.refresh()
    fun play() = source.play()
    fun pause() = source.pause()
    fun next() = source.next()
    fun previous() = source.previous()
    fun seek(progress: Float) = source.seek(progress)
    fun hasNotificationAccess() = source.hasNotificationAccess()
}
