package com.aiweapps.winescan.scan.home.components

import androidx.compose.animation.core.AnimationSpec
import androidx.compose.animation.core.keyframes
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.Color
import com.aiweapps.winescan.uikit.theme.DarkAppColors
import com.aiweapps.winescan.uikit.theme.LightAppColors

private const val REFUSED_MOTION_MS = 420

/**
 * Runs [block] each time [ticket] changes after the first composition. The component bumps its
 * tickets for one-shot reactions (a refused shot, a status reveal); a ticket that is already
 * non-zero when the screen comes back must not replay the reaction.
 */
@Composable
internal fun LaunchedOnTicket(ticket: Int, block: suspend () -> Unit) {
    val seen = remember { mutableIntStateOf(ticket) }
    LaunchedEffect(ticket) {
        if (ticket != seen.intValue) {
            seen.intValue = ticket
            block()
        }
    }
}

/** Horizontal shake of the status capsule, in dp, over [REFUSED_MOTION_MS]. */
internal val ShakeSpec: AnimationSpec<Float> = keyframes {
    durationMillis = REFUSED_MOTION_MS
    -1f at 42
    3f at 84
    -6f at 126
    6f at 168
    -6f at 210
    6f at 252
    -6f at 294
    3f at 336
    -1f at 378
    0f at REFUSED_MOTION_MS
}

/** Squash and rebound of the shutter when it refuses a shot. */
internal val WobbleSpec: AnimationSpec<Float> = keyframes {
    durationMillis = REFUSED_MOTION_MS
    0.86f at 126
    1.05f at 252
    1f at REFUSED_MOTION_MS
}

/**
 * The shutter and the capsule always sit over the camera preview, which is dark in either
 * theme, so their accents come from the dark palette; what is drawn on the white disc comes
 * from the light one. Both are the shared palette tokens, not new colours.
 */
internal object ShutterPalette {
    val glow: Color = DarkAppColors.gold
    val amber: Color = DarkAppColors.warn
    val blocked: Color = DarkAppColors.bad
    val checking: Color = DarkAppColors.ink2
    val ok: Color = DarkAppColors.ok
    val onAmber: Color = DarkAppColors.paper

    val frame: Color = LightAppColors.gold
    val glass: Color = LightAppColors.wine
    val wine: Color = LightAppColors.wine2
    val wineBusy: Color = androidx.compose.ui.graphics.lerp(LightAppColors.wine2, LightAppColors.warn, 0.35f)
    val label: Color = LightAppColors.paper2
    val glassBlocked: Color = LightAppColors.muted
}
