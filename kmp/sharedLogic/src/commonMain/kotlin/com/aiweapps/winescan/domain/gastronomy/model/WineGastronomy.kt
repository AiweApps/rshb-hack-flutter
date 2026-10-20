package com.aiweapps.winescan.domain.gastronomy.model

import kotlinx.serialization.Serializable

/**
 * What the catalogue says about serving one wine. Every field may be missing: `null` is
 * «no data», which is not the same as «does not go» — an empty [pairingIds] is the
 * catalogue listing no dish, `null` is the catalogue saying nothing.
 */
@Serializable
data class WineGastronomy(
    val slug: String,
    val color: WineColor? = null,
    val isSparkling: Boolean? = null,
    val sugar: WineSugar? = null,
    val servingTemperature: ServingTemperature? = null,
    /** Ids of [Dish]es; resolve them through a [DishDictionary]. */
    val pairingIds: List<String>? = null,
    val sourceUrl: String? = null,
)
