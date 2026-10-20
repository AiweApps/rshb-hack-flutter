package com.aiweapps.winescan.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.scan.result.components.PhotoPart
import com.aiweapps.winescan.scan.result.components.rememberPhotoPart

private const val THUMB_MAX_SIDE = 512

/** The bottle cut from the user's photo (the whole photo when [crop] is `null`), filling its box. */
@Composable
fun PhotoCropImage(
    photoPath: String,
    crop: BottleBox?,
    frame: List<Int>?,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Fit,
    maxSide: Int = THUMB_MAX_SIDE,
) {
    val part = rememberPhotoPart(photoPath, crop, frame, maxSide)
    Box(modifier, contentAlignment = Alignment.Center) {
        when (part) {
            PhotoPart.Loading -> CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
            PhotoPart.Missing -> Unit
            is PhotoPart.Ready -> Image(
                bitmap = part.image,
                contentDescription = null,
                modifier = Modifier.matchParentSize(),
                contentScale = contentScale,
            )
        }
    }
}
