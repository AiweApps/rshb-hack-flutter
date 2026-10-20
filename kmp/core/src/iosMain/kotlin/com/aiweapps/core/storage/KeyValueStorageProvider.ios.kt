package com.aiweapps.core.storage

import platform.Foundation.NSUserDefaults

actual class KeyValueStorageProvider {

    actual fun create(name: String): KeyValueStorage =
        UserDefaultsKeyValueStorage(suiteName = name)
}

private class UserDefaultsKeyValueStorage(
    private val suiteName: String,
) : KeyValueStorage {

    private val defaults = NSUserDefaults(suiteName = suiteName)

    override fun getString(key: String): String? = defaults.stringForKey(key)

    override fun putString(key: String, value: String) {
        defaults.setObject(value, key)
    }

    override fun getBoolean(key: String, default: Boolean): Boolean =
        if (contains(key)) defaults.boolForKey(key) else default

    override fun putBoolean(key: String, value: Boolean) {
        defaults.setBool(value, key)
    }

    override fun getInt(key: String, default: Int): Int =
        if (contains(key)) defaults.integerForKey(key).toInt() else default

    override fun putInt(key: String, value: Int) {
        defaults.setInteger(value.toLong(), key)
    }

    override fun getLong(key: String, default: Long): Long =
        if (contains(key)) defaults.integerForKey(key) else default

    override fun putLong(key: String, value: Long) {
        defaults.setInteger(value, key)
    }

    override fun contains(key: String): Boolean = defaults.objectForKey(key) != null

    override fun remove(key: String) {
        defaults.removeObjectForKey(key)
    }

    override fun clear() {
        // Removing the whole persistent domain is the only way to wipe a suite,
        // `dictionaryRepresentation` also contains inherited global defaults.
        defaults.removePersistentDomainForName(suiteName)
    }
}
