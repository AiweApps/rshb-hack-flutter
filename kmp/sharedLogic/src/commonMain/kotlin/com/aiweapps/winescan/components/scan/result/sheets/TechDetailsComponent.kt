package com.aiweapps.winescan.components.scan.result.sheets

import com.arkivanov.decompose.ComponentContext
import com.aiweapps.winescan.components.scan.result.model.TechRow

/** «Technical details»: the raw fields of the answer, for whoever reviews the recognition. */
interface TechDetailsComponent {

    val rows: List<TechRow>

    fun onCloseClicked()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            rows: List<TechRow>,
            onClose: () -> Unit,
        ): TechDetailsComponent
    }
}

internal class DefaultTechDetailsComponent(
    componentContext: ComponentContext,
    override val rows: List<TechRow>,
    private val onClose: () -> Unit,
) : TechDetailsComponent, ComponentContext by componentContext {

    override fun onCloseClicked() {
        onClose()
    }
}
