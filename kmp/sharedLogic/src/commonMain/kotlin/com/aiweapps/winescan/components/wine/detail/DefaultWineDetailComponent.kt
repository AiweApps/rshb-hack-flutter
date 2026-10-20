package com.aiweapps.winescan.components.wine.detail

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.router.slot.SlotNavigation
import com.arkivanov.decompose.router.slot.activate
import com.arkivanov.decompose.router.slot.childSlot
import com.arkivanov.decompose.router.slot.dismiss
import com.arkivanov.decompose.value.Value
import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.components.base.BaseStatefulComponent
import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.winescan.components.common.GastronomyLoader
import com.aiweapps.winescan.components.common.GastronomySnapshot
import com.aiweapps.winescan.components.common.logCompareAdded
import com.aiweapps.winescan.components.scan.result.sheets.CompareComponent
import com.aiweapps.winescan.components.wine.detail.config.WineDetailModalConfig
import com.aiweapps.winescan.components.wine.detail.model.WineDetailState
import com.aiweapps.winescan.components.wine.detail.model.WineDetailToast
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.config.AnalyticsScreens
import com.aiweapps.winescan.domain.compare.model.AddToCompareResult
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.catalog.repository.WineCatalogRepository
import com.aiweapps.winescan.domain.gastronomy.repository.GastronomyRepository
import com.aiweapps.winescan.domain.language.repository.AppLanguageRepository
import com.aiweapps.winescan.domain.scan.model.WineDetailTarget
import com.aiweapps.winescan.domain.scan.repository.ScanRepository
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

internal class DefaultWineDetailComponent(
    componentContext: ComponentContext,
    private val target: WineDetailTarget,
    private val scanRepository: ScanRepository,
    private val compareRepository: CompareSetRepository,
    gastronomyRepository: GastronomyRepository,
    appLanguage: AppLanguageRepository,
    private val platformLinks: PlatformLinks,
    private val analytics: AnalyticsTracker,
    private val compareFactory: CompareComponent.Factory,
    private val onClose: () -> Unit,
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
    /** Older snapshot-only callers can omit enrichment; the production graph supplies the source. */
    private val catalog: WineCatalogRepository? = null,
) : WineDetailComponent, BaseStatefulComponent<WineDetailState>(
    componentContext = componentContext,
    initialState = WineDetailState(card = target.card, bottle = target.bottle),
    mainContext = mainContext,
) {

    private val modalNavigation = SlotNavigation<WineDetailModalConfig>()

    override val modalSlot: Value<ChildSlot<*, WineDetailComponent.Modal>> =
        childSlot(
            source = modalNavigation,
            serializer = WineDetailModalConfig.serializer(),
            handleBackButton = true,
            childFactory = ::createModal,
        )

    private var enrichmentJob: Job? = null

    private val gastronomy = GastronomyLoader(
        repository = gastronomyRepository,
        appLanguage = appLanguage,
        analytics = analytics,
        screen = AnalyticsScreens.WINE_DETAIL,
        scope = scope,
        lifecycle = lifecycle,
        onUpdate = ::updateFacts,
    )

    init {
        gastronomy.load(listOf(target.card))
        scope.launch {
            val access = scanRepository.referenceAccess()
            updateState { copy(referenceAccess = access) }
        }
        compareRepository.watch()
            .onEach { entries ->
                updateState {
                    copy(isInCompare = entries.any { it.slug == target.card.slug }, compareCount = entries.size)
                }
            }
            // The compare buttons are a convenience; a database read failing must not take the card down.
            .catch { }
            .launchIn(scope)
    }

    override fun onBackClicked() {
        onClose()
    }

    override fun onFactsRetryClicked() {
        gastronomy.retryFailed()
    }

    private fun updateFacts(snapshot: GastronomySnapshot) {
        val slug = target.card.slug
        updateState { copy(
            facts = snapshot.facts[slug],
            isFactsLoading = slug in snapshot.pendingSlugs,
            factsError = snapshot.errorsBySlug[slug],
        ) }
        // A successful gastronomy response has already filled the same catalogue cache.
        // Enrich once from it, rather than racing two HTTP reads for the detail screen.
        val catalogue = catalog ?: return
        if (slug in snapshot.bySlug && enrichmentJob == null) {
            enrichmentJob = scope.launch {
                val enriched = catalogue.enrich(target.card)
                ensureActive()
                updateState { copy(card = enriched) }
            }
        }
    }

    override fun onCatalogueLinkClicked(url: String) {
        analytics.logEvent(
            AnalyticsEvents.WINE_PAGE_OPENED,
            mapOf(AnalyticsParams.SCREEN to AnalyticsScreens.WINE_DETAIL),
        )
        platformLinks.openUrl(url)
    }

    override fun onCompareWithPhotoClicked() {
        val bottle = target.bottle ?: return
        modalNavigation.activate(WineDetailModalConfig.Compare(bottle))
    }

    override fun onAddToCompareClicked() {
        val bottle = target.bottle ?: return
        val card = currentState.card
        scope.launch {
            val toast = try {
                val result = compareRepository.add(bottle.toCompareCandidate(card))
                logCompareAdded(analytics, AnalyticsScreens.WINE_DETAIL, result)
                when (result) {
                    AddToCompareResult.ADDED -> WineDetailToast.AddedToCompare
                    AddToCompareResult.ALREADY_THERE -> WineDetailToast.AlreadyInCompare
                    AddToCompareResult.FULL -> WineDetailToast.CompareFull
                }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                WineDetailToast.AddToCompareFailed
            }
            updateState { copy(toast = toast) }
        }
    }

    override fun onRemoveFromCompareClicked() {
        scope.launch {
            val toast = try {
                compareRepository.remove(target.card.slug)
                WineDetailToast.RemovedFromCompare
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                WineDetailToast.RemoveFromCompareFailed
            }
            updateState { copy(toast = toast) }
        }
    }

    override fun onModalDismissed() {
        modalNavigation.dismiss()
    }

    override fun onToastConsumed() {
        updateState { copy(toast = null) }
    }

    private fun createModal(config: WineDetailModalConfig, context: ComponentContext): WineDetailComponent.Modal =
        when (config) {
            is WineDetailModalConfig.Compare -> WineDetailComponent.Modal.Compare(
                compareFactory.create(
                    componentContext = context,
                    photoPath = config.bottle.photoPath,
                    crop = config.bottle.crop,
                    frame = config.bottle.frame,
                    bottleNumber = config.bottle.bottleNumber,
                    cardTitle = currentState.card.title,
                    reference = currentState.card.reference,
                    referenceAccess = currentState.referenceAccess,
                    onClose = { modalNavigation.dismiss() },
                )
            )
        }
}
