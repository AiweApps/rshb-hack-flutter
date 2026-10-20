package com.aiweapps.winescan.components

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.common.ConfirmClearHistoryComponent

/** «Clear the history?» — shared by the history and settings tabs. */
@Composable
fun ConfirmClearDialog(
    component: ConfirmClearHistoryComponent,
    onDismissRequest: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismissRequest,
        title = { Text(stringResource(R.string.history_clear_confirm_title)) },
        text = { Text(stringResource(R.string.history_clear_confirm_body)) },
        confirmButton = {
            TextButton(onClick = component::onConfirmClicked) {
                Text(
                    text = stringResource(R.string.history_clear_confirm),
                    color = MaterialTheme.colorScheme.error,
                )
            }
        },
        dismissButton = {
            TextButton(onClick = component::onCancelClicked) {
                Text(stringResource(R.string.common_cancel))
            }
        },
    )
}
