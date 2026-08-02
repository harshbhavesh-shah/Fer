package com.harshbshah.fer.nowplaying

import android.service.notification.NotificationListenerService

/**
 * No logic needed here beyond existing and being declared in the manifest —
 * once the user grants notification-listener access in system settings (see
 * Settings screen), MediaSessionNowPlayingSource can call
 * MediaSessionManager.getActiveSessions(ComponentName(this app, this class))
 * from anywhere in the app, which is what actually reads now-playing state.
 */
class NowPlayingListenerService : NotificationListenerService()
