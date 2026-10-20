package com.aiweapps.winescan.components.scan.result.sheets

import com.arkivanov.decompose.ComponentContext
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess

/** «Compare with the reference»: the bottle from the photo and the catalogue reference, one swipe apart. */
interface CompareComponent {

    val photoPath: String

    val crop: BottleBox?

    val frame: List<Int>?

    val bottleNumber: Int

    val cardTitle: String

    val referenceUrl: String?

    val referenceAccess: ReferenceAccess?

    fun onCloseClicked()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            photoPath: String,
            crop: BottleBox?,
            frame: List<Int>?,
            bottleNumber: Int,
            cardTitle: String,
            reference: String?,
            referenceAccess: ReferenceAccess?,
            onClose: () -> Unit,
        ): CompareComponent
    }
}

internal class DefaultCompareComponent(
    componentContext: ComponentContext,
    override val photoPath: String,
    override val crop: BottleBox?,
    override val frame: List<Int>?,
    override val bottleNumber: Int,
    override val cardTitle: String,
    reference: String?,
    override val referenceAccess: ReferenceAccess?,
    private val onClose: () -> Unit,
) : CompareComponent, ComponentContext by componentContext {

    override val referenceUrl: String? = referenceAccess?.resolve(reference)

    override fun onCloseClicked() {
        onClose()
    }
}
