package com.aiweapps.winescan.components.scan.home.config

import com.aiweapps.winescan.domain.scan.model.ServiceAvailability
import kotlinx.serialization.Serializable

@Serializable
internal sealed class ScanHomeModalConfig {

    @Serializable
    data class ServiceDetail(val availability: ServiceAvailability) : ScanHomeModalConfig()
}
