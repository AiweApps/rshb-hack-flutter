package com.aiweapps.winescan.domain.gastronomy.repository

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.scan.model.WineCard

/**
 * Colour, sugar, temperature and pairings from the source catalogue, cached in memory for
 * the session.
 */
interface GastronomyRepository {

    /** Every dish named so far; it grows as [gastronomy] reads more wines. */
    suspend fun dishes(): ApiResponse<List<Dish>>

    /** Cards, not slugs: the data stays consistent with each card's category. Missing slug = no data. */
    suspend fun gastronomy(cards: List<WineCard>): ApiResponse<Map<String, WineGastronomy>>
}
