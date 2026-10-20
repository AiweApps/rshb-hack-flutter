package com.aiweapps.winescan.scan.home.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.aiweapps.winescan.R
import com.aiweapps.winescan.domain.history.model.ScanHistoryItem
import java.io.File

private val PanelShape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)
private val CardSize = 100.dp
private val ThumbShape = RoundedCornerShape(16.dp)
private val HeaderMinHeight = 48.dp

/**
 * The recent scans docked to the bottom of the tab: a header with «All» and one horizontal
 * row of cards. It looks like a resting sheet but does not move; the full list is the
 * History tab, which «All» opens.
 */
@Composable
internal fun RecentScansPanel(
    items: List<ScanHistoryItem>,
    onItemClicked: (Long) -> Unit,
    onAllClicked: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = PanelShape,
        color = MaterialTheme.colorScheme.surface,
        shadowElevation = 6.dp,
    ) {
        Column(Modifier.padding(top = 8.dp, bottom = 16.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = HeaderMinHeight)
                    .padding(start = 20.dp, end = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text(
                    text = stringResource(R.string.scan_recent_title),
                    style = MaterialTheme.typography.titleMedium,
                )
                TextButton(onClick = onAllClicked) { Text(stringResource(R.string.scan_recent_all)) }
            }
            LazyRow(
                modifier = Modifier.padding(top = 4.dp),
                contentPadding = PaddingValues(horizontal = 20.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(items, key = { it.id }) { item ->
                    RecentScanCard(item = item, onClick = { onItemClicked(item.id) })
                }
            }
        }
    }
}

@Composable
private fun RecentScanCard(item: ScanHistoryItem, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .width(CardSize)
            .clip(ThumbShape)
            .clickable(onClick = onClick),
    ) {
        AsyncImage(
            model = File(item.photoPath),
            contentDescription = null,
            modifier = Modifier
                .size(CardSize)
                .clip(ThumbShape)
                .background(MaterialTheme.colorScheme.surfaceVariant),
            contentScale = ContentScale.Crop,
        )
        Text(
            text = item.bestTitle ?: stringResource(R.string.history_no_match),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(top = 6.dp),
        )
    }
}
