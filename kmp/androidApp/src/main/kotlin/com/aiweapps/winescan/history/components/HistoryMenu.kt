package com.aiweapps.winescan.history.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.res.stringResource
import com.aiweapps.winescan.R

/** The top bar's overflow menu: «Clear history» lives here, out of the way of a stray tap. */
@Composable
fun HistoryMenu(onClearClicked: () -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    IconButton(onClick = { expanded = true }) {
        Icon(AppIcons.More, contentDescription = stringResource(R.string.history_more))
    }
    DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
        DropdownMenuItem(
            text = { Text(stringResource(R.string.history_clear), color = MaterialTheme.colorScheme.error) },
            onClick = {
                expanded = false
                onClearClicked()
            },
        )
    }
}
