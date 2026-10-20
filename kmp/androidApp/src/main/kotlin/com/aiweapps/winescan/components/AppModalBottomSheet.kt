package com.aiweapps.winescan.components

import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable

/**
 * Renders whatever a component put into its Decompose slot as a modal bottom sheet.
 *
 * Deliberately generic: it knows about "there is a modal or there isn't", never about which
 * modals exist. Each screen keeps its own `Modal` hierarchy and maps it in [content], so a
 * new modal never touches shared UI plumbing.
 *
 * The slot is the source of truth, which has one visible consequence: when the component
 * dismisses the modal itself, the sheet leaves the composition immediately instead of
 * sliding down. That is the price of keeping "is a modal shown" in shared code rather than
 * in two copies of platform UI state, and it is why [onDismissRequest] carries only the
 * gestures the UI owns — the scrim tap and the swipe.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun <T : Any> AppModalBottomSheet(
    modal: T?,
    onDismissRequest: () -> Unit,
    content: @Composable (T) -> Unit,
) {
    if (modal == null) return

    ModalBottomSheet(
        onDismissRequest = onDismissRequest,
        sheetState = rememberModalBottomSheetState(),
    ) {
        content(modal)
    }
}
