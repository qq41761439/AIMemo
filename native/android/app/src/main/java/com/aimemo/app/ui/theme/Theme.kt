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

val AimemoPrimary = Color(0xFF7C3AED)
val AimemoPrimaryEnd = Color(0xFFA855F7)
val AimemoSecondary = Color(0xFF2563EB)
val AimemoAccent = Color(0xFF14B8A6)
val AimemoBackground = Color(0xFFFAFAFE)
val AimemoSurface = Color.White
val AimemoBorder = Color(0xFFE6E1F3)
val AimemoInk = Color(0xFF1F2937)
val AimemoMuted = Color(0xFF6B7280)
val AimemoError = Color(0xFFB42318)

private val LightColors: ColorScheme = lightColorScheme(
    primary = AimemoPrimary,
    secondary = AimemoSecondary,
    tertiary = AimemoAccent,
    background = AimemoBackground,
    surface = AimemoSurface,
    surfaceVariant = Color(0xFFF1EDFB),
    primaryContainer = Color(0xFFEDE9FE),
    secondaryContainer = Color(0xFFDBEAFE),
    tertiaryContainer = Color(0xFFCCFBF1),
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = AimemoInk,
    onSurface = AimemoInk,
    onSurfaceVariant = AimemoMuted,
    onPrimaryContainer = Color(0xFF4C1D95),
    onSecondaryContainer = Color(0xFF1E3A8A),
    onTertiaryContainer = Color(0xFF134E4A),
    error = AimemoError,
    onError = Color.White,
    outline = AimemoBorder,
    outlineVariant = Color(0xFFF0EBFA),
)

private val DarkColors: ColorScheme = darkColorScheme(
    primary = Color(0xFFC4B5FD),
    secondary = Color(0xFF93C5FD),
    tertiary = Color(0xFF5EEAD4),
    background = Color(0xFF10111A),
    surface = Color(0xFF1B1B29),
    surfaceVariant = Color(0xFF2A2638),
    primaryContainer = Color(0xFF4C1D95),
    secondaryContainer = Color(0xFF1E3A8A),
    tertiaryContainer = Color(0xFF134E4A),
    onPrimary = Color(0xFF2E1065),
    onSecondary = Color(0xFF172554),
    onBackground = Color(0xFFF3F4F6),
    onSurface = Color(0xFFF3F4F6),
    onSurfaceVariant = Color(0xFFD1D5DB),
    onPrimaryContainer = Color(0xFFF5F3FF),
    onSecondaryContainer = Color(0xFFEFF6FF),
    onTertiaryContainer = Color(0xFFF0FDFA),
    error = Color(0xFFFFB4AB),
    outline = Color(0xFF3F3A52),
    outlineVariant = Color(0xFF302C42),
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
