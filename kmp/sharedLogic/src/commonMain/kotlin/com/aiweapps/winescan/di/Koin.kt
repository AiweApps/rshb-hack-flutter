package com.aiweapps.winescan.di

import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.database.DatabaseBuilderProvider
import com.aiweapps.core.database.applyDefaults
import com.aiweapps.core.database.databaseBuilder
import com.aiweapps.core.files.FileStore
import com.aiweapps.core.files.FileStoreProvider
import com.aiweapps.core.network.NetworkClient
import com.aiweapps.core.network.NetworkConfig
import com.aiweapps.core.network.auth.AuthProvider
import com.aiweapps.core.platform.PlatformLanguage
import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.core.share.PlatformShare
import com.aiweapps.core.storage.KeyValueStorage
import com.aiweapps.core.storage.KeyValueStorageProvider
import com.aiweapps.core.storage.SecureStorage
import com.aiweapps.core.storage.SecureStorageProvider
import com.aiweapps.winescan.config.AppConfig
import com.aiweapps.winescan.data.database.AppDatabase
import com.aiweapps.winescan.data.assistant.local.AssistantLocalDao
import com.aiweapps.winescan.data.assistant.local.AssistantLocalRepositoryImpl
import com.aiweapps.winescan.data.assistant.repository.UnavailableAssistantService
import com.aiweapps.winescan.data.assistant.repository.AssistantServiceImpl
import com.aiweapps.winescan.data.assistant.remote.AssistantApi
import com.aiweapps.winescan.data.assistant.remote.AssistantAccountApi
import com.aiweapps.winescan.data.assistant.repository.AssistantAccountRepositoryImpl
import com.aiweapps.winescan.domain.assistant.repository.AssistantAccountRepository
import com.aiweapps.winescan.data.catalog.remote.WineCatalogApi
import com.aiweapps.winescan.data.catalog.repository.WineCatalogRepositoryImpl
import com.aiweapps.winescan.data.compare.dao.CompareEntryDao
import com.aiweapps.winescan.data.compare.repository.CompareSetRepositoryImpl
import com.aiweapps.winescan.data.database.AppDatabaseMigrations
import com.aiweapps.winescan.data.gastronomy.GastronomyDataSource
import com.aiweapps.winescan.data.gastronomy.remote.CatalogGastronomyDataSource
import com.aiweapps.winescan.data.gastronomy.repository.GastronomyRepositoryImpl
import com.aiweapps.winescan.data.history.dao.ScanHistoryDao
import com.aiweapps.winescan.data.history.repository.ScanHistoryRepositoryImpl
import com.aiweapps.winescan.data.language.AppLanguageRepositoryImpl
import com.aiweapps.winescan.data.pairing.dao.SavedPairingDao
import com.aiweapps.winescan.data.pairing.repository.SavedPairingRepositoryImpl
import com.aiweapps.winescan.data.preferences.AppPreferencesRepositoryImpl
import com.aiweapps.winescan.data.scan.remote.GuestTokenApi
import com.aiweapps.winescan.data.scan.remote.ScanApi
import com.aiweapps.winescan.data.scan.repository.ScanRepositoryImpl
import com.aiweapps.winescan.data.session.GuestSessionImpl
import com.aiweapps.winescan.data.status.ServiceStatusMonitorImpl
import com.aiweapps.winescan.data.storage.StorageKeys
import com.aiweapps.winescan.data.theme.ThemeRepositoryImpl
import com.aiweapps.winescan.di.dependencies.AppDependencies
import com.aiweapps.winescan.di.dependencies.CompareDependencies
import com.aiweapps.winescan.di.dependencies.GastronomyDependencies
import com.aiweapps.winescan.di.dependencies.HistoryDependencies
import com.aiweapps.winescan.di.dependencies.ScanDependencies
import com.aiweapps.winescan.di.dependencies.SettingsDependencies
import com.aiweapps.winescan.domain.catalog.repository.WineCatalogRepository
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.assistant.repository.AssistantService
import com.aiweapps.winescan.domain.assistant.repository.AssistantLocalRepository
import com.aiweapps.winescan.domain.assistant.repository.RetailGateway
import com.aiweapps.winescan.domain.gastronomy.repository.GastronomyRepository
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.language.repository.AppLanguageRepository
import com.aiweapps.winescan.domain.pairing.repository.SavedPairingRepository
import com.aiweapps.winescan.domain.preferences.repository.AppPreferencesRepository
import com.aiweapps.winescan.domain.scan.repository.ScanRepository
import com.aiweapps.winescan.domain.scan.repository.LocalScanEngine
import com.aiweapps.winescan.domain.scan.repository.ScannerBackendControls
import com.aiweapps.winescan.data.scan.repository.ConfiguredScanRepository
import com.aiweapps.winescan.data.catalog.repository.ConfiguredWineCatalogRepository
import com.aiweapps.winescan.domain.session.GuestSession
import com.aiweapps.winescan.domain.status.ServiceStatusMonitor
import com.aiweapps.winescan.domain.theme.repository.ThemeRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.serialization.json.Json
import org.koin.core.KoinApplication
import org.koin.core.context.startKoin
import org.koin.core.module.Module
import org.koin.dsl.KoinAppDeclaration
import org.koin.dsl.module

/**
 * [appConfig] comes from the platform rather than from a constant in here: only the
 * platform knows whether this is a debug build and which environment it was built for.
 *
 * [platformShare], [platformLinks], [platformLanguage] and [analyticsTracker] follow the same principle one
 * level up — the platform hands in not a value but an implementation. They are required
 * parameters on purpose: registering such services in [platformModule] instead would move
 * the failure for a forgotten one from compile time to the first tap on a button.
 */
fun initKoin(
    appConfig: AppConfig,
    platformShare: PlatformShare,
    platformLinks: PlatformLinks,
    platformLanguage: PlatformLanguage,
    analyticsTracker: AnalyticsTracker,
    appDeclaration: KoinAppDeclaration? = null,
    appModule: Module? = null,
): KoinApplication {
    return startKoin {
        appDeclaration?.invoke(this)
        modules(
            listOfNotNull(
                appModule,
                configModule(appConfig),
                platformServicesModule(platformShare, platformLinks, platformLanguage, analyticsTracker),
                storageModule,
                databaseModule,
                networkModule,
                mainModule,
                platformModule,
            )
        )
    }
}

/**
 * Providers this module builds for itself per target, through `expect`/`actual`. Anything
 * that needs a dependency living in the application — an Activity, a presenting view
 * controller, a platform SDK — cannot be built here and arrives through
 * [platformServicesModule] instead.
 */
expect val platformModule: Module

fun configModule(appConfig: AppConfig): Module = module {
    single { appConfig }
}

/** Implementations of shared interfaces that only the application can build. */
fun platformServicesModule(
    platformShare: PlatformShare,
    platformLinks: PlatformLinks,
    platformLanguage: PlatformLanguage,
    analyticsTracker: AnalyticsTracker,
): Module = module {
    single { platformShare }
    single { platformLinks }
    single { platformLanguage }
    single { analyticsTracker }
}

val storageModule = module {
    single<KeyValueStorage> {
        get<KeyValueStorageProvider>().create(StorageKeys.APP_PREFERENCES)
    }
    single<SecureStorage> {
        get<SecureStorageProvider>().create(StorageKeys.SECURE_PREFERENCES)
    }
    single<FileStore>(FileStores.Scans) {
        get<FileStoreProvider>().create(StorageKeys.SCAN_PHOTOS_DIRECTORY)
    }
    single<FileStore>(FileStores.Compare) {
        get<FileStoreProvider>().create(StorageKeys.COMPARE_PHOTOS_DIRECTORY)
    }
    single<FileStore>(FileStores.Assistant) {
        get<FileStoreProvider>().create(StorageKeys.ASSISTANT_PHOTOS_DIRECTORY)
    }
    // Lenient so a newer backend cannot break parsing, and the stored answer re-reads
    // even when a field it never had is added later.
    single<Json> {
        Json {
            ignoreUnknownKeys = true
            isLenient = true
            encodeDefaults = true
            explicitNulls = false
        }
    }
}

val databaseModule = module {
    single<AppDatabase> {
        get<DatabaseBuilderProvider>()
            .databaseBuilder<AppDatabase>(StorageKeys.DATABASE_NAME)
            .applyDefaults(migrations = AppDatabaseMigrations.ALL)
    }
    single<ScanHistoryDao> { get<AppDatabase>().scanHistoryDao() }
    single<CompareEntryDao> { get<AppDatabase>().compareEntryDao() }
    single<SavedPairingDao> { get<AppDatabase>().savedPairingDao() }
    single<AssistantLocalDao> { get<AppDatabase>().assistantLocalDao() }
}

/**
 * Network wiring. The dependency chain is deliberately one-directional and therefore
 * acyclic:
 *
 *   authorized client -> AuthProvider (GuestSessionImpl) -> GuestTokenApi -> plain client
 *
 * The plain client is built without an [AuthProvider], so nothing points back at the
 * authorized client and Koin can resolve the whole graph.
 *
 * Body logging stays off for the plain client in every build — its only traffic is the
 * token itself. The authorized client logs in debug builds only; its bodies carry the
 * Bearer in the headers, which release builds must not print.
 */
val networkModule = module {

    single(HttpClients.Assistant) {
        val config = get<AppConfig>()
        val url = config.assistantBaseUrl ?: "https://wines.aiweapps.com/assistant/"
        NetworkClient.create(
            NetworkConfig(
                baseUrl = url,
                connectTimeoutMs = 5_000,
                requestTimeoutMs = 160_000,
                socketTimeoutMs = 160_000,
                enableLogging = false,
            )
        )
    }

    single(HttpClients.PlainAuth) {
        NetworkClient.create(
            NetworkConfig(
                baseUrl = get<AppConfig>().environment.apiBaseUrl,
                enableLogging = false,
            )
        )
    }

    single(HttpClients.Authorized) {
        val config = get<AppConfig>()
        NetworkClient.create(
            NetworkConfig(
                baseUrl = config.environment.apiBaseUrl,
                enableLogging = config.enableNetworkLogging,
                authProvider = get<AuthProvider>(),
            )
        )
    }

    single { AssistantAccountApi(
        NetworkClient.create(NetworkConfig(baseUrl = "https://wines.aiweapps.com/", enableLogging = false)),
        get(HttpClients.Assistant),
    ) }
    single<AssistantAccountRepository> { AssistantAccountRepositoryImpl(get(), get(), get()) }

    single { GuestTokenApi(get(HttpClients.PlainAuth)) }
    single { ScanApi(get(HttpClients.Authorized), get()) }
    // Gastronomy reads the same source catalogue as the assistant and the comparison.
    single<GastronomyDataSource> { CatalogGastronomyDataSource(catalog = get()) }

    // One object, two contracts: the transport sees an AuthProvider, the app a GuestSession.
    single { GuestSessionImpl(tokenApi = get(), secureStorage = get()) }
    single<AuthProvider> { get<GuestSessionImpl>() }
    single<GuestSession> { get<GuestSessionImpl>() }
}

val mainModule = module {

    single {
        ConfiguredScanRepository(
            remote = ScanRepositoryImpl(
            api = get(),
            fileStore = get(FileStores.Scans),
            session = get(),
            apiBaseUrl = get<AppConfig>().environment.apiBaseUrl,
            json = get(),
            ),
            local = getOrNull<LocalScanEngine>(),
            config = get(),
            storage = get(),
            json = get(),
        )
    }
    single<ScanRepository> { get<ConfiguredScanRepository>() }
    single<ScannerBackendControls> { get<ConfiguredScanRepository>() }
    single<ScanHistoryRepository> {
        ScanHistoryRepositoryImpl(dao = get(), photos = get(FileStores.Scans), json = get())
    }
    single<CompareSetRepository> {
        CompareSetRepositoryImpl(dao = get(), photos = get(FileStores.Compare), json = get())
    }
    single<SavedPairingRepository> { SavedPairingRepositoryImpl(dao = get(), json = get()) }
    // Lives as long as the app: the status poll it runs stops by itself with its last listener.
    single<ServiceStatusMonitor> {
        ServiceStatusMonitorImpl(scanRepository = get(), scope = CoroutineScope(SupervisorJob() + Dispatchers.Default), backendControls = get())
    }
    single<AppPreferencesRepository> { AppPreferencesRepositoryImpl(get()) }
    single<ThemeRepository> { ThemeRepositoryImpl(get()) }
    single<AssistantLocalRepository> {
        AssistantLocalRepositoryImpl(
            dao = get(), photos = get(FileStores.Assistant), json = get(), accounts = get(), preferences = get(),
            history = get(),
        )
    }
    single<WineCatalogRepository> {
        ConfiguredWineCatalogRepository(
            remote = WineCatalogRepositoryImpl(WineCatalogApi(get(HttpClients.Assistant), get())),
            local = getOrNull<LocalScanEngine>(), controls = get(), json = get(),
        )
    }
    single<AssistantService> {
        AssistantServiceImpl(AssistantApi(get(HttpClients.Assistant), get()))
    }
    single<GastronomyRepository> { GastronomyRepositoryImpl(get()) }
    single<AppLanguageRepository> { AppLanguageRepositoryImpl(get()) }

    single { ScanDependencies(get(), get(), get(), get(), get(), get(), get(), get(), get(), get()) }
    single { HistoryDependencies(get(), get(), get(), get(), get()) }
    single { GastronomyDependencies(get(), get()) }
    single { CompareDependencies(get(), get(), get(), get(), get(), get(), get()) }
    single { SettingsDependencies(get(), get(), get(), get(), get(), get(), get(), get()) }
    single { AppDependencies(get(), get(), get(), get(), get(), get(), get(), get(), get(), get(), get()) }

    single { AppGraph(get()) }
}
