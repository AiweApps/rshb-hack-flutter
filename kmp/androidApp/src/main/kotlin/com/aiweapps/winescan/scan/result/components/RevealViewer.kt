package com.aiweapps.winescan.scan.result.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.aiweapps.winescan.R
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.uikit.theme.AppDesign
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

private const val SNAP_ZONE = 0.06f
private const val SNAP_MILLIS = 280
private const val TAG_BACKDROP_ALPHA = 0.6f
private val HandleSize = 48.dp
private val LineWidth = 3.dp

/** Where the divider rests, as the share of the frame the user's photo covers. */
enum class RevealStop(val share: Float) { MINE(1f), BOTH(0.5f), REFERENCE(0f) }

/** State of the reveal: the divider position, animated by the segmented control and set by dragging. */
class RevealState(val position: Animatable<Float, *>)

@Composable
fun rememberRevealState(): RevealState = remember { RevealState(Animatable(RevealStop.BOTH.share)) }

/**
 * The photo and the reference fitted into one frame by height and centred, the photo on
 * top, cut at a draggable vertical divider. Pinch and pan move both layers together.
 */
@Composable
fun RevealViewer(
    photoPath: String,
    crop: BottleBox?,
    frame: List<Int>?,
    referenceUrl: String?,
    reveal: RevealState,
    maxSide: Int,
    modifier: Modifier = Modifier,
) {
    val part = rememberPhotoPart(photoPath, crop, frame, maxSide)
    val zoom = rememberZoomState()
    val haptics = rememberRevealHaptics()
    val scope = rememberCoroutineScope()
    var width by remember { mutableIntStateOf(0) }
    // The finger's unsnapped position, so the soft snap does not eat drag distance.
    var raw by remember { mutableFloatStateOf(reveal.position.value) }
    var snappedTo by remember { mutableFloatStateOf(Float.NaN) }

    LaunchedEffect(reveal.position.isRunning) {
        if (!reveal.position.isRunning) raw = reveal.position.value
    }

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .onSizeChanged { width = it.width }
            .zoomGestures(zoom),
    ) {
        Box(Modifier.fillMaxSize().zoomLayer(zoom), contentAlignment = Alignment.Center) {
            if (referenceUrl == null) {
                Text(stringResource(R.string.result_reference_missing), color = AppDesign.colors.muted)
            } else {
                AsyncImage(
                    model = referenceUrl,
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.FillHeight,
                )
            }
        }
        // The photo layer is cut in screen space, outside the zoom, so the cut follows the divider.
        Box(
            Modifier
                .fillMaxSize()
                .drawWithContent {
                    clipRect(right = size.width * reveal.position.value) { this@drawWithContent.drawContent() }
                },
        ) {
            Box(Modifier.fillMaxSize().zoomLayer(zoom).background(MaterialTheme.colorScheme.surfaceContainerHigh), Alignment.Center) {
                when (part) {
                    PhotoPart.Loading -> CircularProgressIndicator()
                    PhotoPart.Missing -> Text(stringResource(R.string.result_photo_missing), color = AppDesign.colors.muted)
                    is PhotoPart.Ready -> Image(
                        bitmap = part.image,
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.FillHeight,
                    )
                }
            }
        }
        Tag(stringResource(R.string.reveal_mine), Modifier.align(Alignment.TopStart))
        Tag(stringResource(R.string.reveal_reference), Modifier.align(Alignment.TopEnd))

        DividerHandle(
            positionPx = { reveal.position.value * width },
            description = stringResource(R.string.reveal_handle),
            onDragStart = {
                scope.launch { reveal.position.stop() }
                raw = reveal.position.value
                haptics.gestureStart()
            },
            onDrag = { dx ->
                if (width > 0) {
                    raw = (raw + dx / width).coerceIn(0f, 1f)
                    val stop = RevealStop.entries.firstOrNull { abs(raw - it.share) < SNAP_ZONE }?.share
                    val shown = stop ?: raw
                    if (stop != null && stop != snappedTo) haptics.segmentTick()
                    snappedTo = stop ?: Float.NaN
                    scope.launch { reveal.position.snapTo(shown) }
                }
            },
            onDragEnd = { haptics.gestureEnd() },
        )
    }
}

/** Moves the divider to [stop] with a short animation and the context-click haptic. */
fun RevealState.animateTo(stop: RevealStop, scope: CoroutineScope, haptics: RevealHaptics) {
    haptics.contextClick()
    scope.launch { position.animateTo(stop.share, tween(SNAP_MILLIS)) }
}

@Composable
private fun Tag(text: String, modifier: Modifier) {
    Surface(
        modifier = modifier.padding(12.dp),
        shape = RoundedCornerShape(8.dp),
        color = AppDesign.colors.scrim.copy(alpha = TAG_BACKDROP_ALPHA),
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelMedium,
            color = AppDesign.colors.onPhoto,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
        )
    }
}

@Composable
private fun DividerHandle(
    positionPx: () -> Float,
    description: String,
    onDragStart: () -> Unit,
    onDrag: (Float) -> Unit,
    onDragEnd: () -> Unit,
) {
    Box(
        modifier = Modifier
            .offset { IntOffset((positionPx() - HandleSize.toPx() / 2f).roundToInt(), 0) }
            .width(HandleSize)
            .fillMaxHeight()
            .pointerInput(Unit) {
                detectHorizontalDragGestures(
                    onDragStart = { onDragStart() },
                    onDragEnd = onDragEnd,
                    onDragCancel = onDragEnd,
                    onHorizontalDrag = { change, dx ->
                        change.consume()
                        onDrag(dx)
                    },
                )
            },
        contentAlignment = Alignment.Center,
    ) {
        Box(Modifier.width(LineWidth).fillMaxHeight().background(AppDesign.colors.onPhoto))
        Surface(shape = CircleShape, color = AppDesign.colors.onPhoto, shadowElevation = 4.dp) {
            Icon(
                imageVector = AppIcons.Unfold,
                contentDescription = description,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(12.dp).size(24.dp),
            )
        }
    }
}
