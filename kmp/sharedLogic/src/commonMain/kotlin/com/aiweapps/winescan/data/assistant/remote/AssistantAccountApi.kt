package com.aiweapps.winescan.data.assistant.remote

import com.aiweapps.core.network.safeApiCall
import io.ktor.client.HttpClient
import io.ktor.client.request.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName

@Serializable internal data class AccountLoginDto(val username: String, val password: String)
@Serializable internal data class AccountTokenDto(@SerialName("access_token") val token: String, @SerialName("expires_in") val expiresIn: Long = 86400)
@Serializable internal data class AccountMeDto(val subject: String, @SerialName("account_kind") val kind: String)
internal class AssistantAccountApi(private val auth: HttpClient, private val assistant: HttpClient) {
    suspend fun guest() = safeApiCall<AccountTokenDto> { auth.post(AssistantRoutes.GUEST_TOKEN) }
    suspend fun authenticate(username: String, password: String, register: Boolean) = safeApiCall<AccountTokenDto> {
        auth.post(if (register) AssistantRoutes.REGISTER else AssistantRoutes.LOGIN) { setBody(AccountLoginDto(username, password)) }
    }
    suspend fun me(token: String) = safeApiCall<AccountMeDto> {
        assistant.get(AssistantRoutes.ME) { bearerAuth(token) }
    }
    suspend fun logout(token: String) = safeApiCall<Unit> {
        auth.post(AssistantRoutes.LOGOUT) { bearerAuth(token) }
    }
}
