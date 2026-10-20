package com.aiweapps.winescan.di.graph

import com.aiweapps.winescan.components.settings.DefaultSettingsComponent
import com.aiweapps.winescan.components.settings.SettingsComponent
import com.aiweapps.winescan.components.settings.SettingsModalFactories
import com.aiweapps.winescan.components.settings.about.AboutComponent
import com.aiweapps.winescan.components.settings.about.DefaultAboutComponent
import com.aiweapps.winescan.components.settings.picker.DefaultLanguagePickerComponent
import com.aiweapps.winescan.components.settings.picker.DefaultThemePickerComponent
import com.aiweapps.winescan.components.settings.picker.LanguagePickerComponent
import com.aiweapps.winescan.components.settings.picker.ThemePickerComponent
import com.aiweapps.winescan.di.dependencies.SettingsDependencies

class SettingsGraph(
    settingsDeps: SettingsDependencies,
    shared: SharedGraph,
) {

    /** Private: only the settings tab opens these sheets. */
    private val modalFactories = SettingsModalFactories(
        themePicker = ThemePickerComponent.Factory { componentContext, current, onSelected, onCancel ->
            DefaultThemePickerComponent(componentContext, current, onSelected, onCancel)
        },
        languagePicker = LanguagePickerComponent.Factory { componentContext, current, codes, onSelected, onCancel ->
            DefaultLanguagePickerComponent(componentContext, current, codes, onSelected, onCancel)
        },
        serviceDetail = shared.serviceDetailFactory,
        about = AboutComponent.Factory { componentContext, onClose -> DefaultAboutComponent(componentContext, onClose) },
        confirmClear = shared.confirmClearHistoryFactory,
    )

    val settingsFactory = SettingsComponent.Factory { componentContext, onOpenOnboarding ->
        DefaultSettingsComponent(
            componentContext = componentContext,
            appConfig = settingsDeps.appConfig,
            statusMonitor = settingsDeps.statusMonitor,
            historyRepository = settingsDeps.historyRepository,
            preferences = settingsDeps.preferences,
            themeRepository = settingsDeps.themeRepository,
            platformLanguage = settingsDeps.platformLanguage,
            platformLinks = settingsDeps.platformLinks,
            modalFactories = modalFactories,
            onOpenOnboarding = onOpenOnboarding,
            backendControls = settingsDeps.backendControls,
        )
    }
}
