package com.aiweapps.winescan.scan.home.components

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.scan.home.model.ShutterMood
import com.aiweapps.winescan.components.scan.home.model.StatusHint
import com.aiweapps.winescan.uikit.theme.AppDesign
import com.aiweapps.winescan.uikit.theme.AppTheme

private val CAPSULE_HEIGHT = 36.dp
private const val SHAKE_PX_PER_DP = 1
private const val BASE_SCRIM_ALPHA = 0.35f
private const val TINT_NEUTRAL_ALPHA = 0.12f
private const val TINT_INFO_ALPHA = 0.18f
private const val TINT_WARN_ALPHA = 0.30f
private const val TINT_BAD_ALPHA = 0.28f
private const val BORDER_NEUTRAL_ALPHA = 0.22f
private const val BORDER_ACCENT_ALPHA = 0.55f
private const val SHOW_MS = 260
private const val HIDE_MS = 200
private const val HIDDEN_SCALE = 0.92f
private const val TONE_FADE_MS = 350
private const val WIDTH_MS = 450
private const val LAYER_FADE_MS = 280
private const val LAYER_SLIDE_MS = 380
private const val CHECKING_BLINK_MS = 500
private const val BUSY_PULSE_MS = 700
private const val DOT_MIN_ALPHA = 0.35f
private const val DOT_PULSE_SCALE = 1.5f
private const val DOT_PULSE_MIN_ALPHA = 0.55f

/** What the capsule shows at a moment; two equal faces never trigger a transition. */
private data class HintFace(val hint: StatusHint, val mood: ShutterMood, val queueAhead: Int)

/** Remembers the last face that was on screen, so the fade-out keeps it instead of the resting hint. */
private class HeldFace(var face: HintFace)

private enum class HintTone { NEUTRAL, INFO, WARN, BAD }

/**
 * One capsule over the shutter. It says where to point while the service is ready; when the
 * service status or a queued photo needs saying, the same capsule changes width, tint and
 * text. The whole capsule fades in and out with [isShown]; its slot keeps its height either
 * way, so the controls below never jump. When the status folds back the component decides
 * the capsule is gone, the UI does not time anything itself.
 *
 * [refusedTicket] shakes the capsule.
 */
@Composable
fun StatusHintCapsule(
    hint: StatusHint,
    mood: ShutterMood,
    queueAhead: Int,
    isShown: Boolean,
    refusedTicket: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val face = when (hint) {
        StatusHint.AIM -> HintFace(StatusHint.AIM, ShutterMood.READY, 0)
        StatusHint.QUEUED -> HintFace(StatusHint.QUEUED, ShutterMood.BUSY, queueAhead)
        StatusHint.STATUS ->
            HintFace(StatusHint.STATUS, mood, if (mood == ShutterMood.BUSY) queueAhead else 0)
    }
    val held = remember { HeldFace(face) }
    if (isShown) held.face = face
    val shownFace = held.face
    val shake = remember { Animatable(0f) }
    LaunchedOnTicket(refusedTicket) { shake.animateTo(0f, ShakeSpec) }

    val tone = shownFace.tone()
    val onPhoto = AppDesign.colors.onPhoto
    val tint by animateColorAsState(
        targetValue = when (tone) {
            HintTone.NEUTRAL -> onPhoto.copy(alpha = TINT_NEUTRAL_ALPHA)
            HintTone.INFO -> onPhoto.copy(alpha = TINT_INFO_ALPHA)
            HintTone.WARN -> ShutterPalette.amber.copy(alpha = TINT_WARN_ALPHA)
            HintTone.BAD -> ShutterPalette.blocked.copy(alpha = TINT_BAD_ALPHA)
        },
        animationSpec = tween(TONE_FADE_MS),
        label = "capsuleTint",
    )
    val border by animateColorAsState(
        targetValue = when (tone) {
            HintTone.NEUTRAL, HintTone.INFO -> onPhoto.copy(alpha = BORDER_NEUTRAL_ALPHA)
            HintTone.WARN -> ShutterPalette.amber.copy(alpha = BORDER_ACCENT_ALPHA)
            HintTone.BAD -> ShutterPalette.blocked.copy(alpha = BORDER_ACCENT_ALPHA)
        },
        animationSpec = tween(TONE_FADE_MS),
        label = "capsuleBorder",
    )

    val density = LocalDensity.current
    val slidePx = with(density) { 10.dp.roundToPx() }
    val shakePx = with(density) { SHAKE_PX_PER_DP.dp.toPx() }
    val text = shownFace.text()

    Box(
        modifier = modifier.height(CAPSULE_HEIGHT),
        contentAlignment = Alignment.Center,
    ) {
        AnimatedVisibility(
            visible = isShown,
            enter = fadeIn(tween(SHOW_MS)) +
                scaleIn(tween(SHOW_MS, easing = EaseInOut), initialScale = HIDDEN_SCALE) +
                slideInVertically(tween(SHOW_MS, easing = EaseInOut)) { slidePx },
            exit = fadeOut(tween(HIDE_MS)) +
                scaleOut(tween(HIDE_MS, easing = EaseInOut), targetScale = HIDDEN_SCALE) +
                slideOutVertically(tween(HIDE_MS, easing = EaseInOut)) { slidePx },
        ) {
            Box(
                modifier = Modifier
                    .offset { IntOffset((shake.value * shakePx).toInt(), 0) }
                    .animateContentSize(tween(WIDTH_MS, easing = CubicBezierEasing(0.2f, 0.9f, 0.25f, 1.15f)))
                    .height(CAPSULE_HEIGHT)
                    .clip(CircleShape)
                    .background(AppDesign.colors.scrim.copy(alpha = BASE_SCRIM_ALPHA))
                    .background(tint)
                    .border(1.dp, border, CircleShape)
                    .clickable(role = Role.Button, onClickLabel = text, onClick = onClick),
            ) {
                AnimatedContent(
                    targetState = shownFace,
                    transitionSpec = {
                        // Going back to the hint comes from above and the status leaves downwards;
                        // every other change rises from below.
                        val enterFrom = if (targetState.hint == StatusHint.AIM) -slidePx else slidePx
                        (fadeIn(tween(LAYER_FADE_MS)) +
                            slideInVertically(tween(LAYER_SLIDE_MS, easing = EaseInOut)) { enterFrom }) togetherWith
                            (fadeOut(tween(LAYER_FADE_MS)) +
                                slideOutVertically(tween(LAYER_SLIDE_MS, easing = EaseInOut)) { -enterFrom }) using
                            SizeTransform(clip = false) { _, _ -> snap() }
                    },
                    contentAlignment = Alignment.Center,
                    label = "capsuleFace",
                ) { shown ->
                    HintFaceRow(shown)
                }
            }
        }
    }
}

@Composable
private fun HintFaceRow(face: HintFace) {
    Row(
        modifier = Modifier.height(CAPSULE_HEIGHT).padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        if (face.hint != StatusHint.AIM) StatusDot(face.mood)
        Text(
            text = face.text(),
            style = MaterialTheme.typography.labelLarge,
            color = AppDesign.colors.onPhoto,
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Clip,
        )
    }
}

/** The coloured dot of a status: blinks while checking, pulses while busy, still otherwise. */
@Composable
private fun StatusDot(mood: ShutterMood, modifier: Modifier = Modifier) {
    val loops = rememberInfiniteTransition(label = "dotLoops")
    val blink = loops.animateFloat(
        initialValue = DOT_MIN_ALPHA,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(CHECKING_BLINK_MS, easing = EaseInOut), RepeatMode.Reverse),
        label = "dotBlink",
    )
    val pulse = loops.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(BUSY_PULSE_MS, easing = EaseInOut), RepeatMode.Reverse),
        label = "dotPulse",
    )
    val color = when (mood) {
        ShutterMood.CHECKING -> ShutterPalette.checking
        ShutterMood.READY -> ShutterPalette.ok
        ShutterMood.BUSY -> ShutterPalette.amber
        ShutterMood.BLOCKED, ShutterMood.OFFLINE -> ShutterPalette.blocked
    }
    Box(
        modifier = modifier
            .size(8.dp)
            .graphicsLayer {
                when (mood) {
                    ShutterMood.CHECKING -> alpha = blink.value
                    ShutterMood.BUSY -> {
                        val scale = 1f + (DOT_PULSE_SCALE - 1f) * pulse.value
                        scaleX = scale
                        scaleY = scale
                        alpha = 1f - (1f - DOT_PULSE_MIN_ALPHA) * pulse.value
                    }
                    ShutterMood.READY, ShutterMood.BLOCKED, ShutterMood.OFFLINE -> Unit
                }
            }
            .background(color, CircleShape),
    )
}

private fun HintFace.tone(): HintTone = when (hint) {
    StatusHint.AIM -> HintTone.NEUTRAL
    StatusHint.QUEUED -> HintTone.WARN
    StatusHint.STATUS -> when (mood) {
        ShutterMood.BUSY -> HintTone.WARN
        ShutterMood.BLOCKED, ShutterMood.OFFLINE -> HintTone.BAD
        ShutterMood.CHECKING, ShutterMood.READY -> HintTone.INFO
    }
}

@Composable
private fun HintFace.text(): String = when (hint) {
    StatusHint.AIM -> stringResource(R.string.scan_hint)
    StatusHint.QUEUED -> pluralStringResource(R.plurals.scan_status_queued, queueAhead, queueAhead)
    StatusHint.STATUS -> when (mood) {
        ShutterMood.CHECKING -> stringResource(R.string.scan_status_checking)
        // The status text of a ready service is the resting hint.
        ShutterMood.READY -> stringResource(R.string.scan_hint)
        ShutterMood.BUSY ->
            if (queueAhead > 0) {
                pluralStringResource(R.plurals.scan_status_busy_queue, queueAhead, queueAhead)
            } else {
                stringResource(R.string.scan_status_busy)
            }
        ShutterMood.BLOCKED -> stringResource(R.string.scan_status_blocked)
        ShutterMood.OFFLINE -> stringResource(R.string.scan_status_offline)
    }
}

@Preview(name = "Hint, all faces", showBackground = true, backgroundColor = 0xFF2B2019)
@Composable
private fun StatusHintCapsulePreview() {
    AppTheme(isDark = true) {
        Column(
            modifier = Modifier.padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            StatusHintCapsule(StatusHint.AIM, ShutterMood.READY, 0, isShown = true, refusedTicket = 0, onClick = {})
            ShutterMood.entries.filter { it != ShutterMood.READY }.forEach { mood ->
                StatusHintCapsule(
                    hint = StatusHint.STATUS,
                    mood = mood,
                    queueAhead = if (mood == ShutterMood.BUSY) 2 else 0,
                    isShown = true,
                    refusedTicket = 0,
                    onClick = {},
                )
            }
            StatusHintCapsule(StatusHint.QUEUED, ShutterMood.BUSY, 2, isShown = true, refusedTicket = 0, onClick = {})
        }
    }
}

@Preview(name = "Hint, hidden (slot keeps its height)", showBackground = true, backgroundColor = 0xFF2B2019)
@Composable
private fun StatusHintCapsuleHiddenPreview() {
    AppTheme(isDark = true) {
        Column(Modifier.padding(24.dp)) {
            StatusHintCapsule(StatusHint.AIM, ShutterMood.BLOCKED, 0, isShown = false, refusedTicket = 0, onClick = {})
            Text("controls", color = AppDesign.colors.onPhoto)
        }
    }
}
