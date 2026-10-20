package com.aiweapps.winescan.components.splash

import com.arkivanov.decompose.ComponentContext

/**
 * Shows the mark for a moment and sends the user to the intro or to the scanner,
 * depending on whether the intro was seen.
 */
interface SplashComponent {

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            onFinished: (isOnboardingDone: Boolean) -> Unit,
        ): SplashComponent
    }
}
