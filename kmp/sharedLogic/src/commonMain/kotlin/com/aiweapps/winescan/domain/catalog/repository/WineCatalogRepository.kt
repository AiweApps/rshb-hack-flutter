package com.aiweapps.winescan.domain.catalog.repository

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.domain.scan.model.WineCard

/** Source catalogue metadata. It never changes recognition identity or stored raw answers. */
interface WineCatalogRepository {

    /**
     * The catalogue's own card for [slug], cached for the session. An unknown slug is an
     * [ApiResponse.Error] with status 404; a failure is not cached.
     */
    suspend fun wine(slug: String): ApiResponse<WineCard>

    /** [card] with what it lacks filled from the catalogue; [card] itself when that fails. */
    suspend fun enrich(card: WineCard): WineCard

    suspend fun search(query: String): List<WineCard>
}
