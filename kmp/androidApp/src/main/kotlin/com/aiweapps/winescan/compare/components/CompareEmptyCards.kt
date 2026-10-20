package com.aiweapps.winescan.compare.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons

private val ButtonHeight = 48.dp

/** The set is empty: this is the tab's main content, with the two ways to fill it. */
@Composable
fun CompareEmpty(onPickFromHistoryClicked: () -> Unit, onScanClicked: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
    ) {
        Text(
            text = stringResource(R.string.compare_empty_title),
            style = MaterialTheme.typography.titleLarge,
            textAlign = TextAlign.Center,
        )
        Text(
            text = stringResource(R.string.compare_empty_body),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
        CompareEntryButtons(
            onPickFromHistoryClicked = onPickFromHistoryClicked,
            onScanClicked = onScanClicked,
            modifier = Modifier.padding(top = 12.dp),
        )
    }
}

/** One wine alone is nothing to compare: a hint with the ways to add the second. */
@Composable
fun CompareNeedSecondCard(onPickFromHistoryClicked: () -> Unit, onScanClicked: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surfaceContainerLow,
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(stringResource(R.string.compare_need_second), style = MaterialTheme.typography.titleMedium)
            CompareEntryButtons(onPickFromHistoryClicked = onPickFromHistoryClicked, onScanClicked = onScanClicked)
        }
    }
}

@Composable
private fun CompareEntryButtons(
    onPickFromHistoryClicked: () -> Unit,
    onScanClicked: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Button(
            onClick = onPickFromHistoryClicked,
            modifier = Modifier.fillMaxWidth().heightIn(min = ButtonHeight),
        ) {
            Icon(AppIcons.History, contentDescription = null, modifier = Modifier.size(18.dp))
            Text(stringResource(R.string.compare_pick_from_history), modifier = Modifier.padding(start = 8.dp))
        }
        OutlinedButton(
            onClick = onScanClicked,
            modifier = Modifier.fillMaxWidth().heightIn(min = ButtonHeight),
        ) {
            Icon(AppIcons.Camera, contentDescription = null, modifier = Modifier.size(18.dp))
            Text(stringResource(R.string.compare_scan), modifier = Modifier.padding(start = 8.dp))
        }
    }
}
