package com.harshbshah.fer.util

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Thin vibration wrapper — call sites mirror iOS's Haptics.swift (light/medium/success/etc).
 *
 * Uses the OS's predefined, motor-tuned effects (VibrationEffect.createPredefined,
 * API 29+) rather than raw createOneShot durations — a handful of milliseconds
 * at default amplitude sits below the felt threshold on many Android vibration
 * motors (they need real ramp-up time), which is why nothing was felt on-device
 * even though the calls were firing. Predefined effects use whatever waveform
 * the device's own haptics HAL has calibrated, the closest Android equivalent
 * to iOS's Taptic Engine feel. Falls back to longer manual pulses below API 29.
 */
object Haptics {
    private var vibrator: Vibrator? = null

    fun init(context: Context) {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private fun predefined(effectId: Int, fallbackMs: Long) {
        val v = vibrator ?: return
        if (!v.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            v.vibrate(VibrationEffect.createPredefined(effectId))
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createOneShot(fallbackMs, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(fallbackMs)
        }
    }

    fun light() = predefined(VibrationEffect.EFFECT_TICK, 40)
    fun soft() = predefined(VibrationEffect.EFFECT_TICK, 35)
    fun selection() = predefined(VibrationEffect.EFFECT_TICK, 35)
    fun medium() = predefined(VibrationEffect.EFFECT_CLICK, 50)
    fun success() = predefined(VibrationEffect.EFFECT_CLICK, 45)
    fun warning() = predefined(VibrationEffect.EFFECT_HEAVY_CLICK, 60)
    fun error() = predefined(VibrationEffect.EFFECT_DOUBLE_CLICK, 80)
}
