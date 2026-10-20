package com.aiweapps.winescan.components.history

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.router.slot.SlotNavigation
import com.arkivanov.decompose.router.slot.activate
import com.arkivanov.decompose.router.slot.childSlot
import com.arkivanov.decompose.router.slot.dismiss
import com.arkivanov.decompose.value.Value
import com.arkivanov.essenty.lifecycle.doOnResume
import com.aiweapps.core.components.base.BaseStatefulComponent
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.core.error.AppError
import com.aiweapps.winescan.components.common.ConfirmClearHistoryComponent
import com.aiweapps.winescan.components.history.config.HistoryModalConfig
import com.aiweapps.winescan.components.history.model.HistoryState
import com.aiweapps.winescan.components.history.model.HistoryToast
import com.aiweapps.winescan.domain.assistant.model.AssistantWine
import com.aiweapps.winescan.domain.assistant.repository.AssistantLocalRepository
import com.aiweapps.winescan.domain.compare.model.AddToCompareResult
import com.aiweapps.winescan.domain.compare.model.CompareCandidate
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.history.model.HistoryDaySection
import com.aiweapps.winescan.domain.history.model.ScanRecord
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.language.repository.AppLanguageRepository
import com.aiweapps.winescan.domain.pairing.model.PairingSource
import com.aiweapps.winescan.domain.pairing.repository.SavedPairingRepository
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.RecognizedBottle
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import kotlinx.datetime.TimeZone

internal class DefaultHistoryComponent(
    componentContext: ComponentContext,
    private val repository: ScanHistoryRepository,
    private val savedPairingRepository: SavedPairingRepository,
    private val compareRepository: CompareSetRepository,
    private val favorites: AssistantLocalRepository,
    private val appLanguage: AppLanguageRepository,
    private val confirmClearFactory: ConfirmClearHistoryComponent.Factory,
    private val onOpenScan: (scanId: Long) -> Unit,
    private val onOpenScanner: () -> Unit,
    private val onOpenPairing: (PairingSource) -> Unit,
    private val timeZone: TimeZone = TimeZone.currentSystemDefault(),
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
) : HistoryComponent, BaseStatefulComponent<HistoryState>(
    componentContext = componentContext,
    initialState = HistoryState(),
    mainContext = mainContext,
) {

    private val modalNavigation = SlotNavigation<HistoryModalConfig>()

    override val modalSlot: Value<ChildSlot<*, HistoryComponent.Modal>> =
        childSlot(
            source = modalNavigation,
            serializer = HistoryModalConfig.serializer(),
            handleBackButton = true,
            childFactory = ::createModal,
        )

    private var observeJob: Job? = null

    /** Rows whose compare or heart tap is still being written: a second tap waits for it. */
    private val busyScanIds = mutableSetOf<Long>()
    private var favoriteSubject: String? = null

    init {
        observeHistory()
        // Conveniences next to the list: a failing read leaves the list alone.
        compareRepository.watch()
            .onEach { entries -> updateState { copy(compareSlugs = entries.mapTo(mutableSetOf()) { it.slug }) } }
            .catch { }
            .launchIn(scope)
        favorites.watchSavedWinesByOwner()
            .onEach { snapshot ->
                if (snapshot.subject == favorites.savedWinesSubject) {
                    favoriteSubject = snapshot.subject
                    updateState { copy(favoriteSlugs = snapshot.wines.mapTo(mutableSetOf()) { it.slug }) }
                }
            }
            .catch { }
            .launchIn(scope)
        savedPairingRepository.watchAll()
            .onEach { saved -> updateState { copy(savedPairings = saved) } }
            .catch { }
            .launchIn(scope)
        // The saved dishes are named in the app's language, which may have changed while away.
        lifecycle.doOnResume { appLanguage.refresh() }
        appLanguage.language
            .onEach { language -> updateState { copy(languageCode = language) } }
            .launchIn(scope)
    }

    override fun onRetry() {
        observeHistory()
    }

    override fun onScanClicked(scanId: Long) {
        onOpenScan(scanId)
    }

    override fun onScanDismissed(scanId: Long) {
        // Hide the row at once: the swipe has already animated it away.
        updateHistory { copy(items = items.filterNot { it.id == scanId }, pendingDeleteIds = pendingDeleteIds + scanId) }
        scope.launch {
            try {
                repository.delete(scanId)
                updateState { copy(toast = HistoryToast.DELETED) }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                // The stream brings the row back once it is no longer pending.
                updateState { copy(pendingDeleteIds = pendingDeleteIds - scanId, toast = HistoryToast.DELETE_FAILED) }
            }
        }
    }

    override fun onScanNowClicked() {
        onOpenScanner()
    }

    override fun onClearClicked() {
        if (!currentState.canClear) return
        modalNavigation.activate(HistoryModalConfig.ConfirmClear)
    }

    override fun onCompareClicked(scanId: Long) {
        val item = currentState.items.firstOrNull { it.id == scanId } ?: return
        val slug = item.bestSlug ?: return
        if (!busyScanIds.add(scanId)) return
        val removing = currentState.isInCompare(item)
        scope.launch {
            val toast = try {
                if (removing) {
                    compareRepository.remove(slug)
                    HistoryToast.REMOVED_FROM_COMPARE
                } else {
                    val candidate = bestOf(scanId)?.let { (record, bottle, card) ->
                        CompareCandidate(
                            card = card,
                            photoPath = record.photoPath,
                            crop = record.view.cropOf(bottle),
                            frame = record.view.frame,
                            scanId = record.id,
                        )
                    }
                    if (candidate == null) {
                        HistoryToast.ADD_TO_COMPARE_FAILED
                    } else {
                        when (compareRepository.add(candidate)) {
                            AddToCompareResult.ADDED -> HistoryToast.ADDED_TO_COMPARE
                            AddToCompareResult.ALREADY_THERE -> HistoryToast.ALREADY_IN_COMPARE
                            AddToCompareResult.FULL -> HistoryToast.COMPARE_FULL
                        }
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                if (removing) HistoryToast.REMOVE_FROM_COMPARE_FAILED else HistoryToast.ADD_TO_COMPARE_FAILED
            } finally {
                busyScanIds.remove(scanId)
            }
            updateState { copy(toast = toast) }
        }
    }

    override fun onFavoriteClicked(scanId: Long) {
        val subject = favorites.savedWinesSubject
        // A tap on the preceding account's hearts must not modify the newly selected one.
        if (favoriteSubject != subject) return
        val item = currentState.items.firstOrNull { it.id == scanId } ?: return
        val slug = item.bestSlug ?: return
        if (!busyScanIds.add(scanId)) return
        val removing = currentState.isFavorite(item)
        scope.launch {
            val toast = try {
                if (removing) {
                    // The heart is the wine's, so every saved copy of it goes, wherever it was saved.
                    favorites.updateSavedWines(subject) { stored -> stored.filterNot { it.slug == slug } }
                    HistoryToast.REMOVED_FROM_FAVORITES
                } else {
                    val wine = bestOf(scanId)?.let { (record, bottle, card) ->
                        card.toSavedWine(scanId = record.id, crop = record.view.cropOf(bottle), frame = record.view.frame)
                    }
                    if (wine == null) {
                        HistoryToast.FAVORITES_FAILED
                    } else {
                        favorites.updateSavedWines(subject) { stored ->
                            if (stored.any { it.slug == slug }) stored else stored + wine
                        }
                        HistoryToast.ADDED_TO_FAVORITES
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                HistoryToast.FAVORITES_FAILED
            } finally {
                busyScanIds.remove(scanId)
            }
            if (favorites.savedWinesSubject == subject && favoriteSubject == subject) {
                updateState { copy(toast = toast) }
            }
        }
    }

    /** The stored scan, its first bottle and that bottle's best card: what the row shows. */
    private suspend fun bestOf(scanId: Long): Triple<ScanRecord, RecognizedBottle, WineCard>? {
        val record = repository.byId(scanId) ?: return null
        val bottle = record.view.bottles.firstOrNull() ?: return null
        val card = bottle.best ?: return null
        return Triple(record, bottle, card)
    }

    private fun WineCard.toSavedWine(scanId: Long, crop: BottleBox?, frame: List<Int>?) = AssistantWine(
        slug = slug,
        title = presentationTitle,
        producer = producer,
        region = region,
        category = category,
        foodPairings = pairings.orEmpty(),
        reference = reference,
        pageUrl = catalogueUrl,
        photoId = null,
        photoPath = null,
        instanceId = null,
        uncertain = false,
        description = description,
        dishes = dishes,
        sourceCrop = crop,
        sourceFrame = frame,
        sourceScanId = scanId,
    )

    override fun onSavedPairingClicked(pairingId: Long) {
        onOpenPairing(PairingSource.Saved(pairingId))
    }

    override fun onSavedPairingDismissed(pairingId: Long) {
        scope.launch {
            try {
                savedPairingRepository.delete(pairingId)
                updateState { copy(toast = HistoryToast.PAIRING_DELETED) }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                updateState { copy(toast = HistoryToast.PAIRING_DELETE_FAILED) }
            }
        }
    }

    override fun onModalDismissed() {
        modalNavigation.dismiss()
    }

    override fun onToastConsumed() {
        updateState { copy(toast = null) }
    }

    private fun observeHistory() {
        observeJob?.cancel()
        updateState { copy(screenState = ScreenState.Loading) }
        observeJob = repository.watchAll()
            .onEach { items ->
                // A pending id that the database no longer has is done; the rest stay hidden
                // until their delete lands.
                updateHistory {
                    val pending = pendingDeleteIds.intersect(items.map { it.id }.toSet())
                    copy(
                        screenState = ScreenState.Content,
                        items = items.filterNot { it.id in pending },
                        pendingDeleteIds = pending,
                    )
                }
            }
            // A local database read failing is not something we can classify any further.
            .catch { updateState { copy(screenState = ScreenState.Error(AppError.Unknown)) } }
            .launchIn(scope)
    }

    private fun clearHistory() {
        scope.launch {
            try {
                repository.clear()
                updateState { copy(toast = HistoryToast.CLEARED) }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                updateState { copy(toast = HistoryToast.CLEAR_FAILED) }
            }
        }
    }

    /** The only place that rewrites [HistoryState.items]: the sections always follow. */
    private fun updateHistory(block: HistoryState.() -> HistoryState) {
        updateState {
            val next = block()
            next.copy(sections = HistoryDaySection.group(next.items, timeZone))
        }
    }

    private fun createModal(config: HistoryModalConfig, context: ComponentContext): HistoryComponent.Modal =
        when (config) {
            HistoryModalConfig.ConfirmClear -> HistoryComponent.Modal.ConfirmClear(
                confirmClearFactory.create(
                    componentContext = context,
                    onConfirm = {
                        modalNavigation.dismiss()
                        clearHistory()
                    },
                    onCancel = { modalNavigation.dismiss() },
                )
            )
        }
}
