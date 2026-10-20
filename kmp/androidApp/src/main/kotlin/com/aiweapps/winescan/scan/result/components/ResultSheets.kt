package com.aiweapps.winescan.scan.result.components

import androidx.compose.runtime.Composable
import com.aiweapps.winescan.components.AppModalBottomSheet
import com.aiweapps.winescan.components.scan.result.ScanResultComponent

/**
 * Maps the result's modal slot onto sheets. The frame screen is a drawing surface that
 * needs the whole screen and its own back handling, so it is a full-screen dialog; the
 * rest are ordinary bottom sheets.
 */
@Composable
fun ResultSheets(
    modal: ScanResultComponent.Modal?,
    onDismissRequest: () -> Unit,
) {
    (modal as? ScanResultComponent.Modal.DrawFrame)?.let { DrawFrameDialog(it.component) }

    AppModalBottomSheet(
        modal = modal?.takeUnless { it is ScanResultComponent.Modal.DrawFrame },
        onDismissRequest = onDismissRequest,
    ) { sheet ->
        when (sheet) {
            is ScanResultComponent.Modal.Compare -> CompareSheet(sheet.component)
            is ScanResultComponent.Modal.More -> MoreSheet(sheet.component)
            is ScanResultComponent.Modal.TechDetails -> TechDetailsSheet(sheet.component)
            is ScanResultComponent.Modal.DrawFrame -> Unit
        }
    }
}
