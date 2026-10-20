package com.aiweapps.winescan.domain.assistant.repository

import kotlinx.coroutines.flow.StateFlow

data class AssistantAccount(val subject: String, val kind: String, val username: String? = null, val expired: Boolean = false)
data class AssistantCredentials(val token: String, val deviceId: String, val subject: String? = null)

/** One independent assistant identity. Recognition's guest session remains separate. */
interface AssistantAccountRepository {
    val account: StateFlow<AssistantAccount?>
    val deviceId: String
    suspend fun initialize()
    /** True only for an unresolved first installation, never logout or an expired identity. */
    suspend fun isFirstUseBootstrapPending(): Boolean
    /** Decline automatic first-use bootstrap when existing local data makes it ineligible. */
    suspend fun skipFirstUseBootstrap()
    suspend fun startGuest()
    /** Reject only the credentials that actually failed, under the account owner mutex. */
    suspend fun expireIfCurrent(subject: String, token: String)
    suspend fun expire()
    suspend fun credentials(): AssistantCredentials
    suspend fun authenticate(username: String, password: String, register: Boolean)
    suspend fun logout()
}
