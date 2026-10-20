package com.aiweapps.winescan.di

import com.arkivanov.decompose.ComponentContext
import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.database.DatabaseBuilderProvider
import com.aiweapps.core.files.FileStoreProvider
import com.aiweapps.core.platform.PlatformLanguage
import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.core.share.PlatformShare
import com.aiweapps.core.storage.KeyValueStorageProvider
import com.aiweapps.core.storage.SecureStorageProvider
import com.aiweapps.winescan.components.root.RootComponent
import com.aiweapps.winescan.config.AppConfig
import com.aiweapps.winescan.config.AppEnvironment
import com.aiweapps.winescan.domain.assistant.repository.RetailGateway
import com.aiweapps.winescan.domain.scan.model.ScannerBuild
import com.aiweapps.winescan.domain.scan.repository.LocalScanEngine
import org.koin.core.KoinApplication
import org.koin.core.module.Module
import org.koin.dsl.module
import org.koin.mp.KoinPlatform

/**
 * [isDebug] is passed in from Swift (`#if DEBUG`) rather than derived here: Kotlin/Native
 * has no equivalent of `BuildConfig`, and guessing from the binary kind would silently
 * treat a profiling build as production.
 *
 * The platform services are implemented by Swift classes in `iosApp/platform`. Being
 * parameters of this function is what makes them safe: add a service here and
 * `iOSApp.swift` stops compiling until it supplies one.
 */
fun initKoinIos(
    isDebug: Boolean,
    appVersion: String,
    appBuild: String,
    platformShare: PlatformShare,
    platformLinks: PlatformLinks,
    platformLanguage: PlatformLanguage,
    assistantBaseUrl: String?,
    assistantAccessToken: String?,
    retailGateway: RetailGateway,
    analyticsTracker: AnalyticsTracker,
    scannerBuild: ScannerBuild = ScannerBuild.SERVER,
    localScanEngine: LocalScanEngine? = null,
): KoinApplication {
    return initKoin(
        appConfig = AppConfig(
            environment = if (isDebug) AppEnvironment.DEV else AppEnvironment.PROD,
            isDebug = isDebug,
            appVersion = appVersion,
            appBuild = appBuild,
            assistantBaseUrl = if (isDebug) assistantBaseUrl else null,
            assistantAccessToken = if (isDebug) assistantAccessToken else null,
            scannerBuild = scannerBuild,
        ),
        platformShare = platformShare,
        platformLinks = platformLinks,
        platformLanguage = platformLanguage,
        appModule = module {
            single<RetailGateway> { retailGateway }
            if (localScanEngine != null) single<LocalScanEngine> { localScanEngine }
        },
        analyticsTracker = analyticsTracker,
    )
}

actual val platformModule: Module = module {
    single { DatabaseBuilderProvider() }
    single { KeyValueStorageProvider() }
    single { SecureStorageProvider() }
    single { FileStoreProvider() }
}

fun createRootComponent(componentContext: ComponentContext): RootComponent {
    val appGraph = KoinPlatform.getKoin().get<AppGraph>()
    return appGraph.root.rootFactory.create(componentContext)
}
