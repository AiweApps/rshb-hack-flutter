package com.aiweapps.winescan.di.dependencies

import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.platform.PlatformLanguage
import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.core.share.PlatformShare
import com.aiweapps.winescan.config.AppConfig
import com.aiweapps.winescan.domain.assistant.repository.AssistantAccountRepository
import com.aiweapps.winescan.domain.assistant.repository.AssistantService
import com.aiweapps.winescan.domain.assistant.repository.AssistantLocalRepository
import com.aiweapps.winescan.domain.assistant.repository.RetailGateway
import com.aiweapps.winescan.domain.catalog.repository.WineCatalogRepository
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.gastronomy.repository.GastronomyRepository
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.language.repository.AppLanguageRepository
import com.aiweapps.winescan.domain.pairing.repository.SavedPairingRepository
import com.aiweapps.winescan.domain.preferences.repository.AppPreferencesRepository
import com.aiweapps.winescan.domain.scan.repository.ScanRepository
import com.aiweapps.winescan.domain.scan.repository.ScannerBackendControls
import com.aiweapps.winescan.domain.status.ServiceStatusMonitor
import com.aiweapps.winescan.domain.theme.repository.ThemeRepository
import kotlinx.serialization.json.Json

class AppDependencies(
    val scan: ScanDependencies,
    val history: HistoryDependencies,
    val compare: CompareDependencies,
    val settings: SettingsDependencies,
    val gastronomy: GastronomyDependencies,
    val preferences: AppPreferencesRepository,
    val assistantAccount: AssistantAccountRepository,
    val assistantService: AssistantService,
    val assistantLocalRepository: AssistantLocalRepository,
    val retailGateway: RetailGateway,
    /** Screens are logged where the navigation is, in the root and the tabs. */
    val analytics: AnalyticsTracker,
)

/** What the scan tab and the result screen use. */
class ScanDependencies(
    val scanRepository: ScanRepository,
    /** The shared status poll the scanner tab listens to while on screen. */
    val statusMonitor: ServiceStatusMonitor,
    val historyRepository: ScanHistoryRepository,
    val compareRepository: CompareSetRepository,
    val platformShare: PlatformShare,
    val platformLinks: PlatformLinks,
    /** Serialises the answer for «Share JSON»; the same instance the repositories parse with. */
    val json: Json,
    val appConfig: AppConfig,
    val catalog: WineCatalogRepository,
    val analytics: AnalyticsTracker,
)

class HistoryDependencies(
    val historyRepository: ScanHistoryRepository,
    val savedPairingRepository: SavedPairingRepository,
    /** A row adds its wine to the comparison and shows whether it is there. */
    val compareRepository: CompareSetRepository,
    /** «My wines», shared with the assistant: a row's heart. */
    val favorites: AssistantLocalRepository,
    /** The saved dishes are named in the app's language. */
    val appLanguage: AppLanguageRepository,
)

/** Colour, sugar, temperature and pairings, for every screen that shows a wine's card. */
class GastronomyDependencies(
    val repository: GastronomyRepository,
    val appLanguage: AppLanguageRepository,
)

/** What the comparison table and the dish screen use. */
class CompareDependencies(
    val compareRepository: CompareSetRepository,
    val savedPairingRepository: SavedPairingRepository,
    /** The picker over the stored scans. */
    val historyRepository: ScanHistoryRepository,
    /** For the reference thumbnails next to the user's photos. */
    val scanRepository: ScanRepository,
    val platformLinks: PlatformLinks,
    val catalog: WineCatalogRepository,
    val analytics: AnalyticsTracker,
)

class SettingsDependencies(
    val appConfig: AppConfig,
    val statusMonitor: ServiceStatusMonitor,
    val historyRepository: ScanHistoryRepository,
    val preferences: AppPreferencesRepository,
    val themeRepository: ThemeRepository,
    val platformLanguage: PlatformLanguage,
    val platformLinks: PlatformLinks,
    val backendControls: ScannerBackendControls,
)
