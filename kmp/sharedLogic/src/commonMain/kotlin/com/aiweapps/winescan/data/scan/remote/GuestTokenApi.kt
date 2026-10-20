package com.aiweapps.winescan.data.scan.remote

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.core.network.safeApiCall
import com.aiweapps.winescan.config.ApiConstants
import com.aiweapps.winescan.data.scan.model.GuestTokenDto
import io.ktor.client.HttpClient
import io.ktor.client.plugins.timeout
import io.ktor.client.request.post
import io.ktor.client.request.setBody

/**
 * Must be constructed with the *plain* HTTP client: the token call must not go through
 * the Bearer plugin whose refresh it implements, or a 401 would recurse.
 */
internal class GuestTokenApi(private val httpClient: HttpClient) {

    suspend fun issue(): ApiResponse<GuestTokenDto> = safeApiCall {
        httpClient.post(ScanRoutes.GUEST_TOKEN) {
            setBody(EMPTY_JSON_BODY)
            timeout { requestTimeoutMillis = ApiConstants.GUEST_TOKEN_TIMEOUT_MS }
        }
    }

    private companion object {
        const val EMPTY_JSON_BODY = "{}"
    }
}
