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
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat

// RGB(0.31, 0.35, 0.97) from Fer/Utilities/Theme.swift — read directly from the
// iOS source of truth this time, not eyeballed (the original FF5A32 orange
// used here was picked without checking iOS's actual value).
val FerAccent = Color(0xFF4F59F7)
private val FerAccentDark = Color(0xFF8B90FF)

// Material3's lightColorScheme()/darkColorScheme() fall back to the stock
// (purple-tinted) Material baseline palette for any role not explicitly
// passed in here. Leaving surface/outline/container roles unset is what
// caused the pink tint on NavigationBar and other default-colored chrome —
// every role below is deliberately tied to a neutral cool-gray + FerAccent
// palette so nothing falls back to that baseline purple.
private val LightColors = lightColorScheme(
    primary = FerAccent,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFE0E1FF),
    onPrimaryContainer = Color(0xFF1A1D6B),
    secondary = FerAccent,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFE0E1FF),
    onSecondaryContainer = Color(0xFF1A1D6B),
    tertiary = FerAccent,
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFE0E1FF),
    onTertiaryContainer = Color(0xFF1A1D6B),
    background = Color(0xFFF7F7F8),
    onBackground = Color(0xFF1B1B1F),
    surface = Color.White,
    onSurface = Color(0xFF1B1B1F),
    surfaceVariant = Color(0xFFEEEEF4),
    onSurfaceVariant = Color(0xFF6B6B72),
    surfaceContainerLowest = Color.White,
    surfaceContainerLow = Color(0xFFF8F8FA),
    surfaceContainer = Color(0xFFF1F1F6),
    surfaceContainerHigh = Color(0xFFEBEBF2),
    surfaceContainerHighest = Color(0xFFE5E5EE),
    surfaceTint = FerAccent,
    outline = Color(0xFFD4D4DE),
    outlineVariant = Color(0xFFE5E5EE),
    inverseSurface = Color(0xFF303034),
    inverseOnSurface = Color(0xFFF2F0F4),
    inversePrimary = FerAccentDark,
    error = Color(0xFFBA1A1A),
    onError = Color.White,
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002)
)

private val DarkColors = darkColorScheme(
    primary = FerAccentDark,
    onPrimary = Color(0xFF11135A),
    primaryContainer = Color(0xFF32358F),
    onPrimaryContainer = Color(0xFFE0E1FF),
    secondary = FerAccentDark,
    onSecondary = Color(0xFF11135A),
    secondaryContainer = Color(0xFF32358F),
    onSecondaryContainer = Color(0xFFE0E1FF),
    tertiary = FerAccentDark,
    onTertiary = Color(0xFF11135A),
    tertiaryContainer = Color(0xFF32358F),
    onTertiaryContainer = Color(0xFFE0E1FF),
    background = Color(0xFF0E0E10),
    onBackground = Color(0xFFE5E5EE),
    surface = Color(0xFF1B1B1E),
    onSurface = Color(0xFFE5E5EE),
    surfaceVariant = Color(0xFF2A2A30),
    onSurfaceVariant = Color(0xFFC7C6D0),
    surfaceContainerLowest = Color(0xFF0A0A0B),
    surfaceContainerLow = Color(0xFF17161A),
    surfaceContainer = Color(0xFF1F1E23),
    surfaceContainerHigh = Color(0xFF29282E),
    surfaceContainerHighest = Color(0xFF343339),
    surfaceTint = FerAccentDark,
    outline = Color(0xFF5A5A62),
    outlineVariant = Color(0xFF3A3A40),
    inverseSurface = Color(0xFFE5E5EE),
    inverseOnSurface = Color(0xFF303034),
    inversePrimary = FerAccent,
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFDAD6)
)

// 20.dp explicitly — matches iOS's `cardCorner: CGFloat = 20` in Theme.swift.
// (Previously RoundedCornerShape(16) with a bare Int resolved to the
// *percent* overload — 16% corner rounding, not 16dp — so cards were sized
// inconsistently depending on their own dimensions.)
val CardShape = RoundedCornerShape(20.dp)

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
