package com.aiweapps.winescan.scan.result.components

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import com.aiweapps.winescan.domain.scan.model.BottleBox

/**
 * Maps between frame pixels (what the service speaks) and the screen box the photo is
 * letterboxed into. Pure layout arithmetic.
 */
internal class PhotoGeometry(
    boxWidth: Float,
    boxHeight: Float,
    val frameWidth: Float,
    val frameHeight: Float,
) {
    val scale: Float = minOf(boxWidth / frameWidth, boxHeight / frameHeight)
    private val originX = (boxWidth - frameWidth * scale) / 2f
    private val originY = (boxHeight - frameHeight * scale) / 2f

    fun toScreen(x: Double, y: Double): Offset = Offset(originX + x.toFloat() * scale, originY + y.toFloat() * scale)

    fun toScreenRect(box: BottleBox): Rect = Rect(toScreen(box.x1, box.y1), toScreen(box.x2, box.y2))

    /** Screen point to frame pixels, clamped to the photo. */
    fun toFrame(point: Offset): Offset = Offset(
        ((point.x - originX) / scale).coerceIn(0f, frameWidth),
        ((point.y - originY) / scale).coerceIn(0f, frameHeight),
    )
}
