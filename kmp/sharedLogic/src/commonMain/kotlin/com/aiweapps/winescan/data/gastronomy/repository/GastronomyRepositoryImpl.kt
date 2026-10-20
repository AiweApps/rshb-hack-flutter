package com.aiweapps.winescan.data.gastronomy.repository

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.data.gastronomy.GastronomyDataSource
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.gastronomy.repository.GastronomyRepository
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

internal class GastronomyRepositoryImpl(
    private val source: GastronomyDataSource,
) : GastronomyRepository {

    private val mutex = Mutex()

    // A slug mapped to null was asked for and has no data: it is not asked for again.
    private val bySlug = mutableMapOf<String, WineGastronomy?>()

    // Not cached here: the source's dictionary grows with every wine it reads.
    override suspend fun dishes(): ApiResponse<List<Dish>> = source.dishes()

    override suspend fun gastronomy(cards: List<WineCard>): ApiResponse<Map<String, WineGastronomy>> {
        val unique = cards.distinctBy { it.slug }
        val missing = mutex.withLock { unique.filterNot { it.slug in bySlug } }
        if (missing.isNotEmpty()) {
            when (val response = source.gastronomy(missing)) {
                is ApiResponse.Error -> return response
                is ApiResponse.Success -> {
                    val loaded = response.data.associateBy { it.slug }
                    mutex.withLock { missing.forEach { bySlug[it.slug] = loaded[it.slug] } }
                }
            }
        }
        val result = mutex.withLock {
            unique.mapNotNull { card -> bySlug[card.slug]?.let { card.slug to it } }.toMap()
        }
        return ApiResponse.Success(result, statusCode = CACHED)
    }

    private companion object {
        const val CACHED = 200
    }
}
