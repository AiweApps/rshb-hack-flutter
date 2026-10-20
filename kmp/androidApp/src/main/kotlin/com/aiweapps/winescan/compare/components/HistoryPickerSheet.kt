package com.aiweapps.winescan.compare.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.EmptyState
import com.aiweapps.winescan.components.ErrorState
import com.aiweapps.winescan.components.LoadingState
import com.aiweapps.winescan.components.compare.picker.HistoryPickerComponent
import com.aiweapps.winescan.domain.history.model.ScanHistoryItem
import com.arkivanov.decompose.extensions.compose.subscribeAsState
import java.io.File

private val SheetBodyMinHeight = 240.dp

/** The stored scans with a match; a tap hands the scan to the comparison. */
@Composable
fun HistoryPickerSheet(component: HistoryPickerComponent) {
    val state by component.state.subscribeAsState()

    Text(
        text = stringResource(R.string.compare_picker_title),
        style = MaterialTheme.typography.titleLarge,
        modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
    )
    Box(Modifier.fillMaxWidth().heightIn(min = SheetBodyMinHeight)) {
        when (val screenState = state.screenState) {
            is ScreenState.Loading -> LoadingState()
            is ScreenState.Error -> ErrorState(error = screenState.error)
            is ScreenState.Content ->
                if (state.items.isEmpty()) {
                    EmptyState(message = stringResource(R.string.compare_picker_empty))
                } else {
                    LazyColumn {
                        items(state.items, key = { it.id }) { item ->
                            PickerRow(
                                item = item,
                                isInCompare = state.isInCompare(item),
                                onClick = { component.onScanClicked(item.id) },
                            )
                        }
                    }
                }
        }
    }
}

@Composable
private fun PickerRow(item: ScanHistoryItem, isInCompare: Boolean, onClick: () -> Unit) {
    ListItem(
        modifier = Modifier.clickable(onClick = onClick),
        colors = ListItemDefaults.colors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
        leadingContent = {
            AsyncImage(
                model = File(item.photoPath),
                contentDescription = null,
                modifier = Modifier.size(56.dp).clip(RoundedCornerShape(12.dp)),
                contentScale = ContentScale.Crop,
            )
        },
        headlineContent = {
            Text(text = item.presentationTitle.orEmpty(), maxLines = 2, overflow = TextOverflow.Ellipsis)
        },
        supportingContent = item.bestProducer?.takeUnless {
            it.equals(item.presentationTitle, ignoreCase = true)
        }?.let { producer ->
            { Text(text = producer, maxLines = 1, overflow = TextOverflow.Ellipsis) }
        },
        trailingContent = if (isInCompare) {
            { Icon(AppIcons.Check, contentDescription = stringResource(R.string.action_in_compare)) }
        } else {
            null
        },
    )
}
