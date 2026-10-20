package com.aiweapps.winescan.components.settings.picker

import com.arkivanov.decompose.ComponentContext
import com.aiweapps.winescan.domain.theme.model.ThemeMode

interface ThemePickerComponent {

    val current: ThemeMode

    val options: List<ThemeMode>

    fun onSelected(mode: ThemeMode)

    fun onCancelClicked()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            current: ThemeMode,
            onSelected: (ThemeMode) -> Unit,
            onCancel: () -> Unit,
        ): ThemePickerComponent
    }
}

internal class DefaultThemePickerComponent(
    componentContext: ComponentContext,
    override val current: ThemeMode,
    private val onSelect: (ThemeMode) -> Unit,
    private val onCancel: () -> Unit,
) : ThemePickerComponent, ComponentContext by componentContext {

    override val options: List<ThemeMode> = listOf(ThemeMode.System, ThemeMode.Light, ThemeMode.Dark)

    override fun onSelected(mode: ThemeMode) {
        onSelect(mode)
    }

    override fun onCancelClicked() {
        onCancel()
    }
}
