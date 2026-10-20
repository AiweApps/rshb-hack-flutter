package com.aiweapps.winescan.components.settings

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.common.ConfirmClearHistoryComponent
import com.aiweapps.winescan.components.common.ServiceDetailComponent
import com.aiweapps.winescan.components.settings.about.AboutComponent
import com.aiweapps.winescan.components.settings.model.SettingsState
import com.aiweapps.winescan.components.settings.picker.LanguagePickerComponent
import com.aiweapps.winescan.components.settings.picker.ThemePickerComponent
import com.aiweapps.winescan.domain.theme.model.ThemeMode
import com.aiweapps.winescan.domain.scan.model.ScannerBackend

/**
 * The settings tab: theme, language, service status, help links and the history wipe.
 * Every choice is saved through the repositories and mirrored back into the state.
 */
interface SettingsComponent {

    val state: Value<SettingsState>

    val modalSlot: Value<ChildSlot<*, Modal>>

    /** Opens the theme sheet, for platforms that pick the theme in one. */
    fun onThemeClicked()

    /** A theme picked right in place, from a menu on the row, without the sheet. */
    fun onThemeSelected(mode: ThemeMode)

    fun onScannerBackendSelected(backend: ScannerBackend)
    fun onDownloadLocalModelClicked()
    fun onCancelLocalModelClicked()

    /** Opens the in-app picker, or the system page when the platform owns the choice. */
    fun onLanguageClicked()

    fun onStatusClicked()

    fun onShowOnboardingClicked()

    fun onAboutClicked()

    fun onOpenSiteClicked()

    fun onClearHistoryClicked()

    fun onModalDismissed()

    fun onToastConsumed()

    sealed class Modal {
        class ThemePicker(val component: ThemePickerComponent) : Modal()
        class LanguagePicker(val component: LanguagePickerComponent) : Modal()
        class ServiceDetail(val component: ServiceDetailComponent) : Modal()
        class About(val component: AboutComponent) : Modal()
        class ConfirmClear(val component: ConfirmClearHistoryComponent) : Modal()
    }

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            onOpenOnboarding: () -> Unit,
        ): SettingsComponent
    }
}
