package com.aiweapps.winescan.components.compare

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.router.slot.SlotNavigation
import com.arkivanov.decompose.router.slot.activate
import com.arkivanov.decompose.router.slot.childSlot
import com.arkivanov.decompose.router.slot.dismiss
import com.arkivanov.decompose.value.Value
import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.components.base.BaseStatefulComponent
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.core.error.AppError
import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.winescan.components.common.GastronomyLoader
import com.aiweapps.winescan.components.common.logCompareAdded
import com.aiweapps.winescan.components.compare.config.WineCompareModalConfig
import com.aiweapps.winescan.components.compare.model.WineCompareState
import com.aiweapps.winescan.components.compare.model.WineCompareToast
import com.aiweapps.winescan.components.compare.picker.HistoryPickerComponent
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.config.AnalyticsScreens
import com.aiweapps.winescan.domain.catalog.repository.WineCatalogRepository
import com.aiweapps.winescan.domain.compare.model.AddToCompareResult
import com.aiweapps.winescan.domain.compare.model.CompareCandidate
import com.aiweapps.winescan.domain.compare.model.CompareEntry
import com.aiweapps.winescan.domain.compare.model.CompareTable
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.gastronomy.repository.GastronomyRepository
import com.aiweapps.winescan.domain.language.repository.AppLanguageRepository
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.domain.scan.repository.ScanRepository
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

internal class DefaultWineCompareComponent(
    componentContext: ComponentContext,
    private val compareRepository: CompareSetRepository,
    private val catalog: WineCatalogRepository,
    private val historyRepository: ScanHistoryRepository,
    private val scanRepository: ScanRepository,
    gastronomyRepository: GastronomyRepository,
    appLanguage: AppLanguageRepository,
    private val platformLinks: PlatformLinks,
    private val analytics: AnalyticsTracker,
    private val pickerFactory: HistoryPickerComponent.Factory,
    private val onOpenScanner: () -> Unit,
    private val onOpenPairing: () -> Unit,
    private val onPlanDinner: (List<WineCard>, String) -> Unit,
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
) : WineCompareComponent, BaseStatefulComponent<WineCompareState>(
    componentContext = componentContext,
    initialState = WineCompareState(),
    mainContext = mainContext,
) {

    private val modalNavigation = SlotNavigation<WineCompareModalConfig>()

    override val modalSlot: Value<ChildSlot<*, WineCompareComponent.Modal>> =
        childSlot(
            source = modalNavigation,
            serializer = WineCompareModalConfig.serializer(),
            handleBackButton = true,
            childFactory = ::createModal,
        )

    private var entries: List<CompareEntry> = emptyList()
    private var catalogJob: Job? = null

    // Colour, sugar, temperature and pairings arrive after the set: their cells wait as «pending».
    private val gastronomy = GastronomyLoader(
        repository = gastronomyRepository,
        appLanguage = appLanguage,
        analytics = analytics,
        screen = AnalyticsScreens.COMPARE,
        scope = scope,
        lifecycle = lifecycle,
        onUpdate = { updateTable() },
    )

    init {
        compareRepository.watch()
            .onEach { latest ->
                entries = latest
                gastronomy.load(latest.map { it.card })
                updateTable()
                enrich(latest)
            }
            // A local database read failing is not something we can classify any further.
            .catch { updateState { copy(screenState = ScreenState.Error(AppError.Unknown)) } }
            .launchIn(scope)
        // The reference thumbnails need a session; the table does not wait for one.
        scope.launch {
            val access = scanRepository.referenceAccess()
            updateState { copy(referenceAccess = access) }
        }
    }

    override fun onRemoveClicked(slug: String) {
        scope.launch {
            try {
                compareRepository.remove(slug)
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                updateState { copy(toast = WineCompareToast.REMOVE_FAILED) }
            }
        }
    }

    override fun onPickFromHistoryClicked() {
        if (!currentState.canAddMore) return
        modalNavigation.activate(WineCompareModalConfig.HistoryPicker)
    }

    override fun onScanClicked() {
        if (!currentState.canAddMore) return
        onOpenScanner()
    }

    override fun onPairDishClicked() {
        if (!currentState.canPairDish) return
        onOpenPairing()
    }

    override fun onPlanDinnerClicked(prompt: String) {
        if (currentState.entries.isEmpty()) return
        onPlanDinner(currentState.entries.map { it.card }, prompt)
    }

    override fun onShowAllChanged(showAll: Boolean) {
        updateState { copy(showAll = showAll) }
    }

    override fun onCardLinkClicked(url: String) {
        analytics.logEvent(
            AnalyticsEvents.WINE_PAGE_OPENED,
            mapOf(AnalyticsParams.SCREEN to AnalyticsScreens.COMPARE),
        )
        platformLinks.openUrl(url)
    }

    override fun onModalDismissed() {
        modalNavigation.dismiss()
    }

    override fun onCapacityReached() {
        updateState { copy(toast = WineCompareToast.FULL) }
    }

    override fun onToastConsumed() {
        updateState { copy(toast = null) }
    }

    /** A pick from the history: the scan's best card joins the set, the sheet closes. */
    private fun addFromHistory(scanId: Long) {
        modalNavigation.dismiss()
        scope.launch {
            val record = historyRepository.byId(scanId)
            val bottle = record?.view?.bottles?.firstOrNull()
            val card = bottle?.best
            if (record == null || bottle == null || card == null) {
                updateState { copy(toast = WineCompareToast.ADD_FAILED) }
                return@launch
            }
            val candidate = CompareCandidate(
                card = card,
                photoPath = record.photoPath,
                crop = record.view.cropOf(bottle),
                frame = record.view.frame,
                scanId = record.id,
            )
            try {
                val result = compareRepository.add(candidate)
                logCompareAdded(analytics, AnalyticsScreens.COMPARE, result)
                val toast = when (result) {
                    AddToCompareResult.ADDED -> WineCompareToast.ADDED
                    AddToCompareResult.ALREADY_THERE -> WineCompareToast.ALREADY_THERE
                    AddToCompareResult.FULL -> WineCompareToast.FULL
                }
                updateState { copy(toast = toast) }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                updateState { copy(toast = WineCompareToast.ADD_FAILED) }
            }
        }
    }

    /**
     * The header's description and catalogue facts come from the source catalogue; the
     * table's gastronomy rows come from [gastronomy]. Both read the same cached catalogue.
     */
    private fun enrich(latest: List<CompareEntry>) {
        catalogJob?.cancel()
        catalogJob = scope.launch {
            val enriched = latest.map { it.copy(card = catalog.enrich(it.card)) }
            // A newer set replaced this one meanwhile: its own enrichment follows.
            if (entries.map { it.slug } != latest.map { it.slug }) return@launch
            entries = enriched
            updateTable()
        }
    }

    /** The only place that rewrites the entries: the rows always follow. */
    private fun updateTable() {
        val snapshot = gastronomy.snapshot
        val current = entries
        val rows = CompareTable.build(current, snapshot.loaded, snapshot.dishes, snapshot.language)
        updateState {
            copy(
                screenState = ScreenState.Content,
                entries = current,
                allRows = rows,
                differentRows = rows.filter { it.isDifferent },
                sameRows = rows.filterNot { it.isDifferent },
            )
        }
    }

    private fun createModal(config: WineCompareModalConfig, context: ComponentContext): WineCompareComponent.Modal =
        when (config) {
            WineCompareModalConfig.HistoryPicker -> WineCompareComponent.Modal.HistoryPicker(
                pickerFactory.create(
                    componentContext = context,
                    onPick = ::addFromHistory,
                    onClose = { modalNavigation.dismiss() },
                )
            )
        }
}
