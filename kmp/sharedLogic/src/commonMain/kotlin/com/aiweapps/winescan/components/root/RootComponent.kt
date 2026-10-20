package com.aiweapps.winescan.components.root

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.stack.ChildStack
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.main.MainComponent
import com.aiweapps.winescan.components.pairing.DishPairingComponent
import com.aiweapps.winescan.components.onboarding.OnboardingComponent
import com.aiweapps.winescan.components.scan.result.ScanResultComponent
import com.aiweapps.winescan.components.splash.SplashComponent
import com.aiweapps.winescan.components.wine.detail.WineDetailComponent
import com.aiweapps.winescan.domain.theme.model.ThemeMode

interface RootComponent {

    val childStack: Value<ChildStack<*, Child>>

    val themeMode: Value<ThemeMode>

    sealed class Child {
        class Splash(val component: SplashComponent) : Child()
        class Onboarding(val component: OnboardingComponent) : Child()
        class Main(val component: MainComponent) : Child()
        class ScanResult(val component: ScanResultComponent) : Child()
        class WineDetail(val component: WineDetailComponent) : Child()
        class DishPairing(val component: DishPairingComponent) : Child()
    }

    fun interface Factory {
        fun create(componentContext: ComponentContext): RootComponent
    }
}
