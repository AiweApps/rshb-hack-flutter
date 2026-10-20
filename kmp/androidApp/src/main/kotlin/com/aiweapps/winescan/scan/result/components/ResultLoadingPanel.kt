package com.aiweapps.winescan.scan.result.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.scan.result.model.ResultPhase
import com.aiweapps.winescan.components.scan.result.model.RetryReason
import com.aiweapps.winescan.components.scan.result.model.ScanResultState
import com.aiweapps.winescan.config.ApiConstants

private const val PREVIEW_MAX_SIDE = 1600
private const val BREATH_MILLIS = 1600
private const val BREATH_LOW = 0.55f
private val PhotoHeight = 320.dp

/**
 * The wait: the chosen photo stays on screen, breathing slowly, with one calm indeterminate
 * bar and one short caption. A retry countdown replaces the caption; there are no percentages.
 */
@Composable
fun ResultLoadingPanel(state: ScanResultState) {
    val waiting = state.phase == ResultPhase.WAITING_RETRY
    val caption = when {
        !waiting && state.isRoiRequest -> stringResource(R.string.loading_roi)
        !waiting -> stringResource(R.string.loading_reading)
        state.retryReason == RetryReason.BUSY -> stringResource(R.string.loading_busy)
        else -> stringResource(R.string.loading_too_many)
    }
    val breath by rememberInfiniteTransition(label = "breath").animateFloat(
        initialValue = 1f,
        targetValue = BREATH_LOW,
        animationSpec = infiniteRepeatable(tween(BREATH_MILLIS), RepeatMode.Reverse),
        label = "breathAlpha",
    )

    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        val part = rememberPhotoPart(state.photoPath, crop = null, frame = null, maxSide = PREVIEW_MAX_SIDE)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(PhotoHeight)
                .clip(RoundedCornerShape(16.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant),
        ) {
            if (part is PhotoPart.Ready) {
                Image(
                    bitmap = part.image,
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize().alpha(breath),
                    contentScale = ContentScale.Fit,
                )
            }
            state.geometryProgress?.let { com.aiweapps.winescan.local.ScanGeometryOverlay(it) }
        }
        LinearProgressIndicator(Modifier.fillMaxWidth())
        Text(
            text = caption,
            style = MaterialTheme.typography.titleMedium,
            textAlign = TextAlign.Center,
        )
        if (waiting) {
            Text(
                text = stringResource(
                    R.string.loading_retry_in,
                    state.retrySecondsLeft,
                    state.retryAttempt,
                    ApiConstants.MAX_AUTO_RETRIES,
                ),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
        }
    }
}
