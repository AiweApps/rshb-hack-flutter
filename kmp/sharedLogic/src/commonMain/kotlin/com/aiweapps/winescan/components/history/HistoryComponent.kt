package com.aiweapps.winescan.components.history

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.common.ConfirmClearHistoryComponent
import com.aiweapps.winescan.components.history.model.HistoryState
import com.aiweapps.winescan.domain.pairing.model.PairingSource

/**
 * The list of stored scans. It is a live view of the database: every insert and delete
 * anywhere in the app shows up here without a reload.
 */
interface HistoryComponent {

    val state: Value<HistoryState>

    val modalSlot: Value<ChildSlot<*, Modal>>

    fun onRetry()

    fun onScanClicked(scanId: Long)

    /** A row was swiped away. */
    fun onScanDismissed(scanId: Long)

    /** «Scan» on the empty state. */
    fun onScanNowClicked()

    fun onClearClicked()

    /**
     * The compare button on a row: the scan's wine joins the comparison, or leaves it when
     * it is already there.
     */
    fun onCompareClicked(scanId: Long)

    /** The heart on a row: the scan's wine joins «My wines», or leaves them when it is there. */
    fun onFavoriteClicked(scanId: Long)

    fun onSavedPairingClicked(pairingId: Long)

    /** A saved choice was swiped away. */
    fun onSavedPairingDismissed(pairingId: Long)

    fun onModalDismissed()

    fun onToastConsumed()

    sealed class Modal {
        class ConfirmClear(val component: ConfirmClearHistoryComponent) : Modal()
    }

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            onOpenScan: (scanId: Long) -> Unit,
            onOpenScanner: () -> Unit,
            onOpenPairing: (PairingSource) -> Unit,
        ): HistoryComponent
    }
}
