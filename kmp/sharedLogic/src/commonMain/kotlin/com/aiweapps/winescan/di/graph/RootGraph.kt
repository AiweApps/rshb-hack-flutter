package com.aiweapps.winescan.di.graph

import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.winescan.components.main.DefaultMainComponent
import com.aiweapps.winescan.components.main.MainComponent
import com.aiweapps.winescan.components.onboarding.DefaultOnboardingComponent
import com.aiweapps.winescan.components.onboarding.OnboardingComponent
import com.aiweapps.winescan.components.root.DefaultRootComponent
import com.aiweapps.winescan.components.root.RootComponent
import com.aiweapps.winescan.components.splash.DefaultSplashComponent
import com.aiweapps.winescan.components.splash.SplashComponent
import com.aiweapps.winescan.domain.preferences.repository.AppPreferencesRepository
import com.aiweapps.winescan.domain.theme.repository.ThemeRepository

class RootGraph(
    scan: ScanGraph,
    history: HistoryGraph,
    compare: CompareGraph,
    settings: SettingsGraph,
    assistant: AssistantGraph,
    preferences: AppPreferencesRepository,
    themeRepository: ThemeRepository,
    analytics: AnalyticsTracker,
) {

    val splashFactory = SplashComponent.Factory { componentContext, onFinished ->
        DefaultSplashComponent(componentContext, preferences, onFinished)
    }

    val onboardingFactory = OnboardingComponent.Factory { componentContext, onFinished ->
        DefaultOnboardingComponent(componentContext, preferences, analytics, onFinished)
    }

    val mainFactory = MainComponent.Factory { componentContext, onOpenResult, onOpenOnboarding, onOpenPairing ->
        DefaultMainComponent(
            componentContext = componentContext,
            scanHomeFactory = scan.homeFactory,
            historyFactory = history.historyFactory,
            compareFactory = compare.compareFactory,
            settingsFactory = settings.settingsFactory,
            assistantFactory = assistant.assistantFactory,
            compareRepository = compare.compareRepository,
            analytics = analytics,
            onOpenResult = onOpenResult,
            onOpenOnboarding = onOpenOnboarding,
            onOpenPairing = onOpenPairing,
        )
    }

    val rootFactory = RootComponent.Factory { componentContext ->
        DefaultRootComponent(
            componentContext = componentContext,
            splashFactory = splashFactory,
            onboardingFactory = onboardingFactory,
            mainFactory = mainFactory,
            scanResultFactory = scan.resultFactory,
            wineDetailFactory = scan.wineDetailFactory,
            dishPairingFactory = compare.pairingFactory,
            themeRepository = themeRepository,
            analytics = analytics,
        )
    }
}
