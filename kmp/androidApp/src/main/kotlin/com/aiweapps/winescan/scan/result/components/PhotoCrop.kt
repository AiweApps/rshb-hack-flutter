package com.aiweapps.winescan.scan.result.components

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import com.aiweapps.winescan.config.ScanLimits
import com.aiweapps.winescan.domain.scan.model.BottleBox
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** The part of the user's photo a screen draws: still decoding, unreadable, or ready. */
sealed interface PhotoPart {
    data object Loading : PhotoPart
    data object Missing : PhotoPart
    data class Ready(val image: ImageBitmap) : PhotoPart
}

/**
 * Decodes [photoPath] off the main thread and cuts [crop] out of it (the whole photo when
 * `null`). Box coordinates are in pixels of [frame], the frame the service answered about;
 * the decode may be smaller, so they are scaled to what was actually decoded.
 */
@Composable
fun rememberPhotoPart(
    photoPath: String,
    crop: BottleBox?,
    frame: List<Int>?,
    maxSide: Int,
): PhotoPart {
    val part by produceState<PhotoPart>(PhotoPart.Loading, photoPath, crop, frame, maxSide) {
        value = withContext(Dispatchers.IO) { decodePart(photoPath, crop, frame, maxSide) }
    }
    return part
}

private fun decodePart(photoPath: String, crop: BottleBox?, frame: List<Int>?, maxSide: Int): PhotoPart {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(photoPath, bounds)
    if (bounds.outWidth <= 0) return PhotoPart.Missing

    var sample = 1
    while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= maxSide) sample *= 2
    val decoded = BitmapFactory.decodeFile(photoPath, BitmapFactory.Options().apply { inSampleSize = sample })
        ?: return PhotoPart.Missing
    if (crop == null) return PhotoPart.Ready(decoded.asImageBitmap())

    val frameWidth = frame?.getOrNull(0)?.takeIf { it > 0 } ?: bounds.outWidth
    val scale = decoded.width.toFloat() / frameWidth
    val pad = crop.longerSide * ScanLimits.CROP_PADDING_FACTOR
    val x1 = ((crop.x1 - pad) * scale).toInt().coerceIn(0, decoded.width - 1)
    val y1 = ((crop.y1 - pad) * scale).toInt().coerceIn(0, decoded.height - 1)
    val x2 = ((crop.x2 + pad) * scale).toInt().coerceIn(x1 + 1, decoded.width)
    val y2 = ((crop.y2 + pad) * scale).toInt().coerceIn(y1 + 1, decoded.height)
    val cut = Bitmap.createBitmap(decoded, x1, y1, x2 - x1, y2 - y1)
    return PhotoPart.Ready(cut.asImageBitmap())
}
