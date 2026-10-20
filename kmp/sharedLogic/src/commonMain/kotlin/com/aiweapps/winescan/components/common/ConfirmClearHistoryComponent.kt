package com.aiweapps.winescan.components.common

import com.arkivanov.decompose.ComponentContext

/**
 * Asks before wiping the history. Only asks: the wipe stays with the screen that owns the
 * repository and the feedback about it.
 */
interface ConfirmClearHistoryComponent {

    fun onConfirmClicked()

    fun onCancelClicked()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            onConfirm: () -> Unit,
            onCancel: () -> Unit,
        ): ConfirmClearHistoryComponent
    }
}

internal class DefaultConfirmClearHistoryComponent(
    componentContext: ComponentContext,
    private val onConfirm: () -> Unit,
    private val onCancel: () -> Unit,
) : ConfirmClearHistoryComponent, ComponentContext by componentContext {

    override fun onConfirmClicked() {
        onConfirm()
    }

    override fun onCancelClicked() {
        onCancel()
    }
}
