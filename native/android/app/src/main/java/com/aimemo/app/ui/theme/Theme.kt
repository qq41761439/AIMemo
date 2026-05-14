package com.aimemo.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

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
    surfaceVariant = Color(0xFFEAF0EA),
    primaryContainer = Color(0xFFDCEBE4),
    secondaryContainer = Color(0xFFDDE8F2),
    tertiaryContainer = Color(0xFFF5E4D3),
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = AimemoInk,
    onSurface = AimemoInk,
    onSurfaceVariant = AimemoMuted,
    onPrimaryContainer = Color(0xFF173B31),
    onSecondaryContainer = Color(0xFF18344C),
    onTertiaryContainer = Color(0xFF5C3213),
    error = AimemoError,
    onError = Color.White,
    outline = AimemoBorder,
    outlineVariant = Color(0xFFE8EDE7),
)

private val DarkColors: ColorScheme = darkColorScheme(
    primary = Color(0xFF87D1BA),
    secondary = Color(0xFF9EC5E6),
    tertiary = Color(0xFFE6AC70),
    background = Color(0xFF111511),
    surface = Color(0xFF1B211D),
    surfaceVariant = Color(0xFF26302A),
    primaryContainer = Color(0xFF214F43),
    secondaryContainer = Color(0xFF213D55),
    tertiaryContainer = Color(0xFF5D3518),
    onPrimary = Color(0xFF10372D),
    onSecondary = Color(0xFF102D44),
    onBackground = Color(0xFFE8EEE8),
    onSurface = Color(0xFFE8EEE8),
    onSurfaceVariant = Color(0xFFC3CCC4),
    onPrimaryContainer = Color(0xFFD8F4EA),
    onSecondaryContainer = Color(0xFFD7EAF8),
    onTertiaryContainer = Color(0xFFFFE0C2),
    error = Color(0xFFFFB4AB),
    outline = Color(0xFF3F4A43),
    outlineVariant = Color(0xFF2D3831),
)

private val AimemoShapes = Shapes(
    extraSmall = RoundedCornerShape(6.dp),
    small = RoundedCornerShape(6.dp),
    medium = RoundedCornerShape(8.dp),
    large = RoundedCornerShape(12.dp),
    extraLarge = RoundedCornerShape(16.dp),
)

@Composable
fun AIMemoTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        typography = MaterialTheme.typography,
        shapes = AimemoShapes,
        content = content,
    )
}
