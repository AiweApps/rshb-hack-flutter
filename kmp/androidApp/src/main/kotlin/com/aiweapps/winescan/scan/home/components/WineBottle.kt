package com.aiweapps.winescan.scan.home.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.PathParser
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.components.scan.home.model.ShutterMood
import kotlinx.coroutines.delay

// The bottle is drawn in the 30x52 box of the design mock and scaled to 18x31 dp.
private const val BOTTLE_BOX_WIDTH = 30f
private const val BOTTLE_BOX_HEIGHT = 52f
private const val BOTTLE_GLASS_STROKE = 1.8f
private const val BOTTLE_PIVOT_Y = 0.6f
private const val WAVE_PERIOD = 30f
private const val WAVE_SPAN = 30f
private const val WAVE_MS = 1800
private const val WAVE_TOP = -30f
private const val WAVE_BOTTOM = 60f

// Where the liquid surface sits (y in the bottle box; bigger is emptier).
private const val LEVEL_FULL = 16f
private const val LEVEL_EMPTY = 60f
private const val LEVEL_SLOSH_LOW = 40f
private const val LEVEL_SLOSH_HIGH = 30f
private const val LEVEL_BUSY_START = 48f
private const val LEVEL_BUSY_END = 20f
private const val LEVEL_SETTLE_MS = 900
private const val SLOSH_MS = 800
private const val BUSY_FILL_MS = 2560
private const val BUSY_HOLD_MS = 640L
private const val BUSY_RESET_MS = 400

// The scanner frame is drawn in a 44x54 box and scaled to 36x44 dp.
private const val FRAME_BOX_WIDTH = 44f
private const val FRAME_BOX_HEIGHT = 54f
private const val FRAME_STROKE = 2.4f
private const val SCAN_MS = 2400
private const val SCAN_TOP = 8f
private const val SCAN_BOTTOM = 44f
private const val SCAN_ALPHA = 0.85f
private const val SCAN_FADE_IN_END = 0.15f
private const val SCAN_MIDDLE = 0.5f
private const val SCAN_FADE_OUT_END = 0.65f

private const val LABEL_ALPHA = 0.92f
private const val LABEL_ALPHA_BLOCKED = 0.4f

private val BottleDefaultSize = DpSize(18.dp, 31.dp)
private val FrameDefaultSize = DpSize(36.dp, 44.dp)

private const val BOTTLE_PATH = "M11 1h8v11c0 3 7 6 7 13v22a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4V25c0-7 7-10 7-13z"
private const val FRAME_PATH =
    "M2 12V4a2 2 0 0 1 2-2h8M32 2h8a2 2 0 0 1 2 2v8M42 42v8a2 2 0 0 1-2 2h-8M12 52H4a2 2 0 0 1-2-2v-8"

private val bottlePath: Path by lazy { PathParser().parsePathString(BOTTLE_PATH).toPath() }
private val framePath: Path by lazy { PathParser().parsePathString(FRAME_PATH).toPath() }

/** A surface line with soft waves, long enough to slide by one period without a gap. */
private val wavePath: Path by lazy {
    Path().apply {
        moveTo(WAVE_TOP, 0f)
        for (step in 0 until 6) {
            val endX = -15f + 15f * step
            quadraticTo(endX - 7.5f, if (step % 2 == 0) -3f else 3f, endX, 0f)
        }
        lineTo(60f, WAVE_BOTTOM)
        lineTo(WAVE_TOP, WAVE_BOTTOM)
        close()
    }
}

/**
 * A small wine bottle with a liquid level that tells the service state: full and rippling
 * when ready, sloshing while connecting, filling up in a loop while busy, empty when a photo
 * would get no answer. [tilt] is the pour on a shot, in degrees.
 */
@Composable
internal fun WineBottle(
    mood: ShutterMood,
    tilt: State<Float>,
    modifier: Modifier = Modifier,
    boxSize: DpSize = BottleDefaultSize,
) {
    val level = remember { Animatable(LEVEL_EMPTY) }
    LaunchedEffect(mood) {
        when (mood) {
            ShutterMood.READY -> level.animateTo(LEVEL_FULL, settleSpec())
            ShutterMood.BLOCKED, ShutterMood.OFFLINE -> level.animateTo(LEVEL_EMPTY, settleSpec())
            ShutterMood.CHECKING -> {
                level.animateTo(LEVEL_SLOSH_LOW, settleSpec())
                while (true) {
                    level.animateTo(LEVEL_SLOSH_HIGH, tween(SLOSH_MS, easing = EaseInOut))
                    level.animateTo(LEVEL_SLOSH_LOW, tween(SLOSH_MS, easing = EaseInOut))
                }
            }
            ShutterMood.BUSY -> {
                level.animateTo(LEVEL_BUSY_START, settleSpec())
                while (true) {
                    level.animateTo(LEVEL_BUSY_END, tween(BUSY_FILL_MS, easing = EaseInOut))
                    delay(BUSY_HOLD_MS)
                    level.animateTo(LEVEL_BUSY_START, tween(BUSY_RESET_MS, easing = EaseInOut))
                }
            }
        }
    }

    val wave = rememberInfiniteTransition(label = "bottleWave").animateFloat(
        initialValue = 0f,
        targetValue = WAVE_SPAN,
        animationSpec = infiniteRepeatable(tween(WAVE_MS, easing = LinearEasing)),
        label = "bottleWaveShift",
    )
    val wine by animateColorAsState(
        targetValue = if (mood == ShutterMood.BUSY) ShutterPalette.wineBusy else ShutterPalette.wine,
        animationSpec = tween(LEVEL_SETTLE_MS / 2),
        label = "bottleWine",
    )
    val isBlocked = mood == ShutterMood.BLOCKED || mood == ShutterMood.OFFLINE
    val glass by animateColorAsState(
        targetValue = if (isBlocked) ShutterPalette.glassBlocked else ShutterPalette.glass,
        animationSpec = tween(LEVEL_SETTLE_MS / 2),
        label = "bottleGlass",
    )
    val labelColor by animateColorAsState(
        targetValue = ShutterPalette.label.copy(alpha = if (isBlocked) LABEL_ALPHA_BLOCKED else LABEL_ALPHA),
        animationSpec = tween(LEVEL_SETTLE_MS / 2),
        label = "bottleLabel",
    )

    Canvas(
        modifier = modifier
            .size(boxSize)
            .graphicsLayer {
                rotationZ = tilt.value
                transformOrigin = TransformOrigin(0.5f, BOTTLE_PIVOT_Y)
            },
    ) {
        val k = size.width / BOTTLE_BOX_WIDTH
        withTransform({ scale(k, k, pivot = Offset.Zero) }) {
            clipPath(bottlePath) {
                translate(left = wave.value, top = level.value) {
                    drawPath(wavePath, wine)
                }
            }
            drawPath(bottlePath, glass, style = Stroke(BOTTLE_GLASS_STROKE))
            drawRoundRect(
                color = labelColor,
                topLeft = Offset(6f, 28f),
                size = Size(18f, 11f),
                cornerRadius = CornerRadius(1.5f),
            )
        }
    }
}

/**
 * Gold scanner brackets with a thin line sweeping top to bottom. They fade and scale in only
 * while [isVisible]: the service is ready to read a label.
 */
@Composable
internal fun ScannerFrame(
    isVisible: Boolean,
    modifier: Modifier = Modifier,
    boxSize: DpSize = FrameDefaultSize,
    strokeWidth: Float = FRAME_STROKE,
    showScanLine: Boolean = true,
) {
    val appear = animateFloatAsState(
        targetValue = if (isVisible) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = 300f),
        label = "frameAppear",
    )
    val scan = rememberInfiniteTransition(label = "frameScan").animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(SCAN_MS, easing = LinearEasing)),
        label = "frameScanPhase",
    )
    Canvas(
        modifier = modifier
            .size(boxSize)
            .graphicsLayer {
                val shown = appear.value
                alpha = shown.coerceIn(0f, 1f)
                val s = 1.35f - 0.35f * shown
                scaleX = s
                scaleY = s
            },
    ) {
        if (appear.value < 0.01f) return@Canvas
        // The brackets keep their proportions: fit the box and centre it across the width.
        val k = minOf(size.width / FRAME_BOX_WIDTH, size.height / FRAME_BOX_HEIGHT)
        val offsetX = (size.width - FRAME_BOX_WIDTH * k) / 2f
        withTransform({
            translate(left = offsetX, top = 0f)
            scale(k, k, pivot = Offset.Zero)
        }) {
            drawPath(
                path = framePath,
                color = ShutterPalette.frame,
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round),
            )
            if (!showScanLine) return@withTransform
            val phase = scan.value
            drawRoundRect(
                color = ShutterPalette.frame.copy(alpha = scanAlpha(phase)),
                topLeft = Offset(5f, scanY(phase)),
                size = Size(34f, 2f),
                cornerRadius = CornerRadius(1f),
            )
        }
    }
}

private fun settleSpec() = tween<Float>(LEVEL_SETTLE_MS, easing = CubicBezierEasing(0.3f, 0.8f, 0.3f, 1f))

private fun scanY(phase: Float): Float {
    val travel = SCAN_BOTTOM - SCAN_TOP
    return if (phase < SCAN_MIDDLE) {
        SCAN_TOP + travel * FastOutSlowInEasing.transform(phase / SCAN_MIDDLE)
    } else {
        SCAN_BOTTOM - travel * FastOutSlowInEasing.transform((phase - SCAN_MIDDLE) / (1f - SCAN_MIDDLE))
    }
}

private fun scanAlpha(phase: Float): Float = when {
    phase < SCAN_FADE_IN_END -> SCAN_ALPHA * phase / SCAN_FADE_IN_END
    phase < SCAN_MIDDLE -> SCAN_ALPHA
    phase < SCAN_FADE_OUT_END -> SCAN_ALPHA * (1f - (phase - SCAN_MIDDLE) / (SCAN_FADE_OUT_END - SCAN_MIDDLE))
    else -> 0f
}
