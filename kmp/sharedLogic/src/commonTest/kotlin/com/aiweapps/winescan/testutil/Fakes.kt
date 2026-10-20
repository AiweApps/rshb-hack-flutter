package com.aiweapps.winescan.testutil

import com.aiweapps.core.storage.KeyValueStorage

/**
 * Fakes, not mocks: a fake is a real implementation with a simplified backing store, so a
 * test reads as "given these values" instead of "given this call returns that". They also
 * keep working when an interface gains a method — the compiler points at the fake.
 */
class FakeKeyValueStorage(
    private val values: MutableMap<String, Any> = mutableMapOf(),
) : KeyValueStorage {

    override fun getString(key: String): String? = values[key] as? String

    override fun putString(key: String, value: String) {
        values[key] = value
    }

    override fun getBoolean(key: String, default: Boolean): Boolean =
        values[key] as? Boolean ?: default

    override fun putBoolean(key: String, value: Boolean) {
        values[key] = value
    }

    override fun getInt(key: String, default: Int): Int = values[key] as? Int ?: default

    override fun putInt(key: String, value: Int) {
        values[key] = value
    }

    override fun getLong(key: String, default: Long): Long = values[key] as? Long ?: default

    override fun putLong(key: String, value: Long) {
        values[key] = value
    }

    override fun contains(key: String): Boolean = values.containsKey(key)

    override fun remove(key: String) {
        values.remove(key)
    }

    override fun clear() {
        values.clear()
    }
}
