package com.aiweapps.winescan.scan.result.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.SheetHeader
import com.aiweapps.winescan.components.scan.result.model.TechKey
import com.aiweapps.winescan.components.scan.result.model.TechRow
import com.aiweapps.winescan.components.scan.result.model.TechValue
import com.aiweapps.winescan.components.scan.result.sheets.TechDetailsComponent
import java.util.Locale

private const val MILLIS_IN_SECOND = 1000.0

/** The raw fields of the answer, for whoever reviews the recognition. Text is selectable. */
@Composable
fun TechDetailsSheet(component: TechDetailsComponent) {
    Column(Modifier.fillMaxWidth().navigationBarsPadding().padding(horizontal = 24.dp)) {
        SheetHeader(title = stringResource(R.string.result_tech_details), onClose = component::onCloseClicked)
        SelectionContainer(Modifier.weight(1f, fill = false).padding(bottom = 16.dp)) {
            Column(Modifier.verticalScroll(rememberScrollState()).padding(vertical = 12.dp)) {
                component.rows.forEach { TechRowItem(it) }
            }
        }
    }
}

@Composable
private fun TechRowItem(row: TechRow) {
    Column(Modifier.padding(vertical = 6.dp)) {
        Text(
            text = stringResource(row.key.labelRes()),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(
            text = row.value.text(),
            style = MaterialTheme.typography.bodyMedium,
            fontFamily = FontFamily.Monospace,
        )
    }
}

@Composable
private fun TechValue.text(): String {
    val locale = LocalConfiguration.current.locales[0] ?: Locale.getDefault()
    return when (this) {
        is TechValue.Text -> text
        TechValue.None -> stringResource(R.string.tech_none)
        TechValue.SnapshotYes -> stringResource(R.string.tech_snapshot_yes)
        TechValue.SnapshotNo -> stringResource(R.string.tech_snapshot_no)
        TechValue.ProbabilityNotCalculated -> stringResource(R.string.tech_probability_value)
        is TechValue.File -> stringResource(R.string.tech_file_value, format, bytes)
        is TechValue.Milliseconds ->
            stringResource(R.string.tech_seconds, String.format(locale, "%.1f", millis / MILLIS_IN_SECOND))
    }
}

private fun TechKey.labelRes(): Int = when (this) {
    TechKey.DECISION -> R.string.tech_decision
    TechKey.PRIMARY_BASIS -> R.string.tech_primary_basis
    TechKey.MODE -> R.string.tech_mode
    TechKey.RAW_SLUG -> R.string.tech_raw_slug
    TechKey.BEST_CANDIDATE -> R.string.tech_best_candidate
    TechKey.CARD_SLUG -> R.string.tech_card_slug
    TechKey.PAGE_URL -> R.string.tech_page_url
    TechKey.PAGE_SOURCE -> R.string.tech_page_source
    TechKey.SNAPSHOT -> R.string.tech_snapshot
    TechKey.ROI -> R.string.tech_roi
    TechKey.BOTTLES -> R.string.tech_bottles
    TechKey.FRAME -> R.string.tech_frame
    TechKey.FILE -> R.string.tech_file
    TechKey.PROBABILITY -> R.string.tech_probability
    TechKey.BACKEND_TIME -> R.string.tech_backend_time
    TechKey.PROFILE -> R.string.tech_profile
    TechKey.REASONS -> R.string.tech_reasons
}
