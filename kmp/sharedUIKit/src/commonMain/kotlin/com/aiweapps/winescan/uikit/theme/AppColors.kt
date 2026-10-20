package com.aiweapps.winescan.uikit.theme

import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * The «Винный сканер» palette, native palette:
 * paper and card surfaces, ink for text, wine for actions, gold for accents.
 *
 * Material roles are derived from these in [AppTheme]; screens read the tokens that have
 * no Material counterpart (`gold`, `ok`, `warn`, `onPhoto`, `scrim`) from `AppDesign.colors`.
 * The iOS copy lives in `iosApp/iosApp/sharedComponents/AppTheme.swift` — change both.
 */
data class AppColors(
    /** Page background. */
    val paper: Color,
    /** Slightly deeper background: sheets, chips, inactive tabs. */
    val paper2: Color,
    /** Surface of cards and dialogs. */
    val card: Color,
    /** Primary text. */
    val ink: Color,
    /** Secondary text. */
    val ink2: Color,
    /** Captions, hints, placeholders. */
    val muted: Color,
    /** Hairlines, borders. */
    val rule: Color,
    /** Brand colour: primary buttons, links, active state. */
    val wine: Color,
    /** Pressed / hovered brand colour. */
    val wine2: Color,
    /** Text and icons on a wine-filled surface. */
    val onWine: Color,
    /** Accent: focus rings, selected frame, step numerals. */
    val gold: Color,
    /** Service is ready. */
    val ok: Color,
    /** Service is busy; warnings. */
    val warn: Color,
    /** Errors; service down. */
    val bad: Color,
    /** Badges drawn over a photo: white on any theme. */
    val onPhoto: Color,
    /** Scrim over a photo (draw mode, viewer). */
    val scrim: Color,
    /** Glass of a bottle drawn as an illustration: white wine. Object colours, the same in both themes. */
    val bottleWhite: Color,
    val bottleWhiteCap: Color,
    val bottleRed: Color,
    val bottleRedCap: Color,
    val bottleRose: Color,
    val bottleRoseCap: Color,
    /** Paper label on an illustrated bottle and the ink of its lines and stamp. */
    val bottleLabel: Color,
    val bottleLabelInk: Color,
    val bottleLabelAccent: Color,
)

val LightAppColors = AppColors(
    paper = Color(0xFFFFFFFF),
    paper2 = Color(0xFFF4F4F6),
    card = Color(0xFFFFFFFF),
    ink = Color(0xFF141217),
    ink2 = Color(0xFF3B3840),
    muted = Color(0xFF6B6770),
    rule = Color(0xFFE7E7E9),
    wine = Color(0xFF6B1736),
    wine2 = Color(0xFF561129),
    onWine = Color(0xFFFFFFFF),
    gold = Color(0xFFA9853F),
    ok = Color(0xFF3F6B3A),
    warn = Color(0xFF9A6516),
    bad = Color(0xFF9B2B2B),
    onPhoto = Color(0xFFFFFFFF),
    scrim = Color(0xFF26181A),
    bottleWhite = Color(0xFFB9A35E),
    bottleWhiteCap = Color(0xFF7A6A3A),
    bottleRed = Color(0xFF3B1419),
    bottleRedCap = Color(0xFF6B1D2C),
    bottleRose = Color(0xFFB5525C),
    bottleRoseCap = Color(0xFF7E2F3A),
    bottleLabel = Color(0xFFEFE6D4),
    bottleLabelInk = Color(0xFF6E5A4C),
    bottleLabelAccent = Color(0xFF6B1D2C),
)

val DarkAppColors = AppColors(
    paper = Color(0xFF19191B),
    paper2 = Color(0xFF2B2A2E),
    card = Color(0xFF232326),
    ink = Color(0xFFF4F2F4),
    ink2 = Color(0xFFC9C4CA),
    muted = Color(0xFFADA6AE),
    rule = Color(0xFF3C393F),
    wine = Color(0xFFF08A9E),
    wine2 = Color(0xFFF5A4B4),
    onWine = Color(0xFF21181D),
    gold = Color(0xFFD0AB62),
    ok = Color(0xFF8FBF83),
    warn = Color(0xFFE0A64A),
    bad = Color(0xFFEC8B84),
    onPhoto = Color(0xFFFFFFFF),
    scrim = Color(0xFF000000),
    bottleWhite = Color(0xFFB9A35E),
    bottleWhiteCap = Color(0xFF7A6A3A),
    bottleRed = Color(0xFF3B1419),
    bottleRedCap = Color(0xFF6B1D2C),
    bottleRose = Color(0xFFB5525C),
    bottleRoseCap = Color(0xFF7E2F3A),
    bottleLabel = Color(0xFFEFE6D4),
    bottleLabelInk = Color(0xFF6E5A4C),
    bottleLabelAccent = Color(0xFF6B1D2C),
)

val LocalAppColors = staticCompositionLocalOf { LightAppColors }
