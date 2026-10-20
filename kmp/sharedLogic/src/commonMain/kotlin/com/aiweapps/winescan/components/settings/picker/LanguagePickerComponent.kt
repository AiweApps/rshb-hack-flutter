package com.aiweapps.winescan.components.settings.picker

import com.arkivanov.decompose.ComponentContext

interface LanguagePickerComponent {

    /** ISO 639-1 code of the current language. */
    val current: String

    val codes: List<String>

    fun onSelected(code: String)

    fun onCancelClicked()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            current: String,
            codes: List<String>,
            onSelected: (String) -> Unit,
            onCancel: () -> Unit,
        ): LanguagePickerComponent
    }
}

internal class DefaultLanguagePickerComponent(
    componentContext: ComponentContext,
    override val current: String,
    override val codes: List<String>,
    private val onSelect: (String) -> Unit,
    private val onCancel: () -> Unit,
) : LanguagePickerComponent, ComponentContext by componentContext {

    override fun onSelected(code: String) {
        onSelect(code)
    }

    override fun onCancelClicked() {
        onCancel()
    }
}
