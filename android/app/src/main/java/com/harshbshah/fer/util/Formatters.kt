package com.harshbshah.fer.util

import com.harshbshah.fer.data.model.UserProfile.WeightUnit
import java.text.DateFormat
import java.util.Date
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt

object Formatters {
    private const val LB_PER_KG = 2.20462

    fun duration(totalSeconds: Long): String {
        val h = totalSeconds / 3600
        val m = (totalSeconds % 3600) / 60
        val s = totalSeconds % 60
        return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%d:%02d".format(m, s)
    }

    fun weight(value: Double): String {
        return if (value % 1.0 == 0.0) "%.0f".format(value) else "%.1f".format(value)
    }

    /** Converts a canonical lb value to the display unit and formats it. */
    fun weight(lbValue: Double, unit: WeightUnit): String = weight(displayValue(lbValue, unit))

    /** Converts a canonical lb value into the given display unit (no formatting). */
    fun displayValue(lbValue: Double, unit: WeightUnit): Double =
        if (unit == WeightUnit.kg) lbValue / LB_PER_KG else lbValue

    /** Converts a value entered in the given display unit back to canonical lb for storage. */
    fun toStorageWeight(input: Double, unit: WeightUnit): Double =
        if (unit == WeightUnit.kg) input * LB_PER_KG else input

    fun mediumDate(date: Date): String =
        DateFormat.getDateInstance(DateFormat.MEDIUM).format(date)

    fun relativeDate(date: Date, now: Date = Date()): String {
        val diffMs = now.time - date.time
        val minutes = TimeUnit.MILLISECONDS.toMinutes(diffMs)
        val hours = TimeUnit.MILLISECONDS.toHours(diffMs)
        val days = TimeUnit.MILLISECONDS.toDays(diffMs)
        return when {
            minutes < 1 -> "just now"
            minutes < 60 -> "${minutes}m ago"
            hours < 24 -> "${hours}h ago"
            days < 7 -> "${days}d ago"
            days < 30 -> "${(days / 7)}w ago"
            days < 365 -> "${(days / 30)}mo ago"
            else -> "${(days / 365)}y ago"
        }
    }

    fun monthYear(date: Date): String =
        java.text.SimpleDateFormat("MMMM yyyy").format(date)

    /** Compact absolute date for list rows, e.g. "Aug 1" — used in History instead of relative "1d ago". */
    fun shortDate(date: Date): String =
        java.text.SimpleDateFormat("MMM d", java.util.Locale.getDefault()).format(date)
}
