package com.harshbshah.fer.util

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/** Thin vibration wrapper — call sites mirror iOS's Haptics.swift (light/medium/success/etc). */
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

    private fun vibrate(ms: Long, amplitude: Int = VibrationEffect.DEFAULT_AMPLITUDE) {
        val v = vibrator ?: return
        if (!v.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createOneShot(ms, amplitude))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(ms)
        }
    }

    fun light() = vibrate(10)
    fun medium() = vibrate(20)
    fun soft() = vibrate(8)
    fun selection() = vibrate(5)
    fun success() = vibrate(15)
    fun warning() = vibrate(30)
    fun error() = vibrate(40)
}
