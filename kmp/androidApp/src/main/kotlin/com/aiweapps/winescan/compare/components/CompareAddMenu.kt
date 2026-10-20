package com.aiweapps.winescan.compare.components

import androidx.compose.foundation.layout.Box
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons

/**
 * The comparison's «+» in the top bar: a wine-filled icon button that opens a menu with the
 * two ways to add a wine, from the history or by a new scan. Disabled while the set is full.
 */
@Composable
fun CompareAddMenu(
    enabled: Boolean,
    onPickFromHistoryClicked: () -> Unit,
    onNewScanClicked: () -> Unit,
) {
    var isMenuOpen by remember { mutableStateOf(false) }
    val haptics = LocalHapticFeedback.current

    Box {
        FilledIconButton(
            onClick = {
                haptics.performHapticFeedback(HapticFeedbackType.ContextClick)
                isMenuOpen = true
            },
            enabled = enabled,
            colors = IconButtonDefaults.filledIconButtonColors(
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
            ),
        ) {
            Icon(AppIcons.Add, contentDescription = stringResource(R.string.compare_add_wine))
        }
        DropdownMenu(expanded = isMenuOpen && enabled, onDismissRequest = { isMenuOpen = false }) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.compare_pick_history)) },
                leadingIcon = { Icon(AppIcons.History, contentDescription = null) },
                onClick = {
                    isMenuOpen = false
                    onPickFromHistoryClicked()
                },
            )
            DropdownMenuItem(
                text = { Text(stringResource(R.string.compare_new_scan)) },
                leadingIcon = { Icon(AppIcons.Camera, contentDescription = null) },
                onClick = {
                    isMenuOpen = false
                    onNewScanClicked()
                },
            )
        }
    }
}
