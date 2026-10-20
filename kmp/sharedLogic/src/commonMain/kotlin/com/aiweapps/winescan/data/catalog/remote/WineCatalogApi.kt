package com.aiweapps.winescan.data.catalog.remote

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.core.network.safeApiCall
import com.aiweapps.winescan.data.assistant.model.WineSearchDto
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.domain.session.GuestSession
import io.ktor.client.HttpClient
import io.ktor.client.request.bearerAuth
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.http.encodeURLPathPart

/** Public catalogue facts use the existing scanner guest token, without changing chat identity. */
internal class WineCatalogApi(private val client: HttpClient, private val session: GuestSession) {
    suspend fun wine(slug: String): ApiResponse<WineCard> = call { token ->
        client.get("${WineCatalogRoutes.WINES}/${slug.encodeURLPathPart()}") { bearerAuth(token) }
    }

    suspend fun search(query: String): ApiResponse<WineSearchDto> = call { token ->
        client.get(WineCatalogRoutes.SEARCH) { bearerAuth(token); parameter("query", query); parameter("limit", 10) }
    }

    private suspend inline fun <reified T> call(
        crossinline request: suspend (String) -> io.ktor.client.statement.HttpResponse,
    ): ApiResponse<T> {
        var sentToken: String? = null
        val response = safeApiCall<T> {
            val token = session.validToken() ?: error("catalog_session_unavailable")
            sentToken = token
            request(token)
        }
        val rejected = sentToken
        if (response !is ApiResponse.Error || response.statusCode != 401 || rejected == null) return response
        // One retry only. A late rejection must not clear a token another request refreshed.
        return safeApiCall {
            session.invalidateRejectedToken(rejected)
            val token = session.validToken() ?: error("catalog_session_unavailable")
            request(token)
        }
    }
}

internal object WineCatalogRoutes {
    const val WINES = "v1/wines"
    const val SEARCH = "$WINES/search"
}
