package com.aiweapps.winescan.data.assistant.repository

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.core.storage.SecureStorage
import com.aiweapps.core.storage.KeyValueStorage
import com.aiweapps.winescan.data.storage.StorageKeys
import com.aiweapps.winescan.data.assistant.remote.AssistantAccountApi
import com.aiweapps.winescan.domain.assistant.repository.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.uuid.Uuid
import kotlin.uuid.ExperimentalUuidApi

@OptIn(ExperimentalUuidApi::class, kotlin.time.ExperimentalTime::class)
internal class AssistantAccountRepositoryImpl(
    private val api: AssistantAccountApi, private val secure: SecureStorage,
    private val preferences: KeyValueStorage,
) : AssistantAccountRepository {
    private val mutableAccount = MutableStateFlow<AssistantAccount?>(null)
    override val account = mutableAccount.asStateFlow()
    init {
        // Seed before creating the device ID: a killed/offline first launch must remain retryable.
        // An older installation already has a device marker even after explicit logout.
        if (!preferences.contains(StorageKeys.ASSISTANT_BOOTSTRAP_STATUS)) {
            preferences.putString(StorageKeys.ASSISTANT_BOOTSTRAP_STATUS,
                if (preferences.contains(StorageKeys.ASSISTANT_DEVICE_ID)) BOOTSTRAP_CLOSED else BOOTSTRAP_PENDING)
        }
    }
    override val deviceId: String = preferences.getString(StorageKeys.ASSISTANT_DEVICE_ID)
        ?.takeIf { runCatching { Uuid.parse(it) }.isSuccess } ?: Uuid.random().toString().also {
            preferences.putString(StorageKeys.ASSISTANT_DEVICE_ID, it)
        }
    private val mutex = Mutex()
    private var initialized = false
    override suspend fun initialize() = mutex.withLock {
        if (!initialized) {
            val token = secure.getString(StorageKeys.ASSISTANT_TOKEN)
            val subject = secure.getString(StorageKeys.ASSISTANT_SUBJECT)
            val kind = secure.getString(StorageKeys.ASSISTANT_ACCOUNT_KIND)
            val username = secure.getString(StorageKeys.ASSISTANT_USERNAME)
            val expiresAt = secure.getString(StorageKeys.ASSISTANT_EXPIRES_AT)
            // Keychain can survive reinstall. Any old auth footprint disqualifies a new guest.
            if (listOf(token, subject, kind, username, expiresAt).any { !it.isNullOrBlank() }) closeBootstrap()
            if (!subject.isNullOrBlank()) mutableAccount.value = AssistantAccount(
                subject, kind ?: "account", username,
                expired = token.isNullOrBlank() || (expiresAt?.toLongOrNull() ?: 0) <= now(),
            )
            initialized = true
        }
    }
    override suspend fun isFirstUseBootstrapPending(): Boolean {
        initialize()
        return mutex.withLock {
            mutableAccount.value == null &&
                preferences.getString(StorageKeys.ASSISTANT_BOOTSTRAP_STATUS) == BOOTSTRAP_PENDING
        }
    }
    override suspend fun skipFirstUseBootstrap() = mutex.withLock { closeBootstrap() }
    private fun closeBootstrap() {
        preferences.putString(StorageKeys.ASSISTANT_BOOTSTRAP_STATUS, BOOTSTRAP_CLOSED)
    }
    override suspend fun credentials(): AssistantCredentials {
        initialize()
        return mutex.withLock {
            val expiry = secure.getString(StorageKeys.ASSISTANT_EXPIRES_AT)?.toLongOrNull() ?: 0
            if (mutableAccount.value?.expired != false || expiry <= now()) {
                expireLocked()
                throw IllegalStateException("assistant_account_expired")
            }
            AssistantCredentials(secure.getString(StorageKeys.ASSISTANT_TOKEN)
                ?: throw IllegalStateException("assistant_account_expired"), deviceId,
                subject = mutableAccount.value?.subject ?: throw IllegalStateException("assistant_account_expired"))
        }
    }
    override suspend fun startGuest() = mutex.withLock {
        val response = api.guest().requireData()
        accept(response.token, null, response.expiresIn)
        initialized = true
    }
    override suspend fun expireIfCurrent(subject: String, token: String) = mutex.withLock {
        if (mutableAccount.value?.subject == subject && secure.getString(StorageKeys.ASSISTANT_TOKEN) == token) expireLocked()
    }
    override suspend fun expire() = mutex.withLock { expireLocked() }
    private suspend fun expireLocked() {
        secure.remove(StorageKeys.ASSISTANT_TOKEN)
        secure.remove(StorageKeys.ASSISTANT_EXPIRES_AT)
        mutableAccount.value = mutableAccount.value?.copy(expired = true)
    }
    private fun now(): Long = kotlin.time.Clock.System.now().toEpochMilliseconds()
    override suspend fun authenticate(username: String, password: String, register: Boolean) = mutex.withLock {
        require(username.isNotBlank() && password.isNotBlank())
        val response = api.authenticate(username.trim(), password, register).requireData()
        accept(response.token, username.trim(), response.expiresIn)
        initialized = true
    }
    override suspend fun logout() {
        initialize()
        mutex.withLock {
            // Explicit sign-out must not silently create a replacement guest on the next launch.
            closeBootstrap()
            val token = secure.getString(StorageKeys.ASSISTANT_TOKEN)
            if (token != null) {
                val response = api.logout(token)
                if (response is ApiResponse.Error && response.statusCode !in listOf(401, 403)) response.requireData()
            }
            listOf(StorageKeys.ASSISTANT_TOKEN, StorageKeys.ASSISTANT_SUBJECT,
                StorageKeys.ASSISTANT_ACCOUNT_KIND, StorageKeys.ASSISTANT_USERNAME, StorageKeys.ASSISTANT_EXPIRES_AT).forEach { secure.remove(it) }
            mutableAccount.value = null
        }
    }
    private suspend fun accept(token: String, username: String?, expiresIn: Long) {
        val me = api.me(token).requireData()
        require(me.subject.isNotBlank())
        secure.putString(StorageKeys.ASSISTANT_TOKEN, token)
        secure.putString(StorageKeys.ASSISTANT_EXPIRES_AT, (now() + expiresIn.coerceIn(1, 86400) * 1000).toString())
        secure.putString(StorageKeys.ASSISTANT_SUBJECT, me.subject)
        secure.putString(StorageKeys.ASSISTANT_ACCOUNT_KIND, me.kind)
        if (username == null) secure.remove(StorageKeys.ASSISTANT_USERNAME)
        else secure.putString(StorageKeys.ASSISTANT_USERNAME, username)
        closeBootstrap()
        mutableAccount.value = AssistantAccount(me.subject, me.kind, username)
    }
    private companion object {
        const val BOOTSTRAP_PENDING = "pending"
        const val BOOTSTRAP_CLOSED = "closed"
    }
    private fun <T> ApiResponse<T>.requireData(): T = when (this) {
        is ApiResponse.Success -> data
        is ApiResponse.Error -> throw IllegalStateException("assistant_account_${statusCode ?: 0}")
    }
}
