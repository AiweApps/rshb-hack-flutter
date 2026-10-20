package com.aiweapps.winescan.domain.pairing.model

import kotlinx.serialization.Serializable

/**
 * What the dish screen is opened with: a fresh choice over the comparison set, or a
 * choice the user saved earlier. Serializable because it is the navigation argument.
 */
@Serializable
sealed class PairingSource {

    @Serializable
    data object FromCompareSet : PairingSource()

    @Serializable
    data class Saved(val id: Long) : PairingSource()
}
