package com.aiweapps.winescan.components.settings.model

import com.aiweapps.core.components.model.BaseScreenState
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.domain.scan.model.ServiceState
import com.aiweapps.winescan.domain.scan.model.ScannerBackendState
import com.aiweapps.winescan.domain.theme.model.ThemeMode

enum class SettingsToast { HISTORY_CLEARED, HISTORY_CLEAR_FAILED }

/**
 * Everything the settings tab draws. [screenState] is `Content` from the start: the theme
 * and the language are read synchronously, and the service status arrives later into
 * [serviceState] without ever taking the screen down.
 */
data class SettingsState(
    override val screenState: ScreenState = ScreenState.Content,
    val themeMode: ThemeMode = ThemeMode.System,
    /** ISO 639-1 code of the UI language. */
    val languageCode: String = "",
    val serviceState: ServiceState = ServiceState.checking,
    /** Size of the wine catalogue on the server, when the status told it. */
    val catalogCards: Int? = null,
    /** The history is being wiped; a second confirm is ignored meanwhile. */
    val isClearingHistory: Boolean = false,
    val appVersion: String = "",
    val appBuild: String = "",
    val toast: SettingsToast? = null,
    val scannerBackend: ScannerBackendState? = null,
) : BaseScreenState
