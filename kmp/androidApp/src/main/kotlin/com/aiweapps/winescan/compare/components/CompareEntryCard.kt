package com.aiweapps.winescan.compare.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.components.PhotoCropImage
import com.aiweapps.winescan.components.SvoeVinoMark
import com.aiweapps.winescan.domain.compare.model.CompareEntry

/**
 * One wine of the set as a full-width row: its photo with the ordinal the table columns
 * repeat, name, producer and the remove button; the description and the catalogue link
 * unfold on demand.
 */
@Composable
fun CompareEntryCard(
    entry: CompareEntry,
    ordinal: Int,
    referenceUrl: String?,
    onRemoveClicked: () -> Unit,
    onLinkClicked: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    var referenceFailed by remember(referenceUrl) { mutableStateOf(false) }
    var expanded by rememberSaveable(entry.slug) { mutableStateOf(false) }
    val description = entry.card.description?.takeIf { it.isNotBlank() }
    val catalogueUrl = entry.card.catalogueUrl
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surfaceContainerLow,
    ) {
        Column(Modifier.padding(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    Modifier
                        .width(48.dp)
                        .heightIn(min = 64.dp, max = 64.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant),
                ) {
                    val photoPath = entry.photoPath
                    if (photoPath != null) {
                        PhotoCropImage(
                            photoPath = photoPath,
                            crop = entry.crop,
                            frame = entry.frame,
                            modifier = Modifier.matchParentSize(),
                        )
                    } else if (referenceUrl != null && !referenceFailed) {
                        // A wine added without a photo of its own shows the catalogue bottle.
                        AsyncImage(
                            model = referenceUrl,
                            contentDescription = entry.card.presentationTitle,
                            contentScale = ContentScale.Fit,
                            modifier = Modifier.matchParentSize().padding(4.dp),
                            onError = { referenceFailed = true },
                        )
                    } else {
                        Icon(
                            imageVector = AppIcons.Wine,
                            contentDescription = entry.card.presentationTitle,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.align(Alignment.Center).size(28.dp),
                        )
                    }
                    CompareWineOrdinal(ordinal, Modifier.align(Alignment.TopStart))
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(
                        text = entry.card.presentationTitle,
                        style = MaterialTheme.typography.titleSmall,
                    )
                    entry.card.producer?.takeIf {
                        it.isNotBlank() && !entry.card.presentationTitle.equals(it, ignoreCase = true)
                    }?.let { producer ->
                        Text(
                            text = producer,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
                if (description != null || catalogueUrl != null) {
                    IconButton(onClick = { expanded = !expanded }) {
                        Icon(
                            imageVector = if (expanded) AppIcons.ChevronUp else AppIcons.ChevronDown,
                            contentDescription = stringResource(
                                if (expanded) R.string.compare_hide_description else R.string.compare_description,
                            ),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
                IconButton(onClick = onRemoveClicked) {
                    Icon(
                        imageVector = AppIcons.Close,
                        contentDescription = stringResource(R.string.compare_remove),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            if (expanded) {
                description?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 4.dp),
                    )
                }
                catalogueUrl?.let { url ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 48.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .clickable { onLinkClicked(url) }
                            .padding(horizontal = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        SvoeVinoMark()
                        Text(
                            text = stringResource(R.string.action_open_catalogue),
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.weight(1f),
                        )
                        Icon(
                            imageVector = AppIcons.External,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(16.dp),
                        )
                    }
                }
            }
        }
    }
}

/** The wine's number, shared by its row and its table column. */
@Composable
internal fun CompareWineOrdinal(ordinal: Int, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier.size(20.dp),
        shape = CircleShape,
        color = MaterialTheme.colorScheme.surfaceContainerHigh,
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = ordinal.toString(),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

/** A table column's heading: the wine's number and name. */
@Composable
internal fun CompareColumnTitle(ordinal: Int, title: String, modifier: Modifier = Modifier) {
    Row(modifier = modifier, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        CompareWineOrdinal(ordinal)
        Text(
            text = title,
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
    }
}
