package com.aiweapps.winescan.root

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.graphics.toArgb
import com.aiweapps.winescan.activity.MainActivity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import com.aiweapps.winescan.components.root.RootComponent
import com.aiweapps.winescan.domain.theme.model.ThemeMode
import com.aiweapps.winescan.main.MainContent
import com.aiweapps.winescan.onboarding.OnboardingContent
import com.aiweapps.winescan.pairing.DishPairingContent
import com.aiweapps.winescan.scan.result.ScanResultContent
import com.aiweapps.winescan.splash.SplashContent
import com.aiweapps.winescan.wine.detail.WineDetailContent
import com.aiweapps.winescan.uikit.theme.AppTheme
import com.arkivanov.decompose.extensions.compose.stack.Children
import com.arkivanov.decompose.extensions.compose.stack.animation.fade
import com.arkivanov.decompose.extensions.compose.stack.animation.slide
import com.arkivanov.decompose.extensions.compose.stack.animation.stackAnimation
import com.arkivanov.decompose.extensions.compose.subscribeAsState

@Composable
fun RootContent(component: RootComponent) {
    val themeMode by component.themeMode.subscribeAsState()
    val isDark = when (themeMode) {
        ThemeMode.Light -> false
        ThemeMode.Dark -> true
        ThemeMode.System -> isSystemInDarkTheme()
    }

    AppTheme(isDark = isDark) {
        val view = LocalView.current
        val barBackground = MaterialTheme.colorScheme.background.toArgb()
        LaunchedEffect(isDark, barBackground, view) {
            (view.context as? MainActivity)?.updateAppSystemBars(isDark, barBackground)
        }
        Children(
            stack = component.childStack,
            // The result and its follow-ups cover the tabs, so they slide over them; the rest crossfades.
            animation = stackAnimation { child, _, _ ->
                when (child.instance) {
                    is RootComponent.Child.ScanResult,
                    is RootComponent.Child.WineDetail,
                    is RootComponent.Child.DishPairing -> slide()
                    else -> fade()
                }
            },
        ) { child ->
            when (val instance = child.instance) {
                is RootComponent.Child.Splash -> SplashContent()
                is RootComponent.Child.Onboarding -> OnboardingContent(instance.component)
                is RootComponent.Child.Main -> MainContent(instance.component)
                is RootComponent.Child.ScanResult -> ScanResultContent(instance.component)
                is RootComponent.Child.DishPairing -> DishPairingContent(instance.component)
                is RootComponent.Child.WineDetail -> WineDetailContent(instance.component)
            }
        }
    }
}
