package com.aiweapps.winescan.components.compare

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.compare.model.WineCompareState
import com.aiweapps.winescan.components.compare.picker.HistoryPickerComponent
import com.aiweapps.winescan.domain.scan.model.WineCard

/**
 * The «Compare» tab: the wines the user picked, side by side, differences first. Wines come
 * in from a result, from a history row, or from the picker this tab opens over the history.
 */
interface WineCompareComponent {

    val state: Value<WineCompareState>

    val modalSlot: Value<ChildSlot<*, Modal>>

    fun onRemoveClicked(slug: String)

    /** «Pick from the history»: the sheet with the stored scans that have a match. */
    fun onPickFromHistoryClicked()

    /** «Scan a wine»: the scanner tab; the next result's cards get an «add» button. */
    fun onScanClicked()

    /** «Compare for a dish»: the dish screen over the wines of this set. */
    fun onPairDishClicked()

    /** Open the assistant with these exact wines and an editable dinner request. */
    fun onPlanDinnerClicked(prompt: String)

    /** The «Differences / All» switch. */
    fun onShowAllChanged(showAll: Boolean)

    fun onCardLinkClicked(url: String)

    fun onModalDismissed()

    /** An attempted add from another screen found the existing set full. */
    fun onCapacityReached()

    fun onToastConsumed()

    sealed class Modal {
        class HistoryPicker(val component: HistoryPickerComponent) : Modal()
    }

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            onOpenScanner: () -> Unit,
            onOpenPairing: () -> Unit,
            onPlanDinner: (List<WineCard>, String) -> Unit,
        ): WineCompareComponent
    }
}
