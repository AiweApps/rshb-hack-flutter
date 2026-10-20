package com.aiweapps.winescan.components.common.model

import com.aiweapps.winescan.domain.gastronomy.model.DishDictionary
import com.aiweapps.winescan.domain.gastronomy.model.DishLabel
import com.aiweapps.winescan.domain.gastronomy.model.ServingTemperature
import com.aiweapps.winescan.domain.gastronomy.model.WineColor
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.gastronomy.model.WineSugar

/**
 * One wine's gastronomy ready to show: enums the UI localises (never `UNKNOWN`), dishes
 * already named in the app's language. Every `null` is «no data».
 */
data class WineFacts(
    val color: WineColor?,
    val isSparkling: Boolean?,
    val sugar: WineSugar?,
    val servingTemperature: ServingTemperature?,
    /** `null` is «no data», empty is «the catalogue lists none». */
    val pairings: List<DishLabel>?,
    val sourceUrl: String?,
) {
    companion object {
        val NO_DATA = WineFacts(
            color = null,
            isSparkling = null,
            sugar = null,
            servingTemperature = null,
            pairings = null,
            sourceUrl = null,
        )
    }
}

internal fun WineGastronomy?.toFacts(dishes: DishDictionary, language: String): WineFacts {
    if (this == null) return WineFacts.NO_DATA
    return WineFacts(
        color = color?.takeIf { it != WineColor.UNKNOWN },
        isSparkling = isSparkling,
        sugar = sugar?.takeIf { it != WineSugar.UNKNOWN },
        servingTemperature = servingTemperature,
        pairings = dishes.labels(pairingIds, language),
        sourceUrl = sourceUrl,
    )
}
