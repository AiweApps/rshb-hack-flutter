package com.aiweapps.winescan.scan.result.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.SvoeVinoMark
import com.aiweapps.winescan.domain.scan.model.WineCard

/**
 * One catalogue card: reference thumbnail, tag, title, producer, meta line and the link.
 * The best match gets an outlined card in the brand colour, the rest a tonal one; [footer]
 * adds a row of actions under the texts.
 */
@Composable
fun WineCardTile(
    card: WineCard,
    tag: String?,
    referenceUrl: String?,
    isBest: Boolean,
    onLinkClicked: (String) -> Unit,
    modifier: Modifier = Modifier,
    header: (@Composable () -> Unit)? = null,
    footer: (@Composable () -> Unit)? = null,
    onClick: (() -> Unit)? = null,
) {
    val body: @Composable () -> Unit = {
        Column {
            header?.invoke()
            Row(Modifier.padding(16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                if (header == null) {
                    AsyncImage(
                        model = referenceUrl,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp).clip(RoundedCornerShape(8.dp)),
                        contentScale = ContentScale.Fit,
                    )
                }
                CardTexts(card, tag, onLinkClicked, Modifier.weight(1f))
            }
            footer?.invoke()
        }
    }

    val cardModifier = modifier.fillMaxWidth()
    when {
        isBest -> OutlinedCard(
            modifier = cardModifier,
            border = BorderStroke(1.5.dp, MaterialTheme.colorScheme.primary),
        ) { body() }
        onClick != null -> Card(
            onClick = onClick,
            modifier = cardModifier,
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        ) { body() }
        else -> Card(
            modifier = cardModifier,
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        ) { body() }
    }
}

@Composable
private fun CardTexts(
    card: WineCard,
    tag: String?,
    onLinkClicked: (String) -> Unit,
    modifier: Modifier,
) {
    Column(modifier) {
        if (!tag.isNullOrEmpty()) {
            Text(tag, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
        }
        Text(card.presentationTitle, style = MaterialTheme.typography.titleMedium)
        card.producer?.takeIf { it.isNotEmpty() && !it.equals(card.presentationTitle, ignoreCase = true) }?.let {
            Text(it, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        card.metaLine.takeIf { it.isNotEmpty() }?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                overflow = TextOverflow.Ellipsis,
                maxLines = 2,
            )
        }
        val url = card.catalogueUrl
        if (url != null) {
            TextButton(onClick = { onLinkClicked(url) }, modifier = Modifier.padding(top = 4.dp)) {
                SvoeVinoMark(Modifier.padding(end = 8.dp))
                Text(stringResource(R.string.result_open_on_site))
                Icon(
                    imageVector = AppIcons.External,
                    contentDescription = null,
                    modifier = Modifier.padding(start = 6.dp).size(16.dp),
                )
            }
        } else {
            Text(
                text = stringResource(R.string.result_no_site_url),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 8.dp).fillMaxWidth(),
            )
        }
    }
}
