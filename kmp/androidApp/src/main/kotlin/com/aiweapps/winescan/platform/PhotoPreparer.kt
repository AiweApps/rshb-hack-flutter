package com.aiweapps.winescan.platform

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import com.aiweapps.winescan.config.ScanLimits
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Turns whatever the camera or the picker produced into the JPEG the service expects: no
 * larger than [ScanLimits.UPLOAD_MAX_SIDE] on a side, and **upright in its pixels** — the
 * EXIF rotation is applied and dropped, so the frames the service answers with refer to
 * the picture as the user saw it.
 *
 * Returns `null` when the source cannot be decoded; the caller reports it as a failed
 * capture or pick.
 */
internal class PhotoPreparer(private val context: Context) {

    suspend fun prepare(source: Uri): String? = withContext(Dispatchers.IO) {
        try {
            val orientation = open(source)?.use { stream ->
                ExifInterface(stream).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
            } ?: ExifInterface.ORIENTATION_NORMAL
            // Bounds-only decoding returns no bitmap by design; the size is the answer.
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            open(source)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return@withContext null
            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight)
            }
            val decoded = open(source)?.use { BitmapFactory.decodeStream(it, null, options) } ?: return@withContext null
            val upright = rotate(decoded, orientation)
            val scaled = scaleDown(upright)
            write(scaled)
        } catch (_: IOException) {
            null
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private fun open(source: Uri): InputStream? = context.contentResolver.openInputStream(source)

    private fun sampleSize(width: Int, height: Int): Int {
        var sample = 1
        while (maxOf(width, height) / (sample * 2) >= ScanLimits.UPLOAD_MAX_SIDE) sample *= 2
        return sample
    }

    private fun rotate(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(ROTATE_90)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(ROTATE_180)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(ROTATE_270)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.preScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.preScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> matrix.postRotate(ROTATE_90).also { matrix.preScale(-1f, 1f) }
            ExifInterface.ORIENTATION_TRANSVERSE -> matrix.postRotate(ROTATE_270).also { matrix.preScale(-1f, 1f) }
            else -> return bitmap
        }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun scaleDown(bitmap: Bitmap): Bitmap {
        val longer = maxOf(bitmap.width, bitmap.height)
        if (longer <= ScanLimits.UPLOAD_MAX_SIDE) return bitmap
        val scale = ScanLimits.UPLOAD_MAX_SIDE.toFloat() / longer
        return Bitmap.createScaledBitmap(
            bitmap,
            (bitmap.width * scale).toInt().coerceAtLeast(1),
            (bitmap.height * scale).toInt().coerceAtLeast(1),
            true,
        )
    }

    private fun write(bitmap: Bitmap): String {
        val directory = File(context.cacheDir, PREPARED_DIRECTORY).apply { mkdirs() }
        val file = File(directory, "${System.currentTimeMillis()}$JPEG_EXTENSION")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, ScanLimits.UPLOAD_JPEG_QUALITY, out)
        }
        return file.absolutePath
    }

    private companion object {
        const val PREPARED_DIRECTORY = "prepared"
        const val JPEG_EXTENSION = ".jpg"
        const val ROTATE_90 = 90f
        const val ROTATE_180 = 180f
        const val ROTATE_270 = 270f
    }
}
