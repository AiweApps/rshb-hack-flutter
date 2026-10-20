package com.aiweapps.core.storage

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

actual class KeyValueStorageProvider(private val context: Context) {

    actual fun create(name: String): KeyValueStorage =
        SharedPreferencesKeyValueStorage(context.getSharedPreferences(name, Context.MODE_PRIVATE))
}

private class SharedPreferencesKeyValueStorage(
    private val preferences: SharedPreferences,
) : KeyValueStorage {

    override fun getString(key: String): String? = preferences.getString(key, null)

    override fun putString(key: String, value: String) {
        preferences.edit { putString(key, value) }
    }

    override fun getBoolean(key: String, default: Boolean): Boolean =
        preferences.getBoolean(key, default)

    override fun putBoolean(key: String, value: Boolean) {
        preferences.edit { putBoolean(key, value) }
    }

    override fun getInt(key: String, default: Int): Int = preferences.getInt(key, default)

    override fun putInt(key: String, value: Int) {
        preferences.edit { putInt(key, value) }
    }

    override fun getLong(key: String, default: Long): Long = preferences.getLong(key, default)

    override fun putLong(key: String, value: Long) {
        preferences.edit { putLong(key, value) }
    }

    override fun contains(key: String): Boolean = preferences.contains(key)

    override fun remove(key: String) {
        preferences.edit { remove(key) }
    }

    override fun clear() {
        preferences.edit { clear() }
    }
}
