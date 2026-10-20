package com.aiweapps.winescan.scan.result.components

import androidx.compose.ui.geometry.Offset
import com.aiweapps.winescan.config.ScanLimits
import com.aiweapps.winescan.domain.scan.model.BottleBox
import kotlin.math.abs

/** What one finger-down on the drawing surface is doing: drawing, moving, or resizing a frame. */
internal sealed interface FrameDrag {
    class Draw(val start: Offset) : FrameDrag
    class Move(val origin: BottleBox, val start: Offset) : FrameDrag
    class Resize(val fixed: Offset) : FrameDrag

    companion object {
        fun begin(geometry: PhotoGeometry, draft: BottleBox?, down: Offset, touchRadius: Float): FrameDrag {
            if (draft != null) {
                val rect = geometry.toScreenRect(draft)
                val corners = listOf(
                    rect.topLeft to Offset(draft.x2.toFloat(), draft.y2.toFloat()),
                    rect.topRight to Offset(draft.x1.toFloat(), draft.y2.toFloat()),
                    rect.bottomLeft to Offset(draft.x2.toFloat(), draft.y1.toFloat()),
                    rect.bottomRight to Offset(draft.x1.toFloat(), draft.y1.toFloat()),
                )
                val nearest = corners.minBy { (corner, _) -> (corner - down).getDistance() }
                if ((nearest.first - down).getDistance() <= touchRadius) return Resize(fixed = nearest.second)
                if (rect.contains(down)) return Move(origin = draft, start = geometry.toFrame(down))
            }
            return Draw(start = geometry.toFrame(down))
        }
    }
}

/**
 * The frame the drag has produced by now, in frame pixels. [density] converts the limits,
 * which are in screen points, to the pixels the geometry works in.
 */
internal fun FrameDrag.boxAt(geometry: PhotoGeometry, current: Offset, density: Float): BottleBox {
    val point = geometry.toFrame(current)
    return when (this) {
        is FrameDrag.Draw -> BottleBox.fromPoints(start.x.toDouble(), start.y.toDouble(), point.x.toDouble(), point.y.toDouble())
        is FrameDrag.Move -> {
            val dx = (point.x - start.x).coerceIn(-origin.x1.toFloat(), geometry.frameWidth - origin.x2.toFloat())
            val dy = (point.y - start.y).coerceIn(-origin.y1.toFloat(), geometry.frameHeight - origin.y2.toFloat())
            BottleBox(origin.x1 + dx, origin.y1 + dy, origin.x2 + dx, origin.y2 + dy)
        }
        is FrameDrag.Resize -> {
            val minSide = ScanLimits.MIN_ROI_SIDE_WHILE_RESIZING * density / geometry.scale
            val x = keepApart(point.x, fixed.x, minSide, geometry.frameWidth)
            val y = keepApart(point.y, fixed.y, minSide, geometry.frameHeight)
            BottleBox.fromPoints(fixed.x.toDouble(), fixed.y.toDouble(), x.toDouble(), y.toDouble())
        }
    }
}

/** A drawn frame smaller than a fingertip is a tap, not a frame. */
internal fun BottleBox.isTooSmall(geometry: PhotoGeometry, density: Float): Boolean =
    longerSide * geometry.scale / density < ScanLimits.MIN_ROI_SIDE_ON_SCREEN

private fun keepApart(moving: Float, fixed: Float, minSide: Float, limit: Float): Float {
    if (abs(moving - fixed) >= minSide) return moving
    val pushed = if (moving >= fixed) fixed + minSide else fixed - minSide
    return pushed.coerceIn(0f, limit)
}
