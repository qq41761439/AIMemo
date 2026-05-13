package com.aimemo.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val AimemoPrimary = Color(0xFF2F6F5E)
val AimemoSecondary = Color(0xFF355C7D)
val AimemoAccent = Color(0xFFC7782F)
val AimemoBackground = Color(0xFFF6F7F4)
val AimemoSurface = Color.White
val AimemoBorder = Color(0xFFDDE2DC)
val AimemoInk = Color(0xFF202622)
val AimemoMuted = Color(0xFF68716A)
val AimemoError = Color(0xFFB42318)

private val LightColors: ColorScheme = lightColorScheme(
    primary = AimemoPrimary,
    secondary = AimemoSecondary,
    tertiary = AimemoAccent,
    background = AimemoBackground,
    surface = AimemoSurface,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = AimemoInk,
    onSurface = AimemoInk,
    error = AimemoError,
    outline = AimemoBorder,
)

private val DarkColors: ColorScheme = darkColorScheme(
    primary = Color(0xFF87D1BA),
    secondary = Color(0xFF9EC5E6),
    tertiary = Color(0xFFE6AC70),
    background = Color(0xFF111511),
    surface = Color(0xFF1B211D),
    onPrimary = Color(0xFF10372D),
    onSecondary = Color(0xFF102D44),
    onBackground = Color(0xFFE8EEE8),
    onSurface = Color(0xFFE8EEE8),
    error = Color(0xFFFFB4AB),
    outline = Color(0xFF3F4A43),
)

@Composable
fun AIMemoTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        typography = MaterialTheme.typography,
        content = content,
    )
}
