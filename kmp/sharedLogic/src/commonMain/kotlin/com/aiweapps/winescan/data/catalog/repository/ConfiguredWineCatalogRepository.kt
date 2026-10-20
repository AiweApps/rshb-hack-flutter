package com.aiweapps.winescan.data.catalog.repository

import com.aiweapps.core.error.AppError
import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.domain.catalog.repository.WineCatalogRepository
import com.aiweapps.winescan.domain.scan.model.ScannerBackend
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.domain.scan.repository.LocalScanEngine
import com.aiweapps.winescan.domain.scan.repository.ScannerBackendControls
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

/** Catalogue facts follow the selected backend; local never falls through to the API. */
internal class ConfiguredWineCatalogRepository(
    private val remote: WineCatalogRepository,
    private val local: LocalScanEngine?,
    private val controls: ScannerBackendControls,
    private val json: Json,
) : WineCatalogRepository {
    override suspend fun wine(slug: String): ApiResponse<WineCard> {
        if (controls.backendState.value.selected == ScannerBackend.SERVER) return remote.wine(slug)
        return withContext(Dispatchers.Default) {
            val body = local?.wineJson(slug) ?: return@withContext ApiResponse.Error(AppError.Server(404), statusCode = 404)
            try {
                val card = json.decodeFromString<WineCard>(body)
                if (card.slug == slug) ApiResponse.Success(card, statusCode = 200) else ApiResponse.Error(AppError.Unknown)
            } catch (_: IllegalArgumentException) { ApiResponse.Error(AppError.Unknown) }
        }
    }

    override suspend fun enrich(card: WineCard): WineCard {
        val metadata = (wine(card.slug) as? ApiResponse.Success)?.data ?: return card
        return mergeWineMetadata(card, metadata)
    }

    override suspend fun search(query: String): List<WineCard> {
        if (controls.backendState.value.selected == ScannerBackend.SERVER) return remote.search(query)
        return withContext(Dispatchers.Default) {
            val body = local?.searchJson(query) ?: return@withContext emptyList()
            try { json.decodeFromString<List<WineCard>>(body) }
            catch (_: IllegalArgumentException) { emptyList() }
        }
    }
}
