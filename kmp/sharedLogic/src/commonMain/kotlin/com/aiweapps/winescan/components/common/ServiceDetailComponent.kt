package com.aiweapps.winescan.components.common

import com.arkivanov.decompose.ComponentContext
import com.aiweapps.winescan.domain.scan.model.ServiceAvailability

/** «What does the status pill mean right now» — a sheet with one sentence and a button. */
interface ServiceDetailComponent {

    val availability: ServiceAvailability

    fun onCloseClicked()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            availability: ServiceAvailability,
            onClose: () -> Unit,
        ): ServiceDetailComponent
    }
}

internal class DefaultServiceDetailComponent(
    componentContext: ComponentContext,
    override val availability: ServiceAvailability,
    private val onClose: () -> Unit,
) : ServiceDetailComponent, ComponentContext by componentContext {

    override fun onCloseClicked() {
        onClose()
    }
}
