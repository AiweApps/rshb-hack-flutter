package com.aiweapps.winescan.data.assistant.remote

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.core.network.safeApiCall
import com.aiweapps.winescan.data.assistant.model.SendMessageDto
import com.aiweapps.winescan.data.assistant.model.SendResponseDto
import com.aiweapps.winescan.data.assistant.model.SessionDto
import com.aiweapps.winescan.data.assistant.model.SessionListDto
import com.aiweapps.winescan.data.assistant.model.ReplacementCandidatesDto
import com.aiweapps.winescan.data.assistant.model.ReplacementRequestDto
import com.aiweapps.winescan.data.assistant.model.DinnerSelectionRequestDto
import com.aiweapps.winescan.domain.assistant.repository.AssistantAccountRepository
import com.aiweapps.winescan.domain.assistant.repository.AssistantCredentials
import io.ktor.client.request.bearerAuth
import io.ktor.client.request.header
import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.request.parameter

internal class AssistantApi(private val client: HttpClient, private val accounts: AssistantAccountRepository) {
    suspend fun searchStores(query: String): ApiResponse<com.aiweapps.winescan.data.assistant.model.StoreListDto> = call { credentials ->
        client.get(AssistantRoutes.STORE_SEARCH) { authorize(credentials); parameter("query", query); parameter("limit", 5) }
    }
    suspend fun nearbyStores(latitude: Double, longitude: Double): ApiResponse<com.aiweapps.winescan.data.assistant.model.StoreListDto> = call { credentials ->
        client.get(AssistantRoutes.STORE_NEARBY) { authorize(credentials); parameter("latitude", latitude); parameter("longitude", longitude); parameter("limit", 5) }
    }
    suspend fun confirmStore(id: String, request: com.aiweapps.winescan.data.assistant.model.ConfirmStoreDto): ApiResponse<SendResponseDto> = call { credentials ->
        client.post(AssistantRoutes.confirmStore(id)) { authorize(credentials); setBody(request) }
    }
    suspend fun sessions(): ApiResponse<SessionListDto> = call { credentials ->
        client.get(AssistantRoutes.SESSIONS) { authorize(credentials) }
    }

    suspend fun create(): ApiResponse<SessionDto> = call { credentials ->
        client.post(AssistantRoutes.SESSIONS) { authorize(credentials) }
    }

    suspend fun session(id: String): ApiResponse<SessionDto> = call { credentials ->
        client.get(AssistantRoutes.session(id)) { authorize(credentials) }
    }

    suspend fun send(id: String, request: SendMessageDto): ApiResponse<SendResponseDto> = call { credentials ->
        client.post(AssistantRoutes.messages(id)) { authorize(credentials); setBody(request) }
    }

    suspend fun selectDinner(id: String, sourceMessageId: String, request: DinnerSelectionRequestDto): ApiResponse<SendResponseDto> =
        call { credentials -> client.post(AssistantRoutes.selectDinner(id, sourceMessageId)) { authorize(credentials); setBody(request) } }

    suspend fun replacementCandidates(id: String, sourceMessageId: String, query: String): ApiResponse<ReplacementCandidatesDto> =
        call { credentials -> client.get(AssistantRoutes.replacementCandidates(id, sourceMessageId)) { authorize(credentials); parameter("query", query) } }

    suspend fun replace(id: String, sourceMessageId: String, request: ReplacementRequestDto): ApiResponse<SendResponseDto> =
        call { credentials -> client.post(AssistantRoutes.replace(id, sourceMessageId)) { authorize(credentials); setBody(request) } }
    private suspend inline fun <reified T> call(
        crossinline block: suspend (AssistantCredentials) -> io.ktor.client.statement.HttpResponse,
    ): ApiResponse<T> {
        var sent: AssistantCredentials? = null
        val response = safeApiCall<T> {
            val credentials = accounts.credentials()
            sent = credentials
            block(credentials)
        }
        if (response is ApiResponse.Error && response.statusCode == 401) {
            sent?.let { rejected -> rejected.subject?.let { accounts.expireIfCurrent(it, rejected.token) } }
        }
        return response
    }
    private fun io.ktor.client.request.HttpRequestBuilder.authorize(credentials: AssistantCredentials) {
        bearerAuth(credentials.token)
        header("X-Device-Id", credentials.deviceId)
    }
}
