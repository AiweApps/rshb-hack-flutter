package com.aiweapps.winescan.components.main.config

import kotlinx.serialization.Serializable

@Serializable
sealed class TabConfig {
    @Serializable
    data object Scan : TabConfig()

    @Serializable
    data object History : TabConfig()

    @Serializable
    data object Compare : TabConfig()

    @Serializable
    data object Settings : TabConfig()

    @Serializable
    data object Assistant : TabConfig()
}
