package com.aiweapps.winescan.settings.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp

class RadioOption<T>(val value: T, val label: String)

/** A short list with one chosen option: the content of the theme and language sheets. */
@Composable
fun <T> RadioOptionsSheet(
    title: String,
    options: List<RadioOption<T>>,
    selected: T,
    onSelected: (T) -> Unit,
) {
    Column(Modifier.fillMaxWidth().navigationBarsPadding().padding(bottom = 16.dp)) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
        )
        Column(Modifier.selectableGroup()) {
            options.forEach { option ->
                ListItem(
                    modifier = Modifier.selectable(
                        selected = option.value == selected,
                        role = Role.RadioButton,
                        onClick = { onSelected(option.value) },
                    ),
                    colors = ListItemDefaults.colors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
                    headlineContent = { Text(option.label) },
                    trailingContent = { RadioButton(selected = option.value == selected, onClick = null) },
                )
            }
        }
    }
}
