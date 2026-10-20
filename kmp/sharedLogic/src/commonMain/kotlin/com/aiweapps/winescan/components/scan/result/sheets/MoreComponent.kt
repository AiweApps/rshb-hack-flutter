package com.aiweapps.winescan.components.scan.result.sheets

import com.arkivanov.decompose.ComponentContext

/** «More»: recognise only the selected bottle, choose a frame, share the JSON, technical details. */
interface MoreComponent {

    /** The answer on screen is for a drawn frame, so the second share is «the frame JSON». */
    val isRoi: Boolean

    /**
     * Number of the selected bottle; `null` hides the per-bottle share. The rescan row reads
     * it too: «Recognise only bottle 2».
     */
    val bottleNumber: Int?

    /**
     * «Recognise only this bottle»: the selected bottle of an automatic answer with several
     * bottles, which the service gave a box to ask for; `false` hides the row.
     */
    val canRescanBottle: Boolean

    /**
     * «Choose a frame» needs the photo's frame size, which an answer brings, and no request
     * in flight; `false` hides the row.
     */
    val canDrawFrame: Boolean

    /**
     * «Recognise only this bottle»: this sheet closes and a new result opens for the bottle's
     * box, the same way as for a drawn frame — not stored in the history.
     */
    fun onRescanBottleClicked()

    /** «Choose a frame»: this sheet closes and the frame screen opens. */
    fun onDrawFrameClicked()

    fun onShareFullClicked()

    fun onShareBottleClicked()

    fun onTechDetailsClicked()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            isRoi: Boolean,
            bottleNumber: Int?,
            canRescanBottle: Boolean,
            canDrawFrame: Boolean,
            onRescanBottle: () -> Unit,
            onDrawFrame: () -> Unit,
            onShareFull: () -> Unit,
            onShareBottle: () -> Unit,
            onTechDetails: () -> Unit,
        ): MoreComponent
    }
}

internal class DefaultMoreComponent(
    componentContext: ComponentContext,
    override val isRoi: Boolean,
    override val bottleNumber: Int?,
    override val canRescanBottle: Boolean,
    override val canDrawFrame: Boolean,
    private val onRescanBottle: () -> Unit,
    private val onDrawFrame: () -> Unit,
    private val onShareFull: () -> Unit,
    private val onShareBottle: () -> Unit,
    private val onTechDetails: () -> Unit,
) : MoreComponent, ComponentContext by componentContext {

    override fun onRescanBottleClicked() {
        if (canRescanBottle) onRescanBottle()
    }

    override fun onDrawFrameClicked() {
        if (canDrawFrame) onDrawFrame()
    }

    override fun onShareFullClicked() {
        onShareFull()
    }

    override fun onShareBottleClicked() {
        onShareBottle()
    }

    override fun onTechDetailsClicked() {
        onTechDetails()
    }
}
