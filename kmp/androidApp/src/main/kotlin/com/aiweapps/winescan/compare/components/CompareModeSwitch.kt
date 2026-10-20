package com.aiweapps.winescan.compare.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.aiweapps.winescan.R

private const val MODE_COUNT = 2

/** «Differences | All». */
@Composable
fun CompareModeSwitch(showAll: Boolean, onShowAllChanged: (Boolean) -> Unit) {
    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
        SegmentedButton(
            selected = !showAll,
            onClick = { onShowAllChanged(false) },
            shape = SegmentedButtonDefaults.itemShape(index = 0, count = MODE_COUNT),
        ) { Text(stringResource(R.string.compare_mode_differences)) }
        SegmentedButton(
            selected = showAll,
            onClick = { onShowAllChanged(true) },
            shape = SegmentedButtonDefaults.itemShape(index = 1, count = MODE_COUNT),
        ) { Text(stringResource(R.string.compare_characteristics)) }
    }
}
