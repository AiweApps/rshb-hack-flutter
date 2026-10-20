package com.aiweapps.winescan.components.root.config

import com.aiweapps.winescan.domain.pairing.model.PairingSource
import com.aiweapps.winescan.domain.scan.model.ScanTarget
import com.aiweapps.winescan.domain.scan.model.WineDetailTarget
import kotlinx.serialization.Serializable

@Serializable
sealed class RootConfig {
    @Serializable
    data object Splash : RootConfig()

    @Serializable
    data object Onboarding : RootConfig()

    @Serializable
    data object Main : RootConfig()

    /**
     * Pushed over [Main]: the answer covers the tabs because the photo needs the whole screen.
     * A result for a drawn frame is pushed over the result it was drawn on.
     */
    @Serializable
    data class ScanResult(val target: ScanTarget) : RootConfig()

    /** Pushed over [ScanResult] when a «Similar options» card is tapped. */
    @Serializable
    data class WineDetail(val target: WineDetailTarget) : RootConfig()

    @Serializable
    data class DishPairing(val source: PairingSource) : RootConfig()
}
