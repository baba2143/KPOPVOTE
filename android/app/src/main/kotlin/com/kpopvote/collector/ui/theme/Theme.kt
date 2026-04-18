package com.kpopvote.collector.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = BrandColors.AccentPink,
    onPrimary = Color.White,
    primaryContainer = BrandColors.GradientPurple,
    onPrimaryContainer = Color.White,
    secondary = BrandColors.AccentBlue,
    onSecondary = BrandColors.BackgroundDark,
    secondaryContainer = BrandColors.PrimaryBlue,
    onSecondaryContainer = Color.White,
    tertiary = BrandColors.GradientPurple,
    onTertiary = Color.White,
    background = BrandColors.BackgroundDark,
    onBackground = Color.White,
    surface = BrandColors.CardDark,
    onSurface = Color.White,
    surfaceVariant = BrandColors.SurfaceVariantDark,
    onSurfaceVariant = BrandColors.TextGray,
    error = BrandColors.StatusUrgent,
    onError = Color.White,
    outline = BrandColors.OutlineDark,
)

private val LightColorScheme = lightColorScheme(
    primary = BrandColors.PrimaryPink,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFFCE4EC),
    onPrimaryContainer = BrandColors.OnBackgroundLight,
    secondary = BrandColors.PrimaryBlue,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFE3F2FD),
    onSecondaryContainer = BrandColors.OnBackgroundLight,
    tertiary = BrandColors.GradientPurple,
    onTertiary = Color.White,
    background = BrandColors.BackgroundLight,
    onBackground = Color.Black,
    surface = Color.White,
    onSurface = BrandColors.OnBackgroundLight,
    surfaceVariant = BrandColors.SurfaceVariantLight,
    onSurfaceVariant = Color(0xFF616161),
    error = BrandColors.StatusUrgent,
    onError = Color.White,
    outline = BrandColors.OutlineLight,
)

@Composable
fun KpopvoteTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    // Dynamic Color is disabled — brand identity (pink/blue) should stay consistent.
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = Color.Transparent.toArgb()
            window.navigationBarColor = colorScheme.background.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = !darkTheme
        }
    }

    CompositionLocalProvider(LocalSpacing provides Spacing()) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = KpopvoteTypography,
            shapes = KpopvoteShapes,
            content = content,
        )
    }
}
