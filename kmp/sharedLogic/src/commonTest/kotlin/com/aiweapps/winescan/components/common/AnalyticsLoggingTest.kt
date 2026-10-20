package com.aiweapps.winescan.components.common

import com.arkivanov.decompose.DefaultComponentContext
import com.arkivanov.essenty.lifecycle.LifecycleRegistry
import com.arkivanov.essenty.lifecycle.create
import com.arkivanov.essenty.lifecycle.pause
import com.arkivanov.essenty.lifecycle.resume
import com.arkivanov.essenty.lifecycle.stop
import com.aiweapps.winescan.testutil.FakeAnalyticsTracker
import kotlin.test.Test
import kotlin.test.assertEquals

class AnalyticsLoggingTest {

    @Test
    fun aScreenIsLoggedOnEveryReturnButNotOnAPause() {
        val lifecycle = LifecycleRegistry()
        val analytics = FakeAnalyticsTracker()
        DefaultComponentContext(lifecycle).trackScreen(analytics, "scan")

        lifecycle.create()
        lifecycle.resume()
        // The app switcher on iOS: paused, still on screen.
        lifecycle.pause()
        lifecycle.resume()
        // Another screen pushed over it, then popped.
        lifecycle.stop()
        lifecycle.resume()

        assertEquals(listOf("scan", "scan"), analytics.screens)
    }
}
