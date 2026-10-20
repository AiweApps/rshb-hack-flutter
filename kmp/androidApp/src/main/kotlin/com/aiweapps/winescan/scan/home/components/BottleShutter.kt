package com.aiweapps.winescan.scan.home.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.scan.home.model.ShutterMood
import com.aiweapps.winescan.uikit.theme.AppDesign
import com.aiweapps.winescan.uikit.theme.AppTheme

private const val RING_STROKE_DP = 4
private const val GLOW_SPREAD_DP = 8
private const val GLOW_ALPHA = 0.32f
private const val BREATHE_MS = 1300
private const val CHECKING_SPIN_MS = 1100
private const val BUSY_SPIN_MS = 1800
private const val BLOCKED_SPIN_MS = 14_000
private const val RING_FADE_MS = 500
private const val ARC_FADE_MS = 400
private const val DISC_FADE_MS = 450
private const val PRESS_MS = 180
private const val PRESS_SCALE = 0.9f
private const val RING_ALPHA_READY = 0.95f
private const val RING_ALPHA_DIM = 0.28f
private const val RING_ALPHA_BLOCKED = 0.75f
private const val DISC_ALPHA_BLOCKED = 0.5f
private const val DISC_ALPHA_BUSY = 0.75f
private const val CHECKING_ARC_START = 0.55f
private const val BUSY_ARC_START = 0.4f
private const val DASH_ON_DP = 11
private const val DASH_OFF_DP = 6
private const val TILT_DEGREES = -38f
private const val TILT_OUT_MS = 280
private const val TILT_BACK_MS = 420
private const val BADGE_DAMPING = 0.5f

/**
 * The shutter, 80 dp: a ring around a white disc with a bottle in it. The ring and the bottle
 * say what the service can do ([mood]); the badge counts the photos queued ahead.
 *
 * [shotTicket] pours the bottle, [refusedTicket] wobbles the whole shutter. [enabled] only
 * says a capture or pick is in flight; a refusing service keeps the shutter pressable so it
 * can say why.
 */
@Composable
fun BottleShutter(
    mood: ShutterMood,
    queueAhead: Int,
    shotTicket: Int,
    refusedTicket: Int,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val interaction = remember { MutableInteractionSource() }
    val isPressed by interaction.collectIsPressedAsState()
    val pressScale by animateFloatAsState(
        targetValue = if (isPressed) PRESS_SCALE else 1f,
        animationSpec = tween(PRESS_MS),
        label = "shutterPress",
    )
    val wobble = remember { Animatable(1f) }
    LaunchedOnTicket(refusedTicket) { wobble.animateTo(1f, WobbleSpec) }
    val tilt = remember { Animatable(0f) }
    LaunchedOnTicket(shotTicket) {
        tilt.animateTo(TILT_DEGREES, tween(TILT_OUT_MS, easing = FastOutSlowInEasing))
        tilt.animateTo(0f, tween(TILT_BACK_MS, easing = FastOutSlowInEasing))
    }

    val isBlocked = mood == ShutterMood.BLOCKED || mood == ShutterMood.OFFLINE
    val discColor by animateColorAsState(
        targetValue = AppDesign.colors.onPhoto.copy(
            alpha = when {
                isBlocked -> DISC_ALPHA_BLOCKED
                !enabled -> DISC_ALPHA_BUSY
                else -> 1f
            },
        ),
        animationSpec = tween(DISC_FADE_MS),
        label = "shutterDisc",
    )

    Box(
        modifier = modifier
            .size(80.dp)
            .graphicsLayer {
                scaleX = wobble.value
                scaleY = wobble.value
            }
            .clickable(
                interactionSource = interaction,
                indication = null,
                enabled = enabled,
                role = Role.Button,
                onClickLabel = stringResource(R.string.scan_shutter),
                onClick = onClick,
            ),
        contentAlignment = Alignment.Center,
    ) {
        ShutterRing(mood = mood, modifier = Modifier.fillMaxSize())
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp)
                .graphicsLayer {
                    scaleX = pressScale
                    scaleY = pressScale
                }
                .drawBehind { drawCircle(discColor) },
            contentAlignment = Alignment.Center,
        ) {
            ScannerFrame(isVisible = mood == ShutterMood.READY)
            WineBottle(mood = mood, tilt = tilt.asState())
        }
        QueueBadge(count = queueAhead, modifier = Modifier.align(Alignment.TopEnd))
    }
}

/** The ring: gold glow while ready, a sweeping arc while checking or busy, dashes when blocked. */
@Composable
private fun ShutterRing(mood: ShutterMood, modifier: Modifier = Modifier) {
    val isBlocked = mood == ShutterMood.BLOCKED || mood == ShutterMood.OFFLINE
    val onPhoto = AppDesign.colors.onPhoto
    val ringColor by animateColorAsState(
        targetValue = when (mood) {
            ShutterMood.READY -> onPhoto.copy(alpha = RING_ALPHA_READY)
            ShutterMood.CHECKING, ShutterMood.BUSY -> onPhoto.copy(alpha = RING_ALPHA_DIM)
            ShutterMood.BLOCKED, ShutterMood.OFFLINE -> ShutterPalette.blocked.copy(alpha = 0f)
        },
        animationSpec = tween(RING_FADE_MS),
        label = "ringColor",
    )
    val glowShare = animateFloatAsState(if (mood == ShutterMood.READY) 1f else 0f, tween(RING_FADE_MS), label = "glow")
    val checkingShare = animateFloatAsState(if (mood == ShutterMood.CHECKING) 1f else 0f, tween(ARC_FADE_MS), label = "checkingArc")
    val busyShare = animateFloatAsState(if (mood == ShutterMood.BUSY) 1f else 0f, tween(ARC_FADE_MS), label = "busyArc")
    val blockedShare = animateFloatAsState(if (isBlocked) 1f else 0f, tween(RING_FADE_MS), label = "blockedRing")

    val loops = rememberInfiniteTransition(label = "ringLoops")
    val breathe = loops.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(BREATHE_MS, easing = EaseInOut), RepeatMode.Reverse),
        label = "breathe",
    )
    val checkingAngle = loops.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(CHECKING_SPIN_MS, easing = LinearEasing)),
        label = "checkingAngle",
    )
    val busyAngle = loops.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(BUSY_SPIN_MS, easing = LinearEasing)),
        label = "busyAngle",
    )
    val blockedAngle = loops.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(BLOCKED_SPIN_MS, easing = LinearEasing)),
        label = "blockedAngle",
    )

    val glowColor = ShutterPalette.glow
    val amber = ShutterPalette.amber
    val blockedColor = ShutterPalette.blocked
    Canvas(modifier) {
        val strokeWidth = RING_STROKE_DP.dp.toPx()
        val radius = (size.minDimension - strokeWidth) / 2f
        val outer = size.minDimension / 2f

        val glow = glowShare.value * breathe.value
        if (glow > 0f) {
            val spread = GLOW_SPREAD_DP.dp.toPx() * breathe.value
            drawCircle(
                color = glowColor.copy(alpha = GLOW_ALPHA * glow),
                radius = outer + spread / 2f,
                style = Stroke(spread),
            )
        }
        drawCircle(color = ringColor, radius = radius, style = Stroke(strokeWidth))

        drawSweep(checkingShare.value, checkingAngle.value, CHECKING_ARC_START, onPhoto, radius, strokeWidth)
        drawSweep(busyShare.value, busyAngle.value, BUSY_ARC_START, amber, radius, strokeWidth)

        if (blockedShare.value > 0f) {
            rotate(blockedAngle.value) {
                drawCircle(
                    color = blockedColor.copy(alpha = RING_ALPHA_BLOCKED * blockedShare.value),
                    radius = radius,
                    style = Stroke(
                        width = strokeWidth,
                        pathEffect = PathEffect.dashPathEffect(
                            floatArrayOf(DASH_ON_DP.dp.toPx(), DASH_OFF_DP.dp.toPx()),
                        ),
                    ),
                )
            }
        }
    }
}

/** A ring arc fading from transparent at [tailStart] of the turn to [color] at its head. */
private fun DrawScope.drawSweep(
    share: Float,
    angle: Float,
    tailStart: Float,
    color: Color,
    radius: Float,
    strokeWidth: Float,
) {
    if (share <= 0f) return
    val brush = Brush.sweepGradient(
        0f to Color.Transparent,
        tailStart to Color.Transparent,
        1f to color,
        center = center,
    )
    rotate(angle) {
        drawCircle(brush = brush, radius = radius, style = Stroke(strokeWidth), alpha = share)
    }
}

/** The number of photos ahead of ours, popping in and out with a spring. */
@Composable
private fun QueueBadge(count: Int, modifier: Modifier = Modifier) {
    val shown = remember { mutableIntStateOf(count) }
    LaunchedEffect(count) { if (count > 0) shown.intValue = count }
    val pop by animateFloatAsState(
        targetValue = if (count > 0) 1f else 0f,
        animationSpec = spring(dampingRatio = BADGE_DAMPING, stiffness = Spring.StiffnessMedium),
        label = "badgePop",
    )
    if (pop <= 0.01f) return
    Box(
        modifier = modifier
            .offset(x = 8.dp, y = (-6).dp)
            .graphicsLayer {
                scaleX = pop
                scaleY = pop
                alpha = pop.coerceIn(0f, 1f)
            }
            .defaultMinSize(minWidth = 22.dp, minHeight = 22.dp)
            .background(ShutterPalette.amber, CircleShape)
            .padding(horizontal = 6.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = shown.intValue.toString(),
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            color = ShutterPalette.onAmber,
        )
    }
}

@Preview(name = "Shutter, all moods", showBackground = true, backgroundColor = 0xFF2B2019)
@Composable
private fun BottleShutterPreview() {
    AppTheme(isDark = true) {
        Row(
            modifier = Modifier.padding(24.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            ShutterMood.entries.forEach { mood ->
                BottleShutter(
                    mood = mood,
                    queueAhead = if (mood == ShutterMood.BUSY) 2 else 0,
                    shotTicket = 0,
                    refusedTicket = 0,
                    enabled = true,
                    onClick = {},
                )
            }
        }
    }
}
