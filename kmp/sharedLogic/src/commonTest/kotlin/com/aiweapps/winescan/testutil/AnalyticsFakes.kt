package com.aiweapps.winescan.testutil

import com.aiweapps.core.analytics.AnalyticsTracker

/** Records what would reach the SDK: what is logged, and with what, is decided in shared code. */
class FakeAnalyticsTracker : AnalyticsTracker {

    val events = mutableListOf<Pair<String, Map<String, String>>>()
    val screens = mutableListOf<String>()

    fun eventsNamed(name: String): List<Map<String, String>> = events.filter { it.first == name }.map { it.second }

    override fun logEvent(name: String, params: Map<String, String>) {
        events += name to params
    }

    override fun logScreen(name: String) {
        screens += name
    }
}
