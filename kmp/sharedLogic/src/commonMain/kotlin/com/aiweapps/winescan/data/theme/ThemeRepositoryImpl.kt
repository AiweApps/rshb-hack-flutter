package com.aiweapps.winescan.data.theme

import com.aiweapps.core.storage.KeyValueStorage
import com.aiweapps.winescan.data.storage.StorageKeys
import com.aiweapps.winescan.domain.theme.model.ThemeMode
import com.aiweapps.winescan.domain.theme.repository.ThemeRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

internal class ThemeRepositoryImpl(
    private val storage: KeyValueStorage,
) : ThemeRepository {

    private val _themeMode = MutableStateFlow(readPersistedMode())
    override val themeMode: StateFlow<ThemeMode> = _themeMode.asStateFlow()

    override suspend fun setThemeMode(mode: ThemeMode) {
        storage.putString(StorageKeys.THEME_MODE, mode.name)
        _themeMode.value = mode
    }

    private fun readPersistedMode(): ThemeMode {
        val stored = storage.getString(StorageKeys.THEME_MODE) ?: return ThemeMode.System
        return ThemeMode.entries.firstOrNull { it.name == stored } ?: ThemeMode.System
    }
}
