package com.aiweapps.winescan.data.session

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.core.network.auth.AuthProvider
import com.aiweapps.core.network.auth.AuthTokens
import com.aiweapps.core.network.auth.TokenRefreshResult
import com.aiweapps.core.storage.SecureStorage
import com.aiweapps.winescan.config.ApiConstants
import com.aiweapps.winescan.data.scan.remote.GuestTokenApi
import com.aiweapps.winescan.data.storage.StorageKeys
import com.aiweapps.winescan.domain.session.GuestSession
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

/**
 * One object plays both roles — the app's [GuestSession] and the transport's
 * [AuthProvider] — because they are the same token: what the Bearer plugin attaches to a
 * request is what the reference images need as a header.
 *
 * The token is not an identity: the backend issues a fresh guest on every call to the
 * token endpoint, so the app keeps one and only asks for another when the current one
 * expired or was rejected. Concurrent callers share one fetch through [mutex].
 */
@OptIn(ExperimentalTime::class)
internal class GuestSessionImpl(
    private val tokenApi: GuestTokenApi,
    private val secureStorage: SecureStorage,
    private val clock: Clock = Clock.System,
) : GuestSession, AuthProvider {

    private val mutex = Mutex()
    private var cached: StoredToken? = null
    private var loaded = false

    override suspend fun validToken(): String? = mutex.withLock {
        currentOrNull()?.token ?: fetch()?.token
    }

    override suspend fun loadTokens(): AuthTokens? = validToken()?.let { AuthTokens(accessToken = it) }

    override suspend fun refreshTokens(): TokenRefreshResult = mutex.withLock {
        when (val fetched = fetch()) {
            null -> TokenRefreshResult.Failed
            else -> TokenRefreshResult.Success(AuthTokens(accessToken = fetched.token))
        }
    }

    override suspend fun invalidateRejectedToken(rejectedToken: String) {
        mutex.withLock {
            currentOrNull() // Load the stored token before comparing, even if it has just expired.
            if (cached?.token == rejectedToken) clearTokenLocked()
        }
    }

    override suspend fun onUnauthorized() {
        mutex.withLock { clearTokenLocked() }
    }

    private suspend fun clearTokenLocked() {
        cached = null
        loaded = true
        secureStorage.remove(StorageKeys.GUEST_TOKEN)
        secureStorage.remove(StorageKeys.GUEST_TOKEN_EXPIRES_AT)
    }

    private suspend fun currentOrNull(): StoredToken? {
        if (!loaded) {
            loaded = true
            // Unreadable storage (a restored backup, a changed keychain group) just means
            // a new guest session; nothing of value is lost.
            val token = secureStorage.getString(StorageKeys.GUEST_TOKEN)
            val expiresAt = secureStorage.getString(StorageKeys.GUEST_TOKEN_EXPIRES_AT)?.toLongOrNull()
            cached = if (token != null && expiresAt != null) StoredToken(token, expiresAt) else null
        }
        val stored = cached ?: return null
        val deadline = clock.now().toEpochMilliseconds() + ApiConstants.GUEST_TOKEN_EXPIRY_MARGIN_MS
        return stored.takeIf { it.expiresAtMillis > deadline }
    }

    private suspend fun fetch(): StoredToken? {
        val response = tokenApi.issue() as? ApiResponse.Success ?: return null
        val dto = response.data
        if (dto.accessToken.isEmpty()) return null
        val stored = StoredToken(
            token = dto.accessToken,
            expiresAtMillis = clock.now().toEpochMilliseconds() + dto.expiresIn * MILLIS_PER_SECOND,
        )
        cached = stored
        // Usable from memory at once; a keychain that refuses to store it only costs a new
        // guest session on the next launch.
        secureStorage.putString(StorageKeys.GUEST_TOKEN, stored.token)
        secureStorage.putString(StorageKeys.GUEST_TOKEN_EXPIRES_AT, stored.expiresAtMillis.toString())
        return stored
    }

    private data class StoredToken(val token: String, val expiresAtMillis: Long)

    private companion object {
        const val MILLIS_PER_SECOND = 1_000L
    }
}
