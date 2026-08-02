package com.harshbshah.fer.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.CreationExtras
import com.harshbshah.fer.AppContainer

/** Small manual factory — mirrors each screen owning its ViewModel(s) like the SwiftUI @StateObjects. */
class ViewModelFactory(private val container: AppContainer) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T {
        @Suppress("UNCHECKED_CAST")
        return when (modelClass) {
            AuthViewModel::class.java -> AuthViewModel(container.authRepository) as T
            RoutinesViewModel::class.java -> RoutinesViewModel(container.firestoreRepository) as T
            HistoryViewModel::class.java -> HistoryViewModel(container.firestoreRepository) as T
            SettingsViewModel::class.java -> SettingsViewModel(container.authRepository, container.settingsStore, container.nowPlayingSource) as T
            NowPlayingViewModel::class.java -> NowPlayingViewModel(container.nowPlayingSource) as T
            else -> throw IllegalArgumentException("Unknown ViewModel class: $modelClass")
        }
    }
}
