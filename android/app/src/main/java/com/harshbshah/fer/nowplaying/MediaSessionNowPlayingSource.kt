package com.harshbshah.fer.nowplaying

import android.content.ComponentName
import android.content.Context
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.provider.Settings
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Unified "whatever is playing" facade — Android equivalent of iOS's
 * NowPlayingManager. Works with any app that publishes a MediaSession
 * (Spotify, YouTube Music, etc.) via the system's active-media-sessions API,
 * gated by the same notification-listener access granted once in Settings.
 */
class MediaSessionNowPlayingSource(private val context: Context) {
    private val _state = MutableStateFlow(NowPlayingState())
    val state: StateFlow<NowPlayingState> = _state

    private var activeController: MediaController? = null

    private val componentName: ComponentName
        get() = ComponentName(context, NowPlayingListenerService::class.java)

    fun hasNotificationAccess(): Boolean {
        val enabled = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners") ?: ""
        return enabled.contains(context.packageName)
    }

    fun notificationAccessSettingsIntent() =
        android.content.Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)

    private val sessionCallback = object : MediaController.Callback() {
        override fun onPlaybackStateChanged(state: PlaybackState?) = refresh()
        override fun onMetadataChanged(metadata: MediaMetadata?) = refresh()
        override fun onSessionDestroyed() = refreshFromManager()
    }

    /** Call when the Now Playing panel opens, or from Settings after granting access. */
    fun refresh() {
        if (!hasNotificationAccess()) {
            _state.value = NowPlayingState(isAvailable = false)
            return
        }
        refreshFromManager()
    }

    private fun refreshFromManager() {
        val manager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
        val sessions = try {
            manager.getActiveSessions(componentName)
        } catch (e: SecurityException) {
            emptyList()
        }
        val controller = sessions.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING }
            ?: sessions.firstOrNull()

        activeController?.unregisterCallback(sessionCallback)
        activeController = controller
        controller?.registerCallback(sessionCallback)

        if (controller == null) {
            _state.value = NowPlayingState(isAvailable = false)
            return
        }
        applyState(controller)
    }

    private fun applyState(controller: MediaController) {
        val metadata = controller.metadata
        val playback = controller.playbackState
        _state.value = NowPlayingState(
            title = metadata?.getString(MediaMetadata.METADATA_KEY_TITLE) ?: "",
            artist = metadata?.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: "",
            artwork = metadata?.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
                ?: metadata?.getBitmap(MediaMetadata.METADATA_KEY_ART),
            isPlaying = playback?.state == PlaybackState.STATE_PLAYING,
            elapsedMs = playback?.position ?: 0,
            durationMs = metadata?.getLong(MediaMetadata.METADATA_KEY_DURATION) ?: 0,
            isAvailable = true
        )
    }

    fun play() = activeController?.transportControls?.play() ?: Unit
    fun pause() = activeController?.transportControls?.pause() ?: Unit
    fun next() = activeController?.transportControls?.skipToNext() ?: Unit
    fun previous() = activeController?.transportControls?.skipToPrevious() ?: Unit
    fun seek(progress: Float) {
        val duration = _state.value.durationMs
        activeController?.transportControls?.seekTo((duration * progress).toLong())
    }
}
