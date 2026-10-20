package com.aiweapps.core.storage

expect class KeyValueStorageProvider {
    fun create(name: String): KeyValueStorage
}
