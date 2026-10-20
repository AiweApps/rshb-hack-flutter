package com.aiweapps.winescan.data.language

import com.aiweapps.core.platform.PlatformLanguage
import com.aiweapps.winescan.domain.language.repository.AppLanguageRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

internal class AppLanguageRepositoryImpl(
    private val platformLanguage: PlatformLanguage,
) : AppLanguageRepository {

    private val _language = MutableStateFlow(platformLanguage.currentLanguage())
    override val language: StateFlow<String> = _language.asStateFlow()

    override fun refresh() {
        _language.value = platformLanguage.currentLanguage()
    }
}
