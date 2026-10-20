package com.aiweapps.winescan.components.wine.detail.config

import com.aiweapps.winescan.domain.scan.model.BottlePhoto
import kotlinx.serialization.Serializable

@Serializable
internal sealed class WineDetailModalConfig {

    @Serializable
    data class Compare(val bottle: BottlePhoto) : WineDetailModalConfig()
}
