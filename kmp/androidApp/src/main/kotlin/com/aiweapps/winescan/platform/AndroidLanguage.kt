package com.aiweapps.winescan.platform

import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import com.aiweapps.core.platform.PlatformLanguage
import java.util.Locale

/**
 * Android side of [PlatformLanguage]: the per-app language through AppCompat, which maps to
 * the system setting on API 33+ and persists it by itself below that.
 */
internal class AndroidLanguage : PlatformLanguage {

    override fun currentLanguage(): String {
        val applied = AppCompatDelegate.getApplicationLocales().get(0) ?: Locale.getDefault()
        return applied.language.takeIf { it in SUPPORTED } ?: DEFAULT_LANGUAGE
    }

    override fun selectableLanguages(): List<String> = SUPPORTED

    override fun setLanguage(code: String) {
        AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(code))
    }

    override fun openLanguageSettings() {
        // Never reached: the app switches its locale itself. Kept to honour the interface.
    }

    private companion object {
        const val DEFAULT_LANGUAGE = "ru"
        val SUPPORTED = listOf("ru", "en")
    }
}
