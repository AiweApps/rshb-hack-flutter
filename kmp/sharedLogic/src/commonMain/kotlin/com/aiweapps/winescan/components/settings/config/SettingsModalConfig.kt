package com.aiweapps.winescan.components.settings.config

import com.aiweapps.winescan.domain.scan.model.ServiceAvailability
import com.aiweapps.winescan.domain.theme.model.ThemeMode
import kotlinx.serialization.Serializable

@Serializable
internal sealed class SettingsModalConfig {

    @Serializable
    data class ThemePicker(val current: ThemeMode) : SettingsModalConfig()

    @Serializable
    data class LanguagePicker(val current: String, val codes: List<String>) : SettingsModalConfig()

    @Serializable
    data class ServiceDetail(val availability: ServiceAvailability) : SettingsModalConfig()

    @Serializable
    data object About : SettingsModalConfig()

    @Serializable
    data object ConfirmClear : SettingsModalConfig()
}
