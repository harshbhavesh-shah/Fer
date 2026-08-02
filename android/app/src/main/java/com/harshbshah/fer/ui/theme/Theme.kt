package com.harshbshah.fer.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

val FerAccent = Color(0xFFFF5A32)
private val FerAccentDark = Color(0xFFFF7A54)

private val LightColors = lightColorScheme(
    primary = FerAccent,
    onPrimary = Color.White,
    secondary = FerAccent,
    background = Color(0xFFF7F7F8),
    surface = Color.White
)

private val DarkColors = darkColorScheme(
    primary = FerAccentDark,
    onPrimary = Color.Black,
    secondary = FerAccentDark,
    background = Color(0xFF0E0E10),
    surface = Color(0xFF1B1B1E)
)

val CardShape = RoundedCornerShape(16)

fun ferGradient(base: Color) = Brush.linearGradient(listOf(base, base.copy(alpha = 0.75f)))

@Composable
fun FerTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val colorScheme = if (darkTheme) DarkColors else LightColors
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.background.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }
    MaterialTheme(colorScheme = colorScheme, content = content)
}
