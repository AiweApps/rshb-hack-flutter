package com.aiweapps.winescan.components.settings.about

import com.arkivanov.decompose.ComponentContext

/** «About the scanner»: what it does, the disclaimer, and a button to close. */
interface AboutComponent {

    fun onCloseClicked()

    fun interface Factory {
        fun create(componentContext: ComponentContext, onClose: () -> Unit): AboutComponent
    }
}

internal class DefaultAboutComponent(
    componentContext: ComponentContext,
    private val onClose: () -> Unit,
) : AboutComponent, ComponentContext by componentContext {

    override fun onCloseClicked() {
        onClose()
    }
}
