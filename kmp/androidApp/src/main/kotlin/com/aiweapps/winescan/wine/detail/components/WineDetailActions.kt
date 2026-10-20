package com.aiweapps.winescan.wine.detail.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.Button
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.scan.result.components.ButtonContent
import com.aiweapps.winescan.scan.result.components.CompareToggleButton

private val ButtonHeight = 48.dp

/**
 * The buttons under the wine's name: the user's photo against this reference (main action,
 * only with a photo), and the comparison set toggle (only when it can do something).
 */
@Composable
fun WineDetailActions(
    canCompareWithPhoto: Boolean,
    showsCompareToggle: Boolean,
    isInCompare: Boolean,
    onCompareWithPhotoClicked: () -> Unit,
    onAddToCompareClicked: () -> Unit,
    onRemoveFromCompareClicked: () -> Unit,
) {
    if (!canCompareWithPhoto && !showsCompareToggle) return
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (canCompareWithPhoto) {
            Button(
                onClick = onCompareWithPhotoClicked,
                modifier = Modifier.fillMaxWidth().heightIn(min = ButtonHeight),
            ) {
                ButtonContent(AppIcons.Compare, R.string.action_compare_with_photo)
            }
        }
        if (showsCompareToggle) {
            CompareToggleButton(
                isInCompare = isInCompare,
                onAddClicked = onAddToCompareClicked,
                onRemoveClicked = onRemoveFromCompareClicked,
                isTonal = canCompareWithPhoto,
            )
        }
    }
}
