package com.aiweapps.winescan.data.preferences

import com.aiweapps.core.storage.KeyValueStorage
import com.aiweapps.winescan.data.storage.StorageKeys
import com.aiweapps.winescan.domain.preferences.repository.AppPreferencesRepository

internal class AppPreferencesRepositoryImpl(
    private val storage: KeyValueStorage,
) : AppPreferencesRepository {

    override val isOnboardingDone: Boolean
        get() = storage.getBoolean(StorageKeys.IS_ONBOARDING_DONE, default = false)

    override fun setOnboardingDone(value: Boolean) {
        storage.putBoolean(StorageKeys.IS_ONBOARDING_DONE, value)
    }
}
