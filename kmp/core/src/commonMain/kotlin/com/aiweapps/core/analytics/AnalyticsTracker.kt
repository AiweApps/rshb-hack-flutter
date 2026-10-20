package com.aiweapps.core.analytics

/** Implemented by the app, which links the SDK. Values are text: both SDKs cap one at 100 characters. */
interface AnalyticsTracker {

    fun logEvent(name: String, params: Map<String, String>)

    /** The screen now in front of the user; called on every return to it, not once. */
    fun logScreen(name: String)
}
