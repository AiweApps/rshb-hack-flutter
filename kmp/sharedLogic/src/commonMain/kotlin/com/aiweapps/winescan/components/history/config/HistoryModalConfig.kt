package com.aiweapps.winescan.components.history.config

import kotlinx.serialization.Serializable

@Serializable
internal sealed class HistoryModalConfig {

    @Serializable
    data object ConfirmClear : HistoryModalConfig()
}
