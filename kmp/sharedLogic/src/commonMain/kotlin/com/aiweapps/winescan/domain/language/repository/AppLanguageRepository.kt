package com.aiweapps.winescan.domain.language.repository

import kotlinx.coroutines.flow.StateFlow

/** The UI language as shared code sees it, for data that comes in several languages. */
interface AppLanguageRepository {

    /** ISO 639-1 code of the language the UI shows. */
    val language: StateFlow<String>

    /** Re-reads the platform: the language may change outside the app while it runs. */
    fun refresh()
}
