package com.harshbshah.fer

import android.content.Context
import com.harshbshah.fer.data.repository.AuthRepository
import com.harshbshah.fer.data.repository.FirestoreRepository
import com.harshbshah.fer.nowplaying.MediaSessionNowPlayingSource
import com.harshbshah.fer.util.Haptics
import com.harshbshah.fer.util.SettingsStore

/** Hand-rolled DI container — no Hilt dependency, kept intentionally small. */
class AppContainer(context: Context) {
    val firestoreRepository = FirestoreRepository()
    val authRepository = AuthRepository(firestoreRepository)
    val settingsStore = SettingsStore(context)
    val nowPlayingSource = MediaSessionNowPlayingSource(context)

    init {
        Haptics.init(context)
    }
}
