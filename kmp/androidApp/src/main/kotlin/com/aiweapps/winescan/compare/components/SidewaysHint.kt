package com.aiweapps.winescan.compare.components

import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.layout
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.uikit.theme.AppDesign

private const val MIN_THUMB_SHARE = 0.2f

/** The note and the scroll position bar shown above a table that scrolls sideways. */
@Composable
fun SidewaysHint(scrollState: ScrollState, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            text = stringResource(R.string.compare_scroll_hint),
            style = MaterialTheme.typography.labelMedium,
            color = AppDesign.colors.muted,
        )
        Box(
            Modifier
                .fillMaxWidth()
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(MaterialTheme.colorScheme.outlineVariant),
        ) {
            // The thumb is as wide as the visible share of the content, pinned to the scroll position.
            val max = scrollState.maxValue
            val progress = if (max > 0) scrollState.value.toFloat() / max else 0f
            val visibleShare = if (max > 0) scrollState.viewportSize.toFloat() / (scrollState.viewportSize + max) else 1f
            Box(
                Modifier
                    .layout { measurable, constraints ->
                        val thumbWidth = (constraints.maxWidth * visibleShare.coerceIn(MIN_THUMB_SHARE, 1f)).toInt()
                        val placeable = measurable.measure(constraints.copy(minWidth = thumbWidth, maxWidth = thumbWidth))
                        layout(constraints.maxWidth, placeable.height) {
                            placeable.place(((constraints.maxWidth - thumbWidth) * progress).toInt(), 0)
                        }
                    }
                    .height(4.dp)
                    .background(MaterialTheme.colorScheme.primary),
            )
        }
    }
}

