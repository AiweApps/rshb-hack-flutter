package com.aiweapps.winescan.scan.result.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.drag
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.uikit.theme.AppDesign

private val TouchRadius = 28.dp
private val HandleRingRadius = 10.dp
private val HandleRadius = 7.dp
private val BadgeRadius = 10.dp
private val FrameStroke = 2.dp
private val BottleStroke = 1.5.dp
private const val BOTTLE_ALPHA = 0.5f
private const val DIM_ALPHA = 0.55f
private const val FILL_ALPHA = 0.1f

/**
 * The drawing surface over the photo: the answer's bottle boxes faintly for orientation and
 * the draft frame, with everything outside it dimmed. A drag outside the draft draws a new
 * one, inside moves it, on a corner resizes it. The frame in motion lives here; only the
 * finished one is reported.
 */
@Composable
internal fun FrameCanvas(
    frameWidth: Float,
    frameHeight: Float,
    view: RecognitionView?,
    draft: BottleBox?,
    onDraftChanged: (BottleBox) -> Unit,
    modifier: Modifier = Modifier,
) {
    var size by remember { mutableStateOf(IntSize.Zero) }
    var live by remember { mutableStateOf<BottleBox?>(null) }
    val currentDraft by rememberUpdatedState(draft)
    val report by rememberUpdatedState(onDraftChanged)
    val density = LocalDensity.current.density
    val touchRadius = with(LocalDensity.current) { TouchRadius.toPx() }
    val haptics by rememberUpdatedState(rememberFrameHaptics())
    val measurer = rememberTextMeasurer()
    val badgeStyle = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold)
    val gold = AppDesign.colors.gold
    val onPhoto = AppDesign.colors.onPhoto
    val scrim = AppDesign.colors.scrim

    val geometry = remember(size, frameWidth, frameHeight) {
        if (size.width == 0 || size.height == 0) null
        else PhotoGeometry(size.width.toFloat(), size.height.toFloat(), frameWidth, frameHeight)
    }

    Canvas(
        modifier = modifier
            .onSizeChanged { size = it }
            .pointerInput(geometry, density) {
                val g = geometry ?: return@pointerInput
                awaitEachGesture {
                    val down = awaitFirstDown(requireUnconsumed = false)
                    val action = FrameDrag.begin(g, currentDraft, down.position, touchRadius)
                    var announced = false
                    val completed = drag(down.id) { change ->
                        change.consume()
                        val box = action.boxAt(g, change.position, density)
                        live = box
                        // The tick comes when the stroke grows into a frame, not on the touch itself.
                        if (action is FrameDrag.Draw && !announced && !box.isTooSmall(g, density)) {
                            announced = true
                            haptics.frameStarted()
                        }
                    }
                    val finished = live
                    val isKept = completed && finished != null &&
                        !(action is FrameDrag.Draw && finished.isTooSmall(g, density))
                    // Committed before the local frame is dropped, so no frame shows the old draft.
                    if (isKept && finished != null) {
                        if (action !is FrameDrag.Draw) haptics.frameAdjusted()
                        report(finished)
                    }
                    live = null
                }
            },
    ) {
        val g = geometry ?: return@Canvas
        val frame = (live ?: draft)?.let(g::toScreenRect)
        if (frame != null) drawDim(frame, scrim.copy(alpha = DIM_ALPHA))
        view?.bottles?.forEach { bottle ->
            val box = bottle.geometryBox ?: return@forEach
            val rect = g.toScreenRect(box)
            drawRect(
                color = onPhoto.copy(alpha = BOTTLE_ALPHA),
                topLeft = rect.topLeft,
                size = rect.size,
                style = Stroke(BottleStroke.toPx()),
            )
            if (view.bottles.size > 1) {
                drawBadge(measurer, badgeStyle.copy(color = scrim), bottle.number.toString(), rect.topLeft, onPhoto)
            }
        }
        if (frame != null) drawDraft(frame, gold, onPhoto)
    }
}

/** Darkens the whole surface except [hole]. */
private fun DrawScope.drawDim(hole: Rect, color: Color) {
    val path = Path().apply {
        fillType = PathFillType.EvenOdd
        addRect(Rect(Offset.Zero, size))
        addRect(hole)
    }
    drawPath(path, color)
}

private fun DrawScope.drawBadge(measurer: TextMeasurer, style: TextStyle, text: String, at: Offset, fill: Color) {
    val radius = BadgeRadius.toPx()
    val center = at + Offset(radius, radius)
    drawCircle(fill.copy(alpha = BOTTLE_ALPHA + 0.15f), radius, center)
    val layout = measurer.measure(text, style)
    drawText(layout, topLeft = center - Offset(layout.size.width / 2f, layout.size.height / 2f))
}

private fun DrawScope.drawDraft(rect: Rect, accent: Color, ring: Color) {
    drawRect(accent.copy(alpha = FILL_ALPHA), rect.topLeft, rect.size)
    drawRect(color = accent, topLeft = rect.topLeft, size = rect.size, style = Stroke(FrameStroke.toPx()))
    listOf(rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight).forEach { corner ->
        drawCircle(ring, HandleRingRadius.toPx(), corner)
        drawCircle(accent, HandleRadius.toPx(), corner)
    }
}
