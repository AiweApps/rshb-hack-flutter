package com.aiweapps.winescan.compare.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.domain.compare.model.CompareEntry
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.uikit.theme.AppTheme

private val PreviewEntries = listOf(
    CompareEntry(
        card = WineCard(
            slug = "tamara-2023",
            title = "Тамара Красное сухое",
            producer = "Усадьба Дивноморское",
            description = "Насыщенное красное вино из саперави с нотами тёмных ягод и специй.",
            pageUrl = "https://vino.svoe.ru/wines/tamara-2023",
        ),
        crop = null,
        frame = null,
        scanId = 1L,
        addedAtMillis = 0L,
    ),
    CompareEntry(
        card = WineCard(slug = "bare", title = "Безымянное вино"),
        crop = null,
        frame = null,
        scanId = null,
        addedAtMillis = 0L,
    ),
)

@Composable
private fun ComparePreview(isDark: Boolean, content: @Composable () -> Unit) {
    AppTheme(isDark = isDark) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) { content() }
    }
}

@Preview(name = "Entry cards", showBackground = true, widthDp = 412)
@Composable
private fun CompareEntryCardsPreview() = ComparePreview(isDark = false) {
    PreviewEntries.forEachIndexed { index, entry ->
        CompareEntryCard(
            entry = entry,
            ordinal = index + 1,
            referenceUrl = null,
            onRemoveClicked = {},
            onLinkClicked = {},
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Preview(name = "Empty and one wine, dark", showBackground = true, widthDp = 412, heightDp = 640)
@Composable
private fun CompareEmptyDarkPreview() = ComparePreview(isDark = true) {
    CompareNeedSecondCard(onPickFromHistoryClicked = {}, onScanClicked = {})
    CompareBottomActions(canPairDish = true, onPlanDinnerClicked = {}, onPairDishClicked = {})
}

@Preview(name = "Empty set", showBackground = true, widthDp = 412, heightDp = 640)
@Composable
private fun CompareEmptyPreview() = AppTheme(isDark = false) {
    CompareEmpty(onPickFromHistoryClicked = {}, onScanClicked = {})
}
