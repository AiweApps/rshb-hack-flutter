package com.aiweapps.winescan.components.onboarding

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.onboarding.model.OnboardingState

/** Three intro pages; finishing (or skipping) marks the intro as seen and opens the assistant. */
interface OnboardingComponent {

    val state: Value<OnboardingState>

    /** The pager landed on [pageIndex] by a swipe. */
    fun onPageChanged(pageIndex: Int)

    fun onNextClicked()

    fun onSkipClicked()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            onFinished: () -> Unit,
        ): OnboardingComponent
    }
}
