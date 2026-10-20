package com.aiweapps.winescan.components.settings

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.router.slot.SlotNavigation
import com.arkivanov.decompose.router.slot.activate
import com.arkivanov.decompose.router.slot.childSlot
import com.arkivanov.decompose.router.slot.dismiss
import com.arkivanov.decompose.value.Value
import com.aiweapps.core.components.base.BaseStatefulComponent
import com.aiweapps.core.platform.PlatformLanguage
import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.winescan.components.common.ConfirmClearHistoryComponent
import com.aiweapps.winescan.components.common.ServiceDetailComponent
import com.aiweapps.winescan.components.settings.about.AboutComponent
import com.aiweapps.winescan.components.settings.config.SettingsModalConfig
import com.aiweapps.winescan.components.settings.model.SettingsState
import com.aiweapps.winescan.components.settings.model.SettingsToast
import com.aiweapps.winescan.components.settings.picker.LanguagePickerComponent
import com.aiweapps.winescan.components.settings.picker.ThemePickerComponent
import com.aiweapps.winescan.config.AppConfig
import com.aiweapps.winescan.config.LinkConstants
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.preferences.repository.AppPreferencesRepository
import com.aiweapps.winescan.domain.scan.model.ScannerBackend
import com.aiweapps.winescan.domain.scan.repository.ScannerBackendControls
import com.aiweapps.winescan.domain.status.ServiceStatusMonitor
import com.arkivanov.essenty.lifecycle.doOnPause
import com.arkivanov.essenty.lifecycle.doOnResume
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import com.aiweapps.winescan.domain.theme.model.ThemeMode
import com.aiweapps.winescan.domain.theme.repository.ThemeRepository
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

internal class DefaultSettingsComponent(
    componentContext: ComponentContext,
    private val appConfig: AppConfig,
    private val statusMonitor: ServiceStatusMonitor,
    private val historyRepository: ScanHistoryRepository,
    private val preferences: AppPreferencesRepository,
    private val themeRepository: ThemeRepository,
    private val platformLanguage: PlatformLanguage,
    private val platformLinks: PlatformLinks,
    private val modalFactories: SettingsModalFactories,
    private val onOpenOnboarding: () -> Unit,
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
    private val backendControls: ScannerBackendControls? = null,
) : SettingsComponent, BaseStatefulComponent<SettingsState>(
    componentContext = componentContext,
    initialState = SettingsState(
        themeMode = themeRepository.themeMode.value,
        languageCode = platformLanguage.currentLanguage(),
        appVersion = appConfig.appVersion,
        appBuild = appConfig.appBuild,
    ),
    mainContext = mainContext,
) {

    private val modalNavigation = SlotNavigation<SettingsModalConfig>()

    override val modalSlot: Value<ChildSlot<*, SettingsComponent.Modal>> =
        childSlot(
            source = modalNavigation,
            serializer = SettingsModalConfig.serializer(),
            handleBackButton = true,
            childFactory = ::createModal,
        )

    private var statusJob: Job? = null

    init {
        backendControls?.backendState?.onEach { backend ->
            updateState { copy(scannerBackend = backend) }
        }?.launchIn(scope)
        scope.launch {
            themeRepository.themeMode.collect { mode -> updateState { copy(themeMode = mode) } }
        }
        // The same shared poll as the scanner tab, and only while this tab is on screen.
        lifecycle.doOnResume { watchStatus() }
        lifecycle.doOnPause { statusJob?.cancel() }
    }

    override fun onThemeClicked() {
        modalNavigation.activate(SettingsModalConfig.ThemePicker(currentState.themeMode))
    }

    override fun onScannerBackendSelected(backend: ScannerBackend) {
        backendControls?.selectBackend(backend)
        statusMonitor.refreshNow()
    }

    override fun onDownloadLocalModelClicked() { backendControls?.downloadLocalAssets() }
    override fun onCancelLocalModelClicked() { backendControls?.cancelLocalAssets() }

    override fun onThemeSelected(mode: ThemeMode) {
        if (mode == currentState.themeMode) return
        scope.launch { themeRepository.setThemeMode(mode) }
    }

    override fun onLanguageClicked() {
        val codes = platformLanguage.selectableLanguages()
        if (codes.isEmpty()) {
            platformLanguage.openLanguageSettings()
        } else {
            modalNavigation.activate(SettingsModalConfig.LanguagePicker(current = currentState.languageCode, codes = codes))
        }
    }

    override fun onStatusClicked() {
        modalNavigation.activate(SettingsModalConfig.ServiceDetail(currentState.serviceState.availability))
        statusMonitor.refreshNow()
    }

    override fun onShowOnboardingClicked() {
        // The intro opens by itself on the next launch only while the flag is off; showing
        // it again means resetting it.
        preferences.setOnboardingDone(false)
        onOpenOnboarding()
    }

    override fun onAboutClicked() {
        modalNavigation.activate(SettingsModalConfig.About)
    }

    override fun onOpenSiteClicked() {
        platformLinks.openUrl(LinkConstants.VINO_SVOE_SITE)
    }

    override fun onClearHistoryClicked() {
        if (currentState.isClearingHistory) return
        modalNavigation.activate(SettingsModalConfig.ConfirmClear)
    }

    override fun onModalDismissed() {
        modalNavigation.dismiss()
    }

    override fun onToastConsumed() {
        updateState { copy(toast = null) }
    }

    /** A failed status is never a screen error: it becomes a non-ready pill, as on the scan tab. */
    private fun watchStatus() {
        statusJob?.cancel()
        statusJob = statusMonitor.snapshots
            .onEach { snapshot ->
                updateState { copy(serviceState = snapshot.state, catalogCards = snapshot.catalogCards) }
            }
            .launchIn(scope)
    }

    private fun selectTheme(mode: ThemeMode) {
        modalNavigation.dismiss()
        scope.launch { themeRepository.setThemeMode(mode) }
    }

    private fun selectLanguage(code: String) {
        modalNavigation.dismiss()
        if (code == currentState.languageCode) return
        platformLanguage.setLanguage(code)
        updateState { copy(languageCode = code) }
    }

    private fun clearHistory() {
        modalNavigation.dismiss()
        if (currentState.isClearingHistory) return
        updateState { copy(isClearingHistory = true) }
        scope.launch {
            try {
                historyRepository.clear()
                updateState { copy(isClearingHistory = false, toast = SettingsToast.HISTORY_CLEARED) }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                // A local wipe has no AppError to classify; the user still needs to hear it failed.
                updateState { copy(isClearingHistory = false, toast = SettingsToast.HISTORY_CLEAR_FAILED) }
            }
        }
    }

    private fun createModal(config: SettingsModalConfig, context: ComponentContext): SettingsComponent.Modal =
        when (config) {
            is SettingsModalConfig.ThemePicker -> SettingsComponent.Modal.ThemePicker(
                modalFactories.themePicker.create(
                    componentContext = context,
                    current = config.current,
                    onSelected = ::selectTheme,
                    onCancel = { modalNavigation.dismiss() },
                )
            )
            is SettingsModalConfig.LanguagePicker -> SettingsComponent.Modal.LanguagePicker(
                modalFactories.languagePicker.create(
                    componentContext = context,
                    current = config.current,
                    codes = config.codes,
                    onSelected = ::selectLanguage,
                    onCancel = { modalNavigation.dismiss() },
                )
            )
            is SettingsModalConfig.ServiceDetail -> SettingsComponent.Modal.ServiceDetail(
                modalFactories.serviceDetail.create(
                    componentContext = context,
                    availability = config.availability,
                    onClose = { modalNavigation.dismiss() },
                )
            )
            SettingsModalConfig.About -> SettingsComponent.Modal.About(
                modalFactories.about.create(componentContext = context, onClose = { modalNavigation.dismiss() })
            )
            SettingsModalConfig.ConfirmClear -> SettingsComponent.Modal.ConfirmClear(
                modalFactories.confirmClear.create(
                    componentContext = context,
                    onConfirm = ::clearHistory,
                    onCancel = { modalNavigation.dismiss() },
                )
            )
        }
}

/** The five sheets of the settings tab, bundled so the constructor stays readable. */
class SettingsModalFactories(
    val themePicker: ThemePickerComponent.Factory,
    val languagePicker: LanguagePickerComponent.Factory,
    val serviceDetail: ServiceDetailComponent.Factory,
    val about: AboutComponent.Factory,
    val confirmClear: ConfirmClearHistoryComponent.Factory,
)
