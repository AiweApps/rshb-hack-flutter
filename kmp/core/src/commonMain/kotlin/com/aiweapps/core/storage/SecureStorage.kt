package com.aiweapps.core.storage

/**
 * Encrypted key-value storage for sensitive data such as auth tokens
 * (Android Keystore backed AES/GCM on Android, Keychain on iOS).
 */
interface SecureStorage {
    suspend fun getString(key: String): String?
    suspend fun putString(key: String, value: String)
    suspend fun remove(key: String)
    suspend fun clear()
}

expect class SecureStorageProvider {
    fun create(name: String): SecureStorage
}
