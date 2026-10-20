package com.aiweapps.core.platform

/**
 * Things only the application can open: the system browser and the app's own page in the
 * system settings. Same shape as [com.aiweapps.core.share.PlatformShare] — an interface
 * implemented by the app and handed to `initKoin` — and for the same reason: both need a
 * window or an Activity that shared code cannot reach.
 */
interface PlatformLinks {

    fun openUrl(url: String)

    /** The app's page in the system settings, where a refused permission lives. */
    fun openAppSettings()
}
