package com.aiweapps.winescan.components.onboarding

import com.arkivanov.decompose.ComponentContext
import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.components.base.BaseStatefulComponent
import com.aiweapps.winescan.components.onboarding.model.OnboardingState
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.config.AnalyticsValues
import com.aiweapps.winescan.domain.preferences.repository.AppPreferencesRepository

internal class DefaultOnboardingComponent(
    componentContext: ComponentContext,
    private val preferences: AppPreferencesRepository,
    private val analytics: AnalyticsTracker,
    private val onFinished: () -> Unit,
) : OnboardingComponent, BaseStatefulComponent<OnboardingState>(
    componentContext = componentContext,
    initialState = OnboardingState(),
) {

    private var isFinished = false

    override fun onPageChanged(pageIndex: Int) {
        if (isFinished) return
        updateState { copy(pageIndex = pageIndex.coerceIn(0, pageCount - 1), targetPage = pageIndex.coerceIn(0, pageCount - 1)) }
    }

    override fun onNextClicked() {
        if (isFinished) return
        if (currentState.isLastPage) {
            finish(skippedFrom = null)
        } else {
            updateState {
                // Programmatic SwiftUI page changes do not call the selection binding's setter.
                val next = (pageIndex + 1).coerceAtMost(pageCount - 1)
                copy(pageIndex = next, targetPage = next)
            }
        }
    }

    override fun onSkipClicked() {
        finish(skippedFrom = currentState.pageIndex)
    }

    /** [skippedFrom] is the page «Skip» was tapped on; `null` when the last page was reached. */
    private fun finish(skippedFrom: Int?) {
        if (isFinished) return
        isFinished = true
        preferences.setOnboardingDone(true)
        analytics.logEvent(
            AnalyticsEvents.ONBOARDING_FINISHED,
            buildMap {
                put(
                    AnalyticsParams.RESULT,
                    if (skippedFrom == null) AnalyticsValues.RESULT_COMPLETED else AnalyticsValues.RESULT_SKIPPED,
                )
                skippedFrom?.let { put(AnalyticsParams.SKIPPED_FROM, it.toString()) }
            },
        )
        onFinished()
    }
}
