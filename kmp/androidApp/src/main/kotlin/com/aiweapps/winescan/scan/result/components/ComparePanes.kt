package com.aiweapps.winescan.scan.result.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.aiweapps.winescan.R
import com.aiweapps.winescan.domain.scan.model.BottleBox

private const val PREVIEW_MAX_SIDE = 1024
private const val EXPAND_BACKDROP_ALPHA = 0.9f
private val BlockHeight = 300.dp

/**
 * The bottle cut from the user's photo beside the catalogue reference, as one big block.
 * The corner button opens the full-size comparison.
 */
@Composable
fun ComparePanes(
    photoPath: String,
    crop: BottleBox?,
    frame: List<Int>?,
    referenceUrl: String?,
    onExpandClicked: () -> Unit,
) {
    val part = rememberPhotoPart(photoPath, crop, frame, PREVIEW_MAX_SIDE)

    Box(Modifier.fillMaxWidth().height(BlockHeight).clip(RoundedCornerShape(16.dp))) {
        Row(Modifier.fillMaxSize()) {
            Pane(
                modifier = Modifier.weight(1f),
                caption = stringResource(R.string.result_photo_caption_mine),
                background = MaterialTheme.colorScheme.surfaceVariant,
            ) {
                when (part) {
                    PhotoPart.Loading -> CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp)
                    PhotoPart.Missing -> PaneNote(stringResource(R.string.result_photo_missing))
                    is PhotoPart.Ready -> Image(
                        bitmap = part.image,
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Fit,
                    )
                }
            }
            Pane(
                modifier = Modifier.weight(1f),
                caption = stringResource(R.string.result_photo_caption_reference),
                background = MaterialTheme.colorScheme.surfaceContainerLow,
            ) {
                if (referenceUrl == null) {
                    PaneNote(stringResource(R.string.result_reference_missing))
                } else {
                    AsyncImage(
                        model = referenceUrl,
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Fit,
                    )
                }
            }
        }
        IconButton(
            onClick = onExpandClicked,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(4.dp)
                .size(40.dp)
                .background(MaterialTheme.colorScheme.surface.copy(alpha = EXPAND_BACKDROP_ALPHA), CircleShape),
        ) {
            Icon(
                imageVector = AppIcons.Expand,
                contentDescription = stringResource(R.string.result_expand_compare),
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp),
            )
        }
    }
}

@Composable
private fun Pane(
    modifier: Modifier,
    caption: String,
    background: Color,
    content: @Composable () -> Unit,
) {
    Column(
        modifier = modifier.fillMaxSize().background(background).padding(top = 12.dp, bottom = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(Modifier.weight(1f).fillMaxWidth().padding(horizontal = 8.dp), contentAlignment = Alignment.Center) {
            content()
        }
        Text(
            text = caption,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun PaneNote(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        textAlign = TextAlign.Center,
        modifier = Modifier.padding(8.dp),
    )
}
