package com.aiweapps.winescan.domain.preferences.repository

/** Small flags the app remembers between launches. */
interface AppPreferencesRepository {

    val isOnboardingDone: Boolean

    fun setOnboardingDone(value: Boolean)
}
