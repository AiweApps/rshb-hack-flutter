package com.aiweapps.winescan.scan.result.components

import androidx.annotation.StringRes
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.core.error.AppError
import com.aiweapps.winescan.components.FactPlaceholder
import com.aiweapps.winescan.components.SectionCard
import com.aiweapps.winescan.components.colorText
import com.aiweapps.winescan.components.sugarText
import com.aiweapps.winescan.components.temperatureText
import com.aiweapps.winescan.components.alcoholText
import com.aiweapps.winescan.components.common.model.WineFacts
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.uikit.theme.AppDesign
import com.aiweapps.winescan.error.asText

private const val PLACEHOLDER_CHIPS = 3

/**
 * «About the wine»: colour, sugar, grapes, region, serving. Colour, sugar and serving come
 * from [facts]: while they load ([isLoading]) a placeholder stands in; what the catalogue
 * lacks says «No data».
 */
@Composable
fun WineAboutCard(
    card: WineCard,
    facts: WineFacts?,
    isLoading: Boolean,
    modifier: Modifier = Modifier,
    loadError: AppError? = null,
) {
    val isPending = facts == null && isLoading
    val rows = listOfNotNull(
        AboutRowData(R.string.result_attr_color, colorText(facts?.color, facts?.isSparkling), isPending, loadError != null),
        AboutRowData(R.string.result_attr_sugar, sugarText(facts?.sugar), isPending, loadError != null),
        card.validAlcohol?.let { AboutRowData(R.string.compare_attr_alcohol, alcoholText(it), false) },
        AboutRowData(R.string.result_attr_grapes, card.grapes?.takeIf { it.isNotBlank() }, false),
        AboutRowData(R.string.result_attr_region, card.region?.takeIf { it.isNotBlank() }, false),
        AboutRowData(R.string.result_attr_serving, temperatureText(facts?.servingTemperature), isPending, loadError != null),
    )
    SectionCard(title = stringResource(R.string.result_about), modifier = modifier) {
        rows.forEachIndexed { index, row ->
            if (index > 0) HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
            AboutRow(label = stringResource(row.label), value = row.value, isPending = row.isPending,
                isUnavailable = row.isUnavailable)
        }
    }
}

private class AboutRowData(
    @field:StringRes val label: Int,
    val value: String?,
    val isPending: Boolean,
    val isUnavailable: Boolean = false,
)

@Composable
private fun AboutRow(label: String, value: String?, isPending: Boolean, isUnavailable: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp).padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        if (isPending) {
            Box(Modifier.weight(1f), contentAlignment = Alignment.CenterEnd) { FactPlaceholder() }
        } else {
            Text(
                text = value ?: stringResource(if (isUnavailable) R.string.gastro_unavailable else R.string.common_no_data),
                style = MaterialTheme.typography.bodyLarge,
                color = if (value == null) AppDesign.colors.muted else MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.End,
                modifier = Modifier.weight(1f),
            )
        }
    }
}

/**
 * «Food pairings»: the dishes as chips, with the source underneath. `null` pairings say
 * «No data», an empty list says the catalogue lists none, and while loading ([isLoading]) a
 * placeholder stands in.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun WinePairingsCard(
    facts: WineFacts?,
    isLoading: Boolean,
    modifier: Modifier = Modifier,
    loadError: AppError? = null,
) {
    val pairings = facts?.pairings
    SectionCard(title = stringResource(R.string.result_pairings), modifier = modifier) {
        FlowRow(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            when {
                facts == null && isLoading -> repeat(PLACEHOLDER_CHIPS) { FactPlaceholder(width = 88.dp, height = 32.dp) }
                pairings == null -> NoticeText(stringResource(
                    if (loadError != null) R.string.gastro_unavailable else R.string.common_no_data
                ))
                pairings.isEmpty() -> NoticeText(stringResource(R.string.result_pairings_none))
                else -> pairings.forEach { StaticChip(it.label) }
            }
        }
        Text(
            text = stringResource(R.string.result_pairings_caption),
            style = MaterialTheme.typography.bodySmall,
            color = AppDesign.colors.muted,
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 12.dp),
        )
    }
}

/** Secondary catalogue failure keeps the result and existing facts visible. */
@Composable
fun WineFactsError(error: AppError, isLoading: Boolean, onRetry: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(stringResource(R.string.gastro_load_failed), style = MaterialTheme.typography.titleSmall)
            Text(error.asText(), style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        TextButton(onClick = onRetry, enabled = !isLoading) {
            if (isLoading) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp)
            else Text(stringResource(R.string.common_retry))
        }
    }
}

@Composable
fun WineDescription(card: WineCard) {
    card.description?.takeIf { it.isNotBlank() }?.let { description ->
        SectionCard(title = stringResource(R.string.wine_description)) {
            Text(description, style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(16.dp))
        }
    }
}

@Composable
private fun NoticeText(text: String) {
    Text(text = text, style = MaterialTheme.typography.bodyLarge, color = AppDesign.colors.muted)
}

@Composable
private fun StaticChip(text: String) {
    Surface(
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.surfaceContainerLow,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 6.dp),
        )
    }
}
