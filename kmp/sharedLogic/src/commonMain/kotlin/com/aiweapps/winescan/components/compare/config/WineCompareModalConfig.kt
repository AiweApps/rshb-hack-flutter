package com.aiweapps.winescan.components.compare.config

import kotlinx.serialization.Serializable

@Serializable
internal sealed class WineCompareModalConfig {

    @Serializable
    data object HistoryPicker : WineCompareModalConfig()
}
