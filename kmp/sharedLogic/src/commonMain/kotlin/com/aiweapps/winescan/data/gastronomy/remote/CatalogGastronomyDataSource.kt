package com.aiweapps.winescan.data.gastronomy.remote

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.config.ApiConstants
import com.aiweapps.winescan.data.gastronomy.GastronomyDataSource
import com.aiweapps.winescan.data.gastronomy.model.catalogDishes
import com.aiweapps.winescan.data.gastronomy.model.toGastronomy
import com.aiweapps.winescan.domain.catalog.repository.WineCatalogRepository
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Gastronomy from the source catalogue the assistant and the comparison read too
 * (`v1/wines/<slug>` through [WineCatalogRepository], one cache for all of them).
 *
 * A slug the catalogue does not know (404) is «no data»; any other failure fails the whole
 * request, so the repository does not remember it and the next screen asks again.
 */
internal class CatalogGastronomyDataSource(
    private val catalog: WineCatalogRepository,
) : GastronomyDataSource {

    private val mutex = Mutex()

    // In the order the dishes were first seen, so the chips keep their places between screens.
    private val dictionary = linkedMapOf<String, Dish>()

    override suspend fun dishes(): ApiResponse<List<Dish>> =
        ApiResponse.Success(mutex.withLock { dictionary.values.toList() }, statusCode = HTTP_OK)

    override suspend fun gastronomy(cards: List<WineCard>): ApiResponse<List<WineGastronomy>> {
        val unique = cards.distinctBy { it.slug }
        val responses = coroutineScope {
            unique.map { card -> async { card to catalog.wine(card.slug) } }.awaitAll()
        }
        val failure = responses.firstNotNullOfOrNull { (_, response) ->
            (response as? ApiResponse.Error)?.takeIf { it.statusCode != ApiConstants.HTTP_NOT_FOUND }
        }
        if (failure != null) return failure
        val known = responses.mapNotNull { (card, response) ->
            (response as? ApiResponse.Success)?.data?.let { card to it }
        }
        mutex.withLock {
            known.forEach { (_, detail) ->
                detail.catalogDishes().orEmpty().forEach { dish -> dictionary.getOrPut(dish.id) { dish } }
            }
        }
        return ApiResponse.Success(known.map { (card, detail) -> detail.toGastronomy(recognized = card) }, statusCode = HTTP_OK)
    }

    private companion object {
        const val HTTP_OK = 200
    }
}
