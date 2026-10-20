package com.aiweapps.winescan.domain.scan.model

import kotlinx.serialization.Serializable

/**
 * What the wine screen is opened with. The card rides along because the API has no «card by slug»
 * request; [bottle] is the user's bottle it was suggested for, `null` when there is no photo.
 */
@Serializable
data class WineDetailTarget(
    val card: WineCard,
    val bottle: BottlePhoto?,
)
