package com.harshbshah.fer.util

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.harshbshah.fer.data.model.UserProfile.WeightUnit
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

private val Context.dataStore by preferencesDataStore(name = "fer_settings")

/**
 * Device-local user preferences (not synced to Firestore — mirrors
 * `Fer/Utilities/SettingsStore.swift`; these affect only how this device
 * displays/enters data, not the underlying model).
 */
class SettingsStore(private val context: Context) {
    private val scope = CoroutineScope(Dispatchers.IO)

    private object Keys {
        val weightUnit = stringPreferencesKey("settings.weightUnit")
        val defaultRestSeconds = intPreferencesKey("settings.defaultRestSeconds")
    }

    private val _weightUnit = MutableStateFlow(WeightUnit.lb)
    val weightUnit: StateFlow<WeightUnit> = _weightUnit

    private val _defaultRestSeconds = MutableStateFlow(90)
    val defaultRestSeconds: StateFlow<Int> = _defaultRestSeconds

    init {
        scope.launch {
            val prefs = context.dataStore.data.first()
            prefs[Keys.weightUnit]?.let { raw ->
                runCatching { WeightUnit.valueOf(raw) }.getOrNull()?.let { _weightUnit.value = it }
            }
            prefs[Keys.defaultRestSeconds]?.let { _defaultRestSeconds.value = it }
        }
    }

    fun setWeightUnit(unit: WeightUnit) {
        _weightUnit.value = unit
        scope.launch { context.dataStore.edit { it[Keys.weightUnit] = unit.name } }
    }

    fun setDefaultRestSeconds(seconds: Int) {
        _defaultRestSeconds.value = seconds
        scope.launch { context.dataStore.edit { it[Keys.defaultRestSeconds] = seconds } }
    }
}
