package com.aiweapps.winescan.scan.result.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons

private val ButtonHeight = 48.dp

/**
 * The two actions under the best card: join the comparison, or, once the wine is there,
 * leave it (the same button turns outlined with a minus), and pick for a dish.
 */
@Composable
fun BestCardActions(
    isInCompare: Boolean,
    onAddToCompareClicked: () -> Unit,
    onRemoveFromCompareClicked: () -> Unit,
    onPairDishClicked: () -> Unit,
) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        CompareToggleButton(
            isInCompare = isInCompare,
            onAddClicked = onAddToCompareClicked,
            onRemoveClicked = onRemoveFromCompareClicked,
        )
        FilledTonalButton(
            onClick = onPairDishClicked,
            modifier = Modifier.fillMaxWidth().heightIn(min = ButtonHeight),
        ) {
            ButtonContent(AppIcons.Dinner, R.string.action_pair_dish)
        }
    }
}

/**
 * Join the comparison, or, once the wine is there, leave it: the same button turns outlined
 * with a minus. [isTonal] softens the add state when another button above it is the main action.
 */
@Composable
fun CompareToggleButton(
    isInCompare: Boolean,
    onAddClicked: () -> Unit,
    onRemoveClicked: () -> Unit,
    modifier: Modifier = Modifier,
    isTonal: Boolean = false,
) {
    val haptics = LocalHapticFeedback.current
    val buttonModifier = modifier.fillMaxWidth().heightIn(min = ButtonHeight)
    val onAdd = {
        haptics.performHapticFeedback(HapticFeedbackType.Confirm)
        onAddClicked()
    }
    when {
        isInCompare -> OutlinedButton(
            onClick = {
                haptics.performHapticFeedback(HapticFeedbackType.ContextClick)
                onRemoveClicked()
            },
            modifier = buttonModifier,
        ) {
            ButtonContent(AppIcons.Remove, R.string.action_remove_from_compare)
        }
        isTonal -> FilledTonalButton(onClick = onAdd, modifier = buttonModifier) {
            ButtonContent(AppIcons.Add, R.string.action_add_to_compare)
        }
        else -> Button(onClick = onAdd, modifier = buttonModifier) {
            ButtonContent(AppIcons.Add, R.string.action_add_to_compare)
        }
    }
}

/** The compact version for a tile in a list: a text button that turns into «remove» once added. */
@Composable
fun AddToCompareTextButton(
    isInCompare: Boolean,
    onAddClicked: () -> Unit,
    onRemoveClicked: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val haptics = LocalHapticFeedback.current
    TextButton(
        onClick = {
            if (isInCompare) {
                haptics.performHapticFeedback(HapticFeedbackType.ContextClick)
                onRemoveClicked()
            } else {
                haptics.performHapticFeedback(HapticFeedbackType.Confirm)
                onAddClicked()
            }
        },
        modifier = modifier,
    ) {
        ButtonContent(
            icon = if (isInCompare) AppIcons.Remove else AppIcons.Add,
            label = if (isInCompare) R.string.action_remove_from_compare else R.string.action_add_to_compare,
        )
    }
}

@Composable
fun ButtonContent(icon: ImageVector, label: Int) {
    Icon(icon, contentDescription = null, modifier = Modifier.size(18.dp))
    Text(stringResource(label), modifier = Modifier.padding(start = 8.dp))
}
