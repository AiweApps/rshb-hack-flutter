package com.aiweapps.winescan.scan.result.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.SvoeVinoMark
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.uikit.theme.AppDesign

/** The wine's name, the largest text of the answer, under an optional [tag], with the producer and «colour · region» below. */
@Composable
fun WineHeading(card: WineCard, tag: String?, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth().padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        if (!tag.isNullOrEmpty()) {
            Text(
                text = tag.uppercase(),
                style = MaterialTheme.typography.labelSmall,
                color = AppDesign.colors.gold,
            )
        }
        Text(text = card.presentationTitle, style = MaterialTheme.typography.headlineMedium)
        card.producer?.takeIf { it.isNotEmpty() && !it.equals(card.presentationTitle, ignoreCase = true) }?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        val line = listOfNotNull(card.category, card.region).filter { it.isNotEmpty() }.joinToString(" · ")
        if (line.isNotEmpty()) {
            Text(text = line, style = MaterialTheme.typography.bodyMedium, color = AppDesign.colors.muted)
        }
    }
}

/** The card's page on «Svoe Vino» as a row, or a note when the catalogue gives no address. */
@Composable
fun CatalogueLinkRow(card: WineCard, onLinkClicked: (String) -> Unit) {
    val url = card.catalogueUrl
    if (url == null) {
        Text(
            text = stringResource(R.string.result_no_site_url),
            style = MaterialTheme.typography.bodySmall,
            color = AppDesign.colors.muted,
        )
        return
    }
    Surface(
        modifier = Modifier.fillMaxWidth().clickable { onLinkClicked(url) },
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surfaceContainerLow,
    ) {
        Row(
            modifier = Modifier.heightIn(min = 56.dp).padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            SvoeVinoMark(Modifier.padding(end = 12.dp))
            Text(
                text = stringResource(R.string.action_open_catalogue),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.weight(1f),
            )
            Icon(
                imageVector = AppIcons.External,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp),
            )
        }
    }
}
