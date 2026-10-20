package com.aiweapps.core.storage

/**
 * Simple multiplatform key-value storage for non-sensitive data
 * (SharedPreferences on Android, NSUserDefaults on iOS).
 */
interface KeyValueStorage {
    fun getString(key: String): String?
    fun putString(key: String, value: String)
    fun getBoolean(key: String, default: Boolean = false): Boolean
    fun putBoolean(key: String, value: Boolean)
    fun getInt(key: String, default: Int = 0): Int
    fun putInt(key: String, value: Int)
    fun getLong(key: String, default: Long = 0L): Long
    fun putLong(key: String, value: Long)
    fun contains(key: String): Boolean
    fun remove(key: String)
    fun clear()
}
