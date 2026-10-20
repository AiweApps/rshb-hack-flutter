package com.aiweapps.winescan.platform

import android.content.Context
import android.os.Bundle
import com.aiweapps.core.analytics.AnalyticsTracker
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.FirebaseApp

internal class AndroidAnalytics(context: Context) : AnalyticsTracker {

    private val firebase = if (FirebaseApp.getApps(context).isNotEmpty()) FirebaseAnalytics.getInstance(context) else null

    override fun logEvent(name: String, params: Map<String, String>) {
        firebase?.logEvent(name, Bundle().apply { params.forEach { (key, value) -> putString(key, value) } })
    }

    override fun logScreen(name: String) {
        firebase?.logEvent(
            FirebaseAnalytics.Event.SCREEN_VIEW,
            Bundle().apply { putString(FirebaseAnalytics.Param.SCREEN_NAME, name) },
        )
    }
}
