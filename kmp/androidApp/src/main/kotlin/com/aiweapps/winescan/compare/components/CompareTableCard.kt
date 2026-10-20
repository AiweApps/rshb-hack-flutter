package com.aiweapps.winescan.compare.components

import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.components.SectionCard
import com.aiweapps.winescan.domain.compare.model.CompareRow
import com.aiweapps.winescan.uikit.theme.AppDesign

internal val LabelColumnWidth = 88.dp
internal val SidewaysCellWidth = 156.dp

/**
 * A card of table rows. With two wines the cells share the width; with more the label
 * column stays and the cells scroll sideways together through the shared [scrollState].
 */
@Composable
fun CompareTableCard(
    title: String,
    rows: List<CompareRow>,
    scrollsSideways: Boolean,
    scrollState: ScrollState,
) {
    SectionCard(title = title) {
        rows.forEachIndexed { index, row ->
            if (index > 0) HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
            if (scrollsSideways) {
                SidewaysRow(row, scrollState)
            } else {
                SideBySideRow(row)
            }
        }
    }
}

@Composable
private fun SideBySideRow(row: CompareRow) {
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp)) {
        Text(
            text = row.attribute.label(),
            style = MaterialTheme.typography.labelMedium,
            color = AppDesign.colors.muted,
            modifier = Modifier.padding(bottom = 4.dp),
        )
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            row.values.forEach { CompareCell(it, Modifier.weight(1f)) }
        }
    }
}

@Composable
private fun SidewaysRow(row: CompareRow, scrollState: ScrollState) {
    Row(Modifier.fillMaxWidth().padding(vertical = 10.dp)) {
        Text(
            text = row.attribute.label(),
            style = MaterialTheme.typography.labelMedium,
            color = AppDesign.colors.muted,
            modifier = Modifier.width(LabelColumnWidth).padding(start = 16.dp, end = 8.dp),
        )
        Row(
            modifier = Modifier.weight(1f).horizontalScroll(scrollState),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            row.values.forEach { CompareCell(it, Modifier.width(SidewaysCellWidth)) }
            // Room after the last cell so it can scroll clear of the card edge.
            Spacer(Modifier.width(4.dp))
        }
    }
}
