package com.aiweapps.winescan.config

import com.aiweapps.winescan.domain.scan.model.ScannerBuild

/**
 * Everything about the build that shared code must not guess.
 *
 * Built by each platform at startup and handed to `initKoin`, rather than read from a
 * compile-time constant inside `:sharedLogic`: Android knows it from `BuildConfig`, iOS
 * from the `DEBUG` compilation condition and its bundle, and a test simply constructs the
 * config it wants. That is also why the base URL lives on [AppEnvironment] and not in
 * `:core` — a base URL is a fact about this product, and `:core` is not allowed to know it.
 */
data class AppConfig(
    val environment: AppEnvironment,
    val isDebug: Boolean,
    /** Marketing version and build number, as the stores show them. */
    val appVersion: String,
    val appBuild: String,
    /** Local development service. No assistant token is bundled in release builds. */
    val assistantBaseUrl: String? = "https://wines.aiweapps.com/assistant/",
    val assistantAccessToken: String? = null,
    val scannerBuild: ScannerBuild = ScannerBuild.SERVER,
) {
    /**
     * Body logging prints request and response payloads, which carry the guest Bearer.
     * Anything but a debug build must keep it off.
     */
    val enableNetworkLogging: Boolean get() = isDebug

    companion object {
        /** The configuration a test gets unless it says otherwise. */
        fun debug(environment: AppEnvironment = AppEnvironment.DEV): AppConfig =
            AppConfig(environment = environment, isDebug = true, appVersion = "0.0", appBuild = "0")
    }
}

/**
 * Where the app points. Adding an environment means adding a constant here and mapping the
 * platform build to it — nothing else in the shared code changes.
 */
enum class AppEnvironment(
    /** Origin of the recognition API, with a trailing slash so routes can be relative. */
    val apiBaseUrl: String,
    val analyticsEnabled: Boolean,
) {
    /** The hackathon has one backend; the split is kept as the seam a real product fills. */
    DEV(apiBaseUrl = "https://vines.aiweapps.com/", analyticsEnabled = false),
    PROD(apiBaseUrl = "https://vines.aiweapps.com/", analyticsEnabled = true),
}
