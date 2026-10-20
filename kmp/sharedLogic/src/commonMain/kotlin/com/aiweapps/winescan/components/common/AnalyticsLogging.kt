package com.aiweapps.winescan.components.common

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.essenty.lifecycle.doOnStart
import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.domain.compare.model.AddToCompareResult

// Every return to the front counts, not the first one only. On start, not on resume: iOS
// pauses the lifecycle for the app switcher and Control Center, which are not a new view.
internal fun ComponentContext.trackScreen(analytics: AnalyticsTracker, name: String) {
    lifecycle.doOnStart { analytics.logScreen(name) }
}

internal fun logCompareAdded(analytics: AnalyticsTracker, screen: String, result: AddToCompareResult) {
    analytics.logEvent(
        AnalyticsEvents.COMPARE_ADD,
        mapOf(AnalyticsParams.SCREEN to screen, AnalyticsParams.RESULT to result.name.lowercase()),
    )
}
