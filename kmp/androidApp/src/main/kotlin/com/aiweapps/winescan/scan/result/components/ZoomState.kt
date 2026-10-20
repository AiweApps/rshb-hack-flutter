package com.aiweapps.winescan.scan.result.components

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculatePan
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.unit.IntSize
import com.aiweapps.winescan.config.ScanLimits

/**
 * Zoom and pan shared by several layers: the gestures are read once on the container
 * ([zoomGestures]) and every layer that should move together applies [zoomLayer].
 */
@Stable
class ZoomState {
    var scale by mutableFloatStateOf(1f)
        private set
    var offset by mutableStateOf(Offset.Zero)
        private set
    var size by mutableStateOf(IntSize.Zero)

    fun reset() {
        scale = 1f
        offset = Offset.Zero
    }

    fun transform(zoom: Float, pan: Offset) {
        val newScale = (scale * zoom).coerceIn(1f, ScanLimits.COMPARE_MAX_ZOOM)
        val maxX = size.width * (newScale - 1f) / 2f
        val maxY = size.height * (newScale - 1f) / 2f
        val moved = offset + pan
        scale = newScale
        offset = Offset(moved.x.coerceIn(-maxX, maxX), moved.y.coerceIn(-maxY, maxY))
    }
}

@Composable
fun rememberZoomState(): ZoomState = remember { ZoomState() }

/**
 * Pinch to zoom, drag to pan once zoomed, double-tap to reset. At normal size one-finger
 * drags are left alone, so a divider handle or a surrounding pager still gets them.
 */
fun Modifier.zoomGestures(state: ZoomState): Modifier = this
    .onSizeChanged { state.size = it }
    .pointerInput(state) { detectTapGestures(onDoubleTap = { state.reset() }) }
    .pointerInput(state) {
        awaitEachGesture {
            awaitFirstDown(requireUnconsumed = false)
            do {
                val event = awaitPointerEvent()
                val fingers = event.changes.count { it.pressed }
                if (fingers >= 2 || state.scale > 1f) {
                    state.transform(event.calculateZoom(), event.calculatePan())
                    event.changes.forEach { if (it.positionChanged()) it.consume() }
                }
            } while (event.changes.any { it.pressed })
        }
    }

/** Applies the current zoom and pan to this layer. */
fun Modifier.zoomLayer(state: ZoomState): Modifier = graphicsLayer {
    scaleX = state.scale
    scaleY = state.scale
    translationX = state.offset.x
    translationY = state.offset.y
}
