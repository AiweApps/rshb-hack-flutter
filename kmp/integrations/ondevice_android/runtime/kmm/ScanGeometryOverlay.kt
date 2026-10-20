package com.aiweapps.winescan.local

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.domain.scan.model.ScanGeometryProgress
import kotlin.math.min

/** Boxes use the original oriented frame and the same Fit transform as the photo. */
@Composable
fun ScanGeometryOverlay(progress: ScanGeometryProgress) {
    if (!progress.isValid) return
    Canvas(Modifier.fillMaxSize()) {
        val width = progress.frameSize[0].toFloat()
        val height = progress.frameSize[1].toFloat()
        val scale = min(size.width / width, size.height / height)
        val left = (size.width - width * scale) / 2
        val top = (size.height - height * scale) / 2
        progress.regions.forEach { region ->
            listOf(region.bottleBox to Color(0xFF83D4D0), region.labelBox to Color(0xFFFFD687)).forEach { (box, color) ->
                if (box != null) drawRect(color,
                    topLeft = Offset(left + box.x1.toFloat() * scale, top + box.y1.toFloat() * scale),
                    size = Size(box.width.toFloat() * scale, box.height.toFloat() * scale),
                    style = Stroke(2.dp.toPx()))
            }
        }
    }
}
