package com.aiweapps.winescan.domain.theme.repository

import com.aiweapps.winescan.domain.theme.model.ThemeMode
import kotlinx.coroutines.flow.StateFlow

interface ThemeRepository {
    val themeMode: StateFlow<ThemeMode>
    suspend fun setThemeMode(mode: ThemeMode)
}
