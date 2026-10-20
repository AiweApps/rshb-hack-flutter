package com.aiweapps.winescan.components.wine.detail

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.scan.result.sheets.CompareComponent
import com.aiweapps.winescan.components.wine.detail.model.WineDetailState
import com.aiweapps.winescan.domain.scan.model.WineDetailTarget

/** One catalogue wine in full, opened from a suggestion for a bottle on the user's photo. */
interface WineDetailComponent {

    val state: Value<WineDetailState>

    val modalSlot: Value<ChildSlot<*, Modal>>

    fun onBackClicked()

    fun onCatalogueLinkClicked(url: String)

    /** Repeats only unavailable catalogue facts; the user's photograph and scan stay intact. */
    fun onFactsRetryClicked() = Unit

    /** The user's bottle against this wine's reference; nothing happens without a bottle photo. */
    fun onCompareWithPhotoClicked()

    /** This wine joins the comparison set with the user's bottle photo. */
    fun onAddToCompareClicked()

    fun onRemoveFromCompareClicked()

    fun onModalDismissed()

    fun onToastConsumed()

    sealed class Modal {
        class Compare(val component: CompareComponent) : Modal()
    }

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            target: WineDetailTarget,
            onClose: () -> Unit,
        ): WineDetailComponent
    }
}
