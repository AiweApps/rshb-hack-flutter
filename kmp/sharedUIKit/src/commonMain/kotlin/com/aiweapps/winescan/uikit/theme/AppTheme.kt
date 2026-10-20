package com.aiweapps.winescan.uikit.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier

@Composable
fun AppTheme(
    isDark: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colors = if (isDark) DarkAppColors else LightAppColors

    CompositionLocalProvider(
        LocalAppColors provides colors,
        LocalAppTypography provides DefaultAppTypography,
    ) {
        MaterialTheme(colorScheme = colors.toColorScheme(isDark)) {
            // The theme paints the background itself. Without this the platform window
            // background shows through on the first frame.
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background,
                content = content,
            )
        }
    }
}

/**
 * Maps the palette onto Material's roles so the stock components (buttons, chips, sheets,
 * navigation bar) pick it up. Screens read roles from `MaterialTheme.colorScheme` and only
 * the tokens that have no role — gold, ok, warn, onPhoto, scrim — from [AppDesign.colors].
 */
private fun AppColors.toColorScheme(isDark: Boolean): ColorScheme {
    val base = if (isDark) darkColorScheme() else lightColorScheme()
    return base.copy(
        primary = wine,
        onPrimary = onWine,
        primaryContainer = paper2,
        onPrimaryContainer = ink,
        secondary = gold,
        onSecondary = ink,
        secondaryContainer = paper2,
        onSecondaryContainer = ink,
        tertiary = wine2,
        onTertiary = onWine,
        background = paper,
        onBackground = ink,
        surface = card,
        onSurface = ink,
        surfaceVariant = paper2,
        onSurfaceVariant = ink2,
        surfaceContainerLowest = card,
        surfaceContainerLow = card,
        surfaceContainer = paper2,
        surfaceContainerHigh = paper2,
        surfaceContainerHighest = paper2,
        outline = rule,
        outlineVariant = rule,
        error = bad,
        onError = onWine,
        errorContainer = paper2,
        onErrorContainer = bad,
    )
}

object AppDesign {
    val colors: AppColors
        @Composable get() = LocalAppColors.current

    val typography: AppTypography
        @Composable get() = LocalAppTypography.current
}
