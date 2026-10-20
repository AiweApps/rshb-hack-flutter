package com.aiweapps.winescan.components.splash

import com.arkivanov.decompose.ComponentContext
import com.aiweapps.core.components.base.BaseComponent
import com.aiweapps.winescan.config.TimingConstants
import com.aiweapps.winescan.domain.preferences.repository.AppPreferencesRepository
import kotlin.coroutines.CoroutineContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

internal class DefaultSplashComponent(
    componentContext: ComponentContext,
    private val preferences: AppPreferencesRepository,
    private val onFinished: (isOnboardingDone: Boolean) -> Unit,
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
) : SplashComponent, BaseComponent(componentContext, mainContext) {

    init {
        scope.launch {
            delay(TimingConstants.SPLASH_DELAY_MS)
            onFinished(preferences.isOnboardingDone)
        }
    }
}
