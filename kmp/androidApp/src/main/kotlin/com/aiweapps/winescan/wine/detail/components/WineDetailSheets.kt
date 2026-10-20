package com.aiweapps.winescan.wine.detail.components

import androidx.compose.runtime.Composable
import com.aiweapps.winescan.components.AppModalBottomSheet
import com.aiweapps.winescan.components.wine.detail.WineDetailComponent
import com.aiweapps.winescan.scan.result.components.CompareSheet

/** Maps the wine screen's modal slot onto ordinary bottom sheets. */
@Composable
fun WineDetailSheets(
    modal: WineDetailComponent.Modal?,
    onDismissRequest: () -> Unit,
) {
    AppModalBottomSheet(modal = modal, onDismissRequest = onDismissRequest) { sheet ->
        when (sheet) {
            is WineDetailComponent.Modal.Compare -> CompareSheet(sheet.component)
        }
    }
}
