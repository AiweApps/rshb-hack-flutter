package com.aiweapps.winescan.components.scan.result

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.scan.result.model.ScanResultState
import com.aiweapps.winescan.components.scan.result.sheets.CompareComponent
import com.aiweapps.winescan.components.scan.result.sheets.DrawFrameComponent
import com.aiweapps.winescan.components.scan.result.sheets.MoreComponent
import com.aiweapps.winescan.components.scan.result.sheets.TechDetailsComponent
import com.aiweapps.winescan.domain.scan.model.ScanTarget
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.domain.scan.model.WineDetailTarget

/**
 * The answer for one photo: recognition, bottle selection, per-bottle frames, retries,
 * sharing, and saving the automatic answer to the history. A frame drawn by hand opens a
 * new result for it ([ScanTarget.Framed]) instead of replacing this one.
 */
interface ScanResultComponent {

    val state: Value<ScanResultState>

    val modalSlot: Value<ChildSlot<*, Modal>>

    /** The back button: closes the screen. */
    fun onBackClicked()

    fun onRetryClicked()

    /** Retries unavailable wine facts without recognising the photo or rewriting its history. */
    fun onFactsRetryClicked() = Unit

    /** «New scan»: back to the scanner tab. */
    fun onNewScanClicked()

    /**
     * A bottle frame or chip was tapped; `null` means "all bottles". Tapping the selected
     * bottle again goes back to all bottles when there are several.
     */
    fun onBottleSelected(instanceId: String?)

    fun onCardLinkClicked(url: String)

    /** «Compare» in the toolbar: the selected bottle against its best match. */
    fun onCompareClicked()

    /** A card's preview was tapped: that bottle against [card]. */
    fun onCompareCardClicked(instanceId: String, card: WineCard)

    /** A «Similar options» card was tapped: the wine screen for [card], with that bottle's photo. */
    fun onAlternativeClicked(instanceId: String, card: WineCard)

    fun onMoreClicked()

    /** «Add to comparison» on a bottle's best card. */
    fun onAddToCompareClicked(instanceId: String)

    /** «Remove from comparison»: the same button once the bottle's best card is in the set. */
    fun onRemoveFromCompareClicked(instanceId: String)

    /**
     * The «Compare · N» pill. The wine on screen joins the set first when it is not there
     * yet and there is already another wine to compare it with.
     */
    fun onCompareWinesClicked()

    /**
     * «Pick for a dish» on a bottle's card: the wine joins the comparison silently — no toast
     * for added, already there or a full set — then the dish screen opens. Only a failed
     * write is told, and the dish screen then stays shut.
     */
    fun onPairDishClicked(instanceId: String)

    fun onModalDismissed()

    fun onToastConsumed()

    sealed class Modal {
        /** «Choose a frame» from «More»; the platforms present it full screen. */
        class DrawFrame(val component: DrawFrameComponent) : Modal()
        class Compare(val component: CompareComponent) : Modal()
        class More(val component: MoreComponent) : Modal()
        class TechDetails(val component: TechDetailsComponent) : Modal()
    }

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            target: ScanTarget,
            onClose: () -> Unit,
            onNewScan: () -> Unit,
            onOpenCompare: () -> Unit,
            onOpenPairing: () -> Unit,
            onOpenWineDetail: (WineDetailTarget) -> Unit,
            /**
             * «Scan» on the frame screen, or «Recognise only this bottle» in «More»: a new
             * result for the same photo and that frame.
             */
            onOpenFramedResult: (ScanTarget.Framed) -> Unit,
        ): ScanResultComponent
    }
}
