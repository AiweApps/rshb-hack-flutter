package com.aiweapps.winescan.local

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.settings.SettingsComponent
import com.aiweapps.winescan.domain.scan.model.ScannerBackend
import com.aiweapps.winescan.domain.scan.model.ScannerBackendState
import com.aiweapps.winescan.settings.components.SettingsSection

@Composable
fun ScannerBackendSection(state: ScannerBackendState, component: SettingsComponent) {
    SettingsSection(stringResource(R.string.local_scanner_title)) {
        if (state.canChoose) {
            listOf(ScannerBackend.SERVER, ScannerBackend.LOCAL).forEach { choice ->
                val enabled = choice == ScannerBackend.SERVER || state.localAvailable
                Row(Modifier.fillMaxWidth().clickable(enabled = enabled) { component.onScannerBackendSelected(choice) }
                    .padding(horizontal = 16.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                    RadioButton(selected = state.selected == choice, onClick = null, enabled = enabled)
                    Text(stringResource(if (choice == ScannerBackend.SERVER) R.string.local_scanner_server else R.string.local_scanner_device),
                        modifier = Modifier.padding(start = 12.dp))
                }
            }
        }
        Column(Modifier.padding(horizontal = 24.dp, vertical = 8.dp)) {
            Text(stringResource(when {
                state.localAvailable -> R.string.local_scanner_ready
                state.localModel.isBusy -> R.string.local_scanner_preparing
                else -> R.string.local_scanner_missing
            }), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
