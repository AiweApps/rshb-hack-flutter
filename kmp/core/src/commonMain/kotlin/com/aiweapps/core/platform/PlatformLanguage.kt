package com.aiweapps.core.platform

/**
 * The UI language as the platform manages it.
 *
 * Android lets an app switch its own locale at runtime; iOS does not, and offers the
 * choice on the app's page in the system settings instead. Shared code asks
 * [selectableLanguages]: an empty list means "send the user to [openLanguageSettings]".
 */
interface PlatformLanguage {

    /** ISO 639-1 code of the language the UI is showing right now. */
    fun currentLanguage(): String

    /** Codes the app can switch to by itself; empty when the platform owns the choice. */
    fun selectableLanguages(): List<String>

    fun setLanguage(code: String)

    fun openLanguageSettings()
}
