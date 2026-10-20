package com.aiweapps.winescan

import com.aiweapps.winescan.local.AndroidLocalScanEngine
import com.aiweapps.winescan.domain.scan.repository.LocalScanEngine
import android.app.Application
import coil3.ImageLoader
import coil3.SingletonImageLoader
import coil3.network.ktor3.KtorNetworkFetcherFactory
import coil3.request.crossfade
import com.aiweapps.winescan.config.AppConfig
import com.aiweapps.winescan.config.AppEnvironment
import com.aiweapps.winescan.di.HttpClients
import com.aiweapps.winescan.di.initKoin
import com.aiweapps.winescan.platform.AndroidAnalytics
import com.aiweapps.winescan.platform.AndroidLanguage
import com.aiweapps.winescan.platform.AndroidLinks
import com.aiweapps.winescan.platform.AndroidShare
import com.aiweapps.winescan.platform.PhotoPreparer
import com.aiweapps.winescan.retail.AndroidRetailGateway
import com.aiweapps.winescan.domain.assistant.repository.RetailGateway
import io.ktor.client.HttpClient
import org.koin.android.ext.koin.androidContext
import org.koin.core.qualifier.named
import org.koin.dsl.module

class WineScanApp : Application() {
    // Retail thumbnails are public CDN assets. Keep them on a client without the
    // scanner auth plugin, including when a CDN returns an authentication challenge.
    lateinit var publicImageLoader: ImageLoader
        private set

    override fun onCreate() {
        super.onCreate()

        val koin = initKoin(
            appConfig = AppConfig(
                environment = if (BuildConfig.DEBUG) AppEnvironment.DEV else AppEnvironment.PROD,
                isDebug = BuildConfig.DEBUG,
                appVersion = BuildConfig.VERSION_NAME,
                appBuild = BuildConfig.VERSION_CODE.toString(),
                assistantBaseUrl = BuildConfig.ASSISTANT_BASE_URL.takeIf { BuildConfig.DEBUG && it.isNotBlank() } ?: "https://wines.aiweapps.com/assistant/",
                assistantAccessToken = null,
            ),
            platformShare = AndroidShare(this),
            platformLinks = AndroidLinks(this),
            platformLanguage = AndroidLanguage(),
            analyticsTracker = AndroidAnalytics(this),
            appDeclaration = { androidContext(this@WineScanApp) },
            // Android-only helpers the screens need; they live in the same container so a
            // Composable can take them from Koin instead of building them in place.
            appModule = module {
                single<LocalScanEngine> { AndroidLocalScanEngine(this@WineScanApp) }
                single { PhotoPreparer(get()) }
                single { AndroidRetailGateway() }
                single<RetailGateway> { get<AndroidRetailGateway>() }
            },
        ).koin

        val publicClient = koin.get<HttpClient>(HttpClients.PlainAuth)
        publicImageLoader = ImageLoader.Builder(this)
            .components { add(KtorNetworkFetcherFactory(publicClient)) }
            .crossfade(true)
            .build()

        // Reference thumbnails sit behind the same guest Bearer as the API: loading them
        // through the authorized Ktor client gives Coil the header and the refresh for free.
        val authorizedClient = koin.get<HttpClient>(named(HttpClients.Authorized.value))
        SingletonImageLoader.setSafe {
            ImageLoader.Builder(this)
                .components { add(KtorNetworkFetcherFactory(authorizedClient)) }
                .crossfade(true)
                .build()
        }
    }
}
