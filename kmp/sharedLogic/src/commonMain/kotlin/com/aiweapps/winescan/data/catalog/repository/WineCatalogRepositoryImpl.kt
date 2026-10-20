package com.aiweapps.winescan.data.catalog.repository

import com.aiweapps.core.error.AppError
import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.config.ApiConstants
import com.aiweapps.winescan.data.catalog.remote.WineCatalogApi
import com.aiweapps.winescan.domain.catalog.repository.WineCatalogRepository
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeoutOrNull

/**
 * One cache for every reader of the catalogue: the comparison's and the assistant's card
 * enrichment and the gastronomy facts all ask [wine], so a slug is fetched once a session.
 */
internal class WineCatalogRepositoryImpl(private val api: WineCatalogApi) : WineCatalogRepository {
    private val cache = linkedMapOf<String, WineCard>()
    private val mutex = Mutex()

    override suspend fun wine(slug: String): ApiResponse<WineCard> {
        mutex.withLock { cache[slug] }?.let { return ApiResponse.Success(it, statusCode = HTTP_OK) }
        val response = withTimeoutOrNull(ApiConstants.CATALOG_TIMEOUT_MS) { api.wine(slug) }
            ?: return ApiResponse.Error(AppError.Timeout)
        if (response !is ApiResponse.Success) return response
        // A card for another slug is a broken answer, not this wine's data.
        val detail = response.data.takeIf { it.slug == slug } ?: return ApiResponse.Error(AppError.Unknown)
        mutex.withLock {
            if (cache.size >= ApiConstants.CATALOG_CACHE_SIZE) cache.remove(cache.keys.first())
            cache[slug] = detail
        }
        return ApiResponse.Success(detail, statusCode = HTTP_OK)
    }

    override suspend fun enrich(card: WineCard): WineCard {
        val metadata = (wine(card.slug) as? ApiResponse.Success)?.data ?: return card
        return mergeWineMetadata(card, metadata)
    }

    override suspend fun search(query: String): List<WineCard> {
        if (query.trim().length < MIN_QUERY_LENGTH) return emptyList()
        return (api.search(query.trim()) as? ApiResponse.Success)?.data?.wines.orEmpty()
    }

    private companion object {
        const val HTTP_OK = 200
        const val MIN_QUERY_LENGTH = 2
    }
}

/** Same enrichment rule for local and remote facts; neither changes stored scan identity. */
internal fun mergeWineMetadata(card: WineCard, metadata: WineCard): WineCard = card.copy(
            name = card.name.nonBlankOr(metadata.name),
            producer = card.producer.nonBlankOr(metadata.producer),
            category = metadata.category.nonBlankOr(card.category),
            region = card.region.nonBlankOr(metadata.region),
            grapes = card.grapes.nonBlankOr(metadata.grapes),
            pageUrl = card.pageUrl.nonBlankOr(metadata.pageUrl),
            reference = card.reference.nonBlankOr(metadata.reference),
            color = card.color.nonBlankOr(metadata.color),
            sugar = card.sugar.nonBlankOr(metadata.sugar),
            foodPairings = card.pairings ?: metadata.pairings,
            servingTemperature = card.servingTemperature.nonBlankOr(metadata.servingTemperature),
            description = card.description.nonBlankOr(metadata.description),
            alcohol = card.alcohol ?: metadata.alcohol,
            dishes = card.dishes.ifEmpty { metadata.dishes },
)

private fun String?.nonBlankOr(other: String?): String? = takeUnless { it.isNullOrBlank() } ?: other
