package com.aiweapps.winescan.history.components

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.history.HistoryComponent
import com.aiweapps.winescan.components.history.model.HistoryState

// Room under the last row so the «Compare · N» pill never covers it.
private val PillClearance = 88.dp

/** The saved choices on top, then the scans grouped by day. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun HistoryList(state: HistoryState, component: HistoryComponent) {
    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(bottom = PillClearance)) {
        if (state.savedPairings.isNotEmpty()) {
            item(key = "saved-header") {
                Text(
                    text = stringResource(R.string.history_saved_pairings).uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 8.dp),
                )
            }
            items(state.savedPairings, key = { "saved-${it.id}" }) { pairing ->
                SavedPairingCard(
                    pairing = pairing,
                    dishLabel = state.dishLabelOf(pairing),
                    onClick = { component.onSavedPairingClicked(pairing.id) },
                    onDismissed = { component.onSavedPairingDismissed(pairing.id) },
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
                )
            }
        }
        state.sections.forEach { section ->
            stickyHeader(key = "header-${section.day}") { HistoryDayHeader(section.day) }
            items(section.items, key = { it.id }) { item ->
                HistoryTile(
                    item = item,
                    isFavorite = state.isFavorite(item),
                    isInCompare = state.isInCompare(item),
                    onClick = { component.onScanClicked(item.id) },
                    onFavoriteClicked = { component.onFavoriteClicked(item.id) },
                    onCompareClicked = { component.onCompareClicked(item.id) },
                    onDismissed = { component.onScanDismissed(item.id) },
                )
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
            }
        }
    }
}
