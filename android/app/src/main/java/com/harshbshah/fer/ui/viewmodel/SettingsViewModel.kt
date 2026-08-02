package com.harshbshah.fer.ui.viewmodel

import androidx.lifecycle.ViewModel
import com.harshbshah.fer.data.model.UserProfile.WeightUnit
import com.harshbshah.fer.data.repository.AuthRepository
import com.harshbshah.fer.nowplaying.MediaSessionNowPlayingSource
import com.harshbshah.fer.util.Haptics
import com.harshbshah.fer.util.SettingsStore
import kotlinx.coroutines.flow.StateFlow

class SettingsViewModel(
    private val authRepository: AuthRepository,
    private val settingsStore: SettingsStore,
    private val nowPlayingSource: MediaSessionNowPlayingSource
) : ViewModel() {
    val currentUser = authRepository.currentUser
    val weightUnit: StateFlow<WeightUnit> = settingsStore.weightUnit
    val defaultRestSeconds: StateFlow<Int> = settingsStore.defaultRestSeconds

    fun setWeightUnit(unit: WeightUnit) {
        settingsStore.setWeightUnit(unit)
        Haptics.selection()
    }

    fun setDefaultRestSeconds(seconds: Int) {
        settingsStore.setDefaultRestSeconds(seconds)
        Haptics.selection()
    }

    fun hasNowPlayingAccess() = nowPlayingSource.hasNotificationAccess()

    fun signOut() {
        Haptics.medium()
        authRepository.signOut()
    }
}
