package com.aiweapps.winescan.history.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.domain.history.model.ScanHistoryItem
import com.aiweapps.winescan.uikit.theme.AppDesign
import java.io.File

/**
 * One stored scan: thumbnail, best match, producer and bottle count, which open the scan;
 * and, for a scan that found a wine, a heart for «My wines» and the compare toggle. Swipe
 * left to delete.
 */
@Composable
fun HistoryTile(
    item: ScanHistoryItem,
    isFavorite: Boolean,
    isInCompare: Boolean,
    onClick: () -> Unit,
    onFavoriteClicked: () -> Unit,
    onCompareClicked: () -> Unit,
    onDismissed: () -> Unit,
) {
    DismissToDelete(onDismissed = onDismissed) {
        ListItem(
            modifier = Modifier
                .background(MaterialTheme.colorScheme.background)
                .clickable(onClick = onClick),
            colors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.background),
            leadingContent = {
                AsyncImage(
                    model = File(item.photoPath),
                    contentDescription = null,
                    modifier = Modifier.size(64.dp).clip(RoundedCornerShape(12.dp)),
                    contentScale = ContentScale.Crop,
                )
            },
            headlineContent = {
                Text(
                    text = item.presentationTitle ?: stringResource(R.string.history_no_match),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            },
            supportingContent = {
                val bottles = pluralStringResource(R.plurals.history_bottles_count, item.bottleCount, item.bottleCount)
                Text(
                    text = listOfNotNull(
                        item.bestProducer?.takeUnless { it.equals(item.presentationTitle, ignoreCase = true) },
                        bottles,
                    ).joinToString(" · "),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            },
            trailingContent = if (item.bestSlug != null) {
                {
                    Row {
                        FavoriteToggle(isFavorite = isFavorite, onClick = onFavoriteClicked)
                        CompareToggle(isInCompare = isInCompare, onClick = onCompareClicked)
                    }
                }
            } else {
                null
            },
        )
    }
}

@Composable
private fun FavoriteToggle(isFavorite: Boolean, onClick: () -> Unit) {
    val haptics = LocalHapticFeedback.current
    IconButton(onClick = {
        haptics.performHapticFeedback(if (isFavorite) HapticFeedbackType.ToggleOff else HapticFeedbackType.ToggleOn)
        onClick()
    }) {
        Icon(
            imageVector = if (isFavorite) AppIcons.FavoriteFilled else AppIcons.Favorite,
            contentDescription = stringResource(if (isFavorite) R.string.assistant_unsave_wine else R.string.assistant_save_wine),
            tint = if (isFavorite) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun CompareToggle(isInCompare: Boolean, onClick: () -> Unit) {
    val haptics = LocalHapticFeedback.current
    val onToggle = {
        haptics.performHapticFeedback(if (isInCompare) HapticFeedbackType.ToggleOff else HapticFeedbackType.ToggleOn)
        onClick()
    }
    if (isInCompare) {
        FilledTonalIconButton(onClick = onToggle) {
            Icon(AppIcons.Check, contentDescription = stringResource(R.string.action_in_compare))
        }
    } else {
        IconButton(onClick = onToggle) {
            Icon(
                imageVector = AppIcons.Compare,
                contentDescription = stringResource(R.string.action_add_to_compare),
                tint = AppDesign.colors.muted,
            )
        }
    }
}
