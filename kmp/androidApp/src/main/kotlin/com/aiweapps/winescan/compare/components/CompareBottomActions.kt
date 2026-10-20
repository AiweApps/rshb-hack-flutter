package com.aiweapps.winescan.compare.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R

/** Small actions in the scroll content; no dock covers the comparison table. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun CompareBottomActions(
    canPairDish: Boolean,
    onPlanDinnerClicked: () -> Unit,
    onPairDishClicked: () -> Unit,
) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        OutlinedButton(
            onClick = onPlanDinnerClicked,
            contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp),
        ) {
            Text(stringResource(R.string.compare_plan_dinner))
        }
        TextButton(
            onClick = onPairDishClicked,
            enabled = canPairDish,
            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
        ) {
            Text(stringResource(R.string.compare_for_dish))
        }
    }
}
