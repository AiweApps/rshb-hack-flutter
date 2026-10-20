package com.aiweapps.winescan.data.gastronomy

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.scan.model.WineCard

/** Where the repository gets gastronomy from: the source catalogue (`v1/wines`). */
internal interface GastronomyDataSource {

    /**
     * Every dish this source has named so far. The catalogue has no dish dictionary of its
     * own, so the dictionary grows with the wines read through [gastronomy].
     */
    suspend fun dishes(): ApiResponse<List<Dish>>

    /** One item per card the source knows; a card left out has no data. */
    suspend fun gastronomy(cards: List<WineCard>): ApiResponse<List<WineGastronomy>>
}
