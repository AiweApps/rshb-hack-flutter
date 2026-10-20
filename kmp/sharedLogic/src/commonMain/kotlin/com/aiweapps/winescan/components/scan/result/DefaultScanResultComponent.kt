package com.aiweapps.winescan.components.scan.result

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
import com.aiweapps.core.share.PlatformShare
import com.aiweapps.core.share.ShareFilePayload
import com.aiweapps.winescan.components.common.GastronomyLoader
import com.aiweapps.winescan.components.common.logCompareAdded
import com.aiweapps.winescan.components.scan.result.config.ScanResultModalConfig
import com.aiweapps.winescan.components.scan.result.model.ResultPhase
import com.aiweapps.winescan.components.scan.result.model.RetryReason
import com.aiweapps.winescan.components.scan.result.model.ScanResultState
import com.aiweapps.winescan.components.scan.result.model.ScanResultToast
import com.aiweapps.winescan.components.scan.result.model.TechKey
import com.aiweapps.winescan.components.scan.result.model.TechRow
import com.aiweapps.winescan.components.scan.result.model.TechValue
import com.aiweapps.winescan.components.scan.result.sheets.CompareComponent
import com.aiweapps.winescan.components.scan.result.sheets.DrawFrameComponent
import com.aiweapps.winescan.components.scan.result.sheets.MoreComponent
import com.aiweapps.winescan.components.scan.result.sheets.TechDetailsComponent
import com.aiweapps.winescan.components.scan.result.sheets.validatedFrameRoi
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.config.AnalyticsScreens
import com.aiweapps.winescan.config.AnalyticsValues
import com.aiweapps.winescan.config.ApiConstants
import com.aiweapps.winescan.config.CompareLimits
import com.aiweapps.winescan.config.TimingConstants
import com.aiweapps.winescan.domain.compare.model.AddToCompareResult
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.gastronomy.repository.GastronomyRepository
import com.aiweapps.winescan.domain.language.repository.AppLanguageRepository
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.RecognizedBottle
import com.aiweapps.winescan.domain.scan.model.ScanFailure
import com.aiweapps.winescan.domain.scan.model.ScanOutcome
import com.aiweapps.winescan.domain.scan.model.ScanTarget
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.domain.scan.model.WineDetailTarget
import com.aiweapps.winescan.domain.scan.repository.ScanRepository
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.put

@OptIn(ExperimentalTime::class)
@Suppress("LargeClass", "TooManyFunctions")
internal class DefaultScanResultComponent(
    componentContext: ComponentContext,
    private val target: ScanTarget,
    private val scanRepository: ScanRepository,
    private val historyRepository: ScanHistoryRepository,
    private val compareRepository: CompareSetRepository,
    gastronomyRepository: GastronomyRepository,
    appLanguage: AppLanguageRepository,
    private val platformShare: PlatformShare,
    private val platformLinks: PlatformLinks,
    private val analytics: AnalyticsTracker,
    private val sheetFactories: ScanResultSheetFactories,
    private val json: Json,
    private val onClose: () -> Unit,
    private val onNewScan: () -> Unit,
    private val onOpenCompare: () -> Unit,
    private val onOpenPairing: () -> Unit,
    private val onOpenWineDetail: (WineDetailTarget) -> Unit,
    private val onOpenFramedResult: (ScanTarget.Framed) -> Unit,
    private val clock: Clock = Clock.System,
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
) : ScanResultComponent, BaseStatefulComponent<ScanResultState>(
    componentContext = componentContext,
    initialState = ScanResultState(),
    mainContext = mainContext,
) {

    private val modalNavigation = SlotNavigation<ScanResultModalConfig>()

    override val modalSlot: Value<ChildSlot<*, ScanResultComponent.Modal>> =
        childSlot(
            source = modalNavigation,
            serializer = ScanResultModalConfig.serializer(),
            handleBackButton = true,
            childFactory = ::createModal,
        )

    private var requestJob: Job? = null
    private var retryJob: Job? = null

    // Bumped by every request and by leaving: an answer that arrives for an older request
    // (a repository call that ignored the cancellation) is dropped, not shown.
    private var requestRevision: Long = 0

    // The facts of every card on screen load beside the answer and never hold it up.
    private val gastronomy = GastronomyLoader(
        repository = gastronomyRepository,
        appLanguage = appLanguage,
        analytics = analytics,
        screen = AnalyticsScreens.SCAN_RESULT,
        scope = scope,
        lifecycle = lifecycle,
        onUpdate = { snapshot -> updateState {
            copy(
                facts = snapshot.facts,
                isFactsLoading = snapshot.isLoading,
                factsErrors = snapshot.errorsBySlug,
            )
        } },
    )

    init {
        // The reference images need a session; the photo and the answer do not wait for one.
        scope.launch {
            val access = scanRepository.referenceAccess()
            updateState { copy(referenceAccess = access) }
        }
        compareRepository.watch()
            .onEach { entries -> updateState { copy(compareSlugs = entries.map { it.slug }.toSet()) } }
            // The pill is a convenience; a database read failing must not take the answer down.
            .catch { }
            .launchIn(scope)
        when (target) {
            is ScanTarget.NewScan -> {
                updateState {
                    copy(
                        screenState = ScreenState.Content,
                        photoPath = target.photoPath,
                    )
                }
                recognize(roi = null)
            }
            is ScanTarget.Stored -> openStored(target.scanId)
            is ScanTarget.Framed -> {
                updateState {
                    copy(
                        screenState = ScreenState.Content,
                        photoPath = target.photoPath,
                        isFramed = true,
                    )
                }
                recognize(roi = target.roi)
            }
        }
    }

    override fun onBackClicked() {
        cancelWork()
        onClose()
    }

    override fun onRetryClicked() {
        if (currentState.phase == ResultPhase.RECOGNIZING) return
        updateState { copy(retryAttempt = 0) }
        recognize(roi = currentState.pendingRoi)
    }

    override fun onFactsRetryClicked() {
        gastronomy.retryFailed()
    }

    override fun onNewScanClicked() {
        cancelWork()
        onNewScan()
    }

    override fun onBottleSelected(instanceId: String?) {
        val view = currentState.view ?: return
        // Tapping the selected bottle again returns to "all" when there are several, as on the web.
        val next = if (instanceId == currentState.selectedInstanceId && view.bottles.size > 1) null else instanceId
        updateState { copy(selectedInstanceId = next, techRows = techRows(view, next)) }
    }

    override fun onCardLinkClicked(url: String) {
        analytics.logEvent(
            AnalyticsEvents.WINE_PAGE_OPENED,
            mapOf(AnalyticsParams.SCREEN to AnalyticsScreens.SCAN_RESULT),
        )
        platformLinks.openUrl(url)
    }

    override fun onCompareClicked() {
        val bottle = currentState.selectedBottle ?: return
        val card = currentState.selectedCard ?: return
        openCompare(bottle, card)
    }

    override fun onCompareCardClicked(instanceId: String, card: WineCard) {
        val bottle = currentState.view?.bottleById(instanceId) ?: return
        openCompare(bottle, card)
    }

    override fun onAlternativeClicked(instanceId: String, card: WineCard) {
        onOpenWineDetail(WineDetailTarget(card = card, bottle = currentState.bottlePhoto(instanceId)))
    }

    override fun onMoreClicked() {
        val view = currentState.view ?: return
        if (!currentState.hasAnswer) return
        modalNavigation.activate(
            ScanResultModalConfig.More(
                isRoi = view.isExplicitRoi,
                bottleNumber = currentState.selectedBottle?.number,
                canRescanBottle = currentState.canRescanBottle,
                canDrawFrame = currentState.canDrawFrame,
            )
        )
    }

    override fun onAddToCompareClicked(instanceId: String) {
        scope.launch { addToCompare(instanceId, announce = true) }
    }

    override fun onRemoveFromCompareClicked(instanceId: String) {
        val slug = currentState.view?.bottleById(instanceId)?.best?.slug ?: return
        scope.launch {
            try {
                compareRepository.remove(slug)
                updateState { copy(toast = ScanResultToast.RemovedFromCompare) }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                updateState { copy(toast = ScanResultToast.RemoveFromCompareFailed) }
            }
        }
    }

    override fun onCompareWinesClicked() {
        val state = currentState
        if (!state.canOpenCompare) return
        val bottle = state.selectedBottle
        val card = bottle?.best
        // The pill means «compare this one too»: the wine on screen joins a set that already
        // has something to compare it with, unless it is there or the set is full.
        val shouldAdd = bottle != null && card != null && !state.isInCompare(card) &&
            state.compareCount < CompareLimits.MAX_WINES
        if (!shouldAdd) {
            onOpenCompare()
            return
        }
        scope.launch {
            addToCompare(bottle.instanceId, announce = true)
            onOpenCompare()
        }
    }

    override fun onPairDishClicked(instanceId: String) {
        scope.launch {
            // The requested wine must be present in the set used by the dish screen.
            when (addToCompare(instanceId, announce = false)) {
                AddToCompareResult.ADDED, AddToCompareResult.ALREADY_THERE -> onOpenPairing()
                AddToCompareResult.FULL -> updateState { copy(toast = ScanResultToast.CompareFull) }
                null -> Unit // addToCompare already reports an unsuccessful write.
            }
        }
    }

    override fun onModalDismissed() {
        // The frame screen replaces «More» in the slot; the outgoing sheet reports its own
        // dismissal, which must not close the screen that took its place. The frame screen
        // closes through its own ✕ and «Scan».
        if (modalSlot.value.child?.instance is ScanResultComponent.Modal.DrawFrame) return
        modalNavigation.dismiss()
    }

    override fun onToastConsumed() {
        updateState { copy(toast = null) }
    }

    /**
     * Adds the bottle's best card to the comparison; `null` when nothing could be written.
     * [announce] toasts the outcome; a failed write is toasted either way.
     */
    private suspend fun addToCompare(instanceId: String, announce: Boolean): AddToCompareResult? {
        val card = currentState.view?.bottleById(instanceId)?.best ?: return null
        val bottle = currentState.bottlePhoto(instanceId) ?: return null
        return try {
            val result = compareRepository.add(bottle.toCompareCandidate(card))
            logCompareAdded(analytics, AnalyticsScreens.SCAN_RESULT, result)
            if (announce) {
                val toast = when (result) {
                    AddToCompareResult.ADDED -> ScanResultToast.AddedToCompare
                    AddToCompareResult.ALREADY_THERE -> ScanResultToast.AlreadyInCompare
                    AddToCompareResult.FULL -> ScanResultToast.CompareFull
                }
                updateState { copy(toast = toast) }
            }
            result
        } catch (e: CancellationException) {
            throw e
        } catch (_: Exception) {
            updateState { copy(toast = ScanResultToast.AddToCompareFailed) }
            null
        }
    }

    private fun openStored(scanId: Long) {
        scope.launch {
            val record = historyRepository.byId(scanId)
            if (record == null) {
                updateState { copy(screenState = ScreenState.Error(AppError.Unknown)) }
                return@launch
            }
            updateState {
                copy(
                    screenState = ScreenState.Content,
                    photoPath = record.photoPath,
                    isStored = true,
                    historyId = record.id,
                )
            }
            // A stored answer was seen once already: no tip the second time.
            showAnswer(record.view, announce = false)
        }
    }

    private fun recognize(roi: BottleBox?) {
        retryJob?.cancel()
        requestJob?.cancel()
        val revision = ++requestRevision
        val photoPath = currentState.photoPath
        updateState { copy(phase = ResultPhase.RECOGNIZING, isRoiRequest = roi != null, pendingRoi = roi, failure = null, geometryProgress = null) }
        requestJob = scope.launch {
            val outcome = scanRepository.recognizeWithProgress(photoPath, roi) { progress ->
                // Native callbacks may arrive off the main thread, after cancel, or after the answer.
                scope.launch {
                    if (requestJob?.isActive == true && revision == requestRevision &&
                        currentState.photoPath == photoPath && currentState.phase == ResultPhase.RECOGNIZING) {
                        updateState { copy(geometryProgress = progress) }
                    }
                }
            }
            if (!isActive || revision != requestRevision || currentState.photoPath != photoPath) return@launch
            when (outcome) {
                is ScanOutcome.Recognized -> {
                    logRecognized(outcome.view, roi)
                    updateState { copy(retryAttempt = 0, isSavingHistory = willStore(roi)) }
                    showAnswer(outcome.view, announce = true)
                    storeIfNew(outcome.view, roi)
                }
                is ScanOutcome.Failed -> handleFailure(outcome.failure)
            }
        }
    }

    private fun showAnswer(view: RecognitionView, announce: Boolean) {
        val selection = initialSelection(view)
        updateState {
            copy(
                phase = ResultPhase.ANSWER,
                geometryProgress = null,
                view = view,
                selectedInstanceId = selection,
                pendingRoi = null,
                failure = null,
                techRows = techRows(view, selection),
                toast = if (announce) announcement(view) else toast,
            )
        }
        gastronomy.load(view.bottles.flatMap { bottle -> listOfNotNull(bottle.best) + bottle.alternatives })
    }

    // Only the automatic answer of a fresh photo goes to the history: not a frame asked for
    // on it, not a result opened for a drawn frame, not a scan already stored.
    private fun willStore(roi: BottleBox?): Boolean {
        val state = currentState
        return roi == null && !state.isStored && !state.isFramed && state.historyId == null
    }

    private suspend fun storeIfNew(view: RecognitionView, roi: BottleBox?) {
        if (!willStore(roi)) return
        val photoPath = currentState.photoPath
        try {
            val id = historyRepository.save(photoPath = photoPath, view = view)
            // The store moved the photo under its own name; the screen follows the new path.
            val record = historyRepository.byId(id)
            if (currentState.photoPath != photoPath) return
            updateState { copy(historyId = id, photoPath = record?.photoPath ?: photoPath) }
        } catch (e: CancellationException) {
            throw e
        } catch (_: Exception) {
            // A full disk or a missing file: the answer is still on screen, it just will not
            // be in the history.
        } finally {
            updateState { copy(isSavingHistory = false) }
        }
    }

    private fun cancelWork() {
        requestRevision += 1
        requestJob?.cancel()
        retryJob?.cancel()
    }

    private fun handleFailure(failure: ScanFailure) {
        // 429 and a busy 503 both say when to come back: wait and retry by ourselves a few
        // times instead of showing an error.
        if (failure.isThrottled && currentState.retryAttempt < ApiConstants.MAX_AUTO_RETRIES) {
            val seconds = (failure.retryAfterSeconds ?: ApiConstants.DEFAULT_RETRY_AFTER_SECONDS).coerceAtLeast(1).toInt()
            updateState {
                copy(
                    phase = ResultPhase.WAITING_RETRY,
                    retryAttempt = retryAttempt + 1,
                    retrySecondsLeft = seconds,
                    retryReason = if (failure.statusCode == ScanFailure.HTTP_TOO_MANY) RetryReason.TOO_MANY else RetryReason.BUSY,
                )
            }
            startRetryCountdown()
            return
        }
        analytics.logEvent(
            AnalyticsEvents.RECOGNITION_FAILED,
            mapOf(
                AnalyticsParams.REQUEST to requestOf(currentState.pendingRoi),
                AnalyticsParams.REASON to failure.kind.name.lowercase(),
            ),
        )
        updateState { copy(phase = ResultPhase.FAILED, failure = failure) }
    }

    private fun logRecognized(view: RecognitionView, roi: BottleBox?) {
        analytics.logEvent(
            AnalyticsEvents.RECOGNITION_SUCCEEDED,
            mapOf(
                AnalyticsParams.REQUEST to requestOf(roi),
                AnalyticsParams.DECISION to view.decisionKind.apiName,
                AnalyticsParams.BOTTLES to view.bottles.size.toString(),
            ),
        )
    }

    // Only a framed result asks for a box, and it asks for its own.
    private fun requestOf(roi: BottleBox?): String = when {
        roi == null -> AnalyticsValues.REQUEST_PHOTO
        target is ScanTarget.Framed && target.isBottle -> AnalyticsValues.REQUEST_BOTTLE
        else -> AnalyticsValues.REQUEST_FRAME
    }

    private fun startRetryCountdown() {
        retryJob?.cancel()
        retryJob = scope.launch {
            while (currentState.phase == ResultPhase.WAITING_RETRY) {
                delay(TimingConstants.RETRY_TICK_MS)
                val left = currentState.retrySecondsLeft - 1
                if (left > 0) {
                    updateState { copy(retrySecondsLeft = left) }
                } else {
                    recognize(roi = currentState.pendingRoi)
                    return@launch
                }
            }
        }
    }

    private fun openCompare(bottle: RecognizedBottle, card: WineCard) {
        val view = currentState.view ?: return
        modalNavigation.activate(
            ScanResultModalConfig.Compare(
                crop = view.cropOf(bottle),
                bottleNumber = bottle.number,
                cardTitle = card.title,
                reference = card.reference,
            )
        )
    }

    private fun drawFrame() {
        val state = currentState
        if (!state.canDrawFrame) return
        // Activating the frame screen replaces «More» in the slot, so it closes by itself.
        modalNavigation.activate(ScanResultModalConfig.DrawFrame(photoPath = state.photoPath, frame = state.frame))
    }

    private fun onFrameDrawn(roi: BottleBox) {
        openFramedResult(roi, isBottle = false)
    }

    private fun rescanBottle() {
        val state = currentState
        if (!state.canRescanBottle) return
        val roi = state.selectedBottle?.selectRoiBox ?: return
        openFramedResult(roi, isBottle = true)
    }

    /**
     * A new result for [roi] on the same photo; the sheet on top closes first. A box with
     * nothing left inside the photo opens nothing.
     */
    @OptIn(kotlin.uuid.ExperimentalUuidApi::class)
    private fun openFramedResult(roi: BottleBox, isBottle: Boolean) {
        modalNavigation.dismiss()
        val checked = validatedFrameRoi(roi, currentState.frame) ?: return
        // The current path, not the one the sheet opened with: saving the answer to the
        // history may have moved the photo meanwhile.
        onOpenFramedResult(ScanTarget.Framed(photoPath = currentState.photoPath, roi = checked, isBottle = isBottle,
            requestId = kotlin.uuid.Uuid.random().toString()))
    }

    private fun shareFull() {
        val view = currentState.view ?: return
        modalNavigation.dismiss()
        logShared(AnalyticsValues.SCOPE_PHOTO)
        platformShare.shareFile(
            ShareFilePayload(
                fileName = fileName("scan"),
                mimeType = ApiConstants.JSON_MIME_TYPE,
                content = json.encodeToString(view),
            )
        )
    }

    private fun shareBottle() {
        val view = currentState.view ?: return
        val bottle = currentState.selectedBottle ?: return
        modalNavigation.dismiss()
        logShared(AnalyticsValues.SCOPE_BOTTLE)
        val payload: JsonObject = buildJsonObject {
            put(JSON_MODE, view.mode)
            put(JSON_ROI, view.roi ?: JsonPrimitive(null as String?))
            put(JSON_FRAME_SIZE, json.encodeToJsonElement(view.frameSize))
            put(JSON_IMAGE, json.encodeToJsonElement(view.image))
            put(JSON_BOTTLE, json.encodeToJsonElement(bottle))
        }
        platformShare.shareFile(
            ShareFilePayload(
                fileName = fileName(if (view.isExplicitRoi) "scan-frame" else "scan-bottle-${bottle.number}"),
                mimeType = ApiConstants.JSON_MIME_TYPE,
                content = json.encodeToString(JsonObject.serializer(), payload),
            )
        )
    }

    private fun logShared(scope: String) {
        analytics.logEvent(AnalyticsEvents.RESULT_SHARED, mapOf(AnalyticsParams.SCOPE to scope))
    }

    private fun showTechDetails() {
        modalNavigation.activate(ScanResultModalConfig.TechDetails)
    }

    // A frame answer is about one target: the service names it, or nothing is chosen. An
    // automatic answer opens on its best bottle; «All» stays a tap away.
    private fun initialSelection(view: RecognitionView): String? = when {
        view.bottles.size == 1 -> view.bottles.first().instanceId
        view.isExplicitRoi -> view.bottleById(view.primaryInstanceId)?.instanceId
        else -> view.bestBottle()?.instanceId
    }

    private fun announcement(view: RecognitionView): ScanResultToast? {
        val count = view.bottles.size
        return when {
            view.isExplicitRoi -> if (count > 0) ScanResultToast.RoiFound else ScanResultToast.RoiEmpty
            count > 1 -> ScanResultToast.ManyBottles(count)
            else -> null
        }
    }

    private fun techRows(view: RecognitionView, selectedId: String?): List<TechRow> {
        val bottle = view.bottleById(selectedId)
        val card = bottle?.best ?: view.publishedCard
        val image = view.image
        fun text(value: String?): TechValue = if (value.isNullOrEmpty()) TechValue.None else TechValue.Text(value)
        return listOf(
            TechRow(TechKey.DECISION, TechValue.Text(view.decisionKind.apiName)),
            TechRow(TechKey.PRIMARY_BASIS, text(view.primaryBasis)),
            TechRow(TechKey.MODE, TechValue.Text(view.modeKind.apiName)),
            TechRow(TechKey.RAW_SLUG, text(view.rawSlug)),
            TechRow(TechKey.BEST_CANDIDATE, text(view.bestSlug)),
            TechRow(TechKey.CARD_SLUG, text(card?.slug)),
            TechRow(TechKey.PAGE_URL, text(card?.pageUrl)),
            TechRow(TechKey.PAGE_SOURCE, text(card?.pageSource)),
            TechRow(
                TechKey.SNAPSHOT,
                when (card?.pageInSiteSnapshot) {
                    true -> TechValue.SnapshotYes
                    false -> TechValue.SnapshotNo
                    null -> TechValue.None
                },
            ),
            TechRow(TechKey.ROI, text(view.roiBox?.toList()?.joinToString(", "))),
            TechRow(TechKey.BOTTLES, TechValue.Text(view.bottleCount.toString())),
            TechRow(TechKey.FRAME, text(view.frame?.joinToString(" × "))),
            TechRow(
                TechKey.FILE,
                if (image?.format != null && image.bytes != null) TechValue.File(image.format, image.bytes) else TechValue.None,
            ),
            TechRow(TechKey.PROBABILITY, TechValue.ProbabilityNotCalculated),
            TechRow(TechKey.BACKEND_TIME, view.backendMs?.let { TechValue.Milliseconds(it) } ?: TechValue.None),
            TechRow(TechKey.PROFILE, text(view.profileChecksum)),
            TechRow(TechKey.REASONS, text(view.reasons.joinToString(", "))),
        )
    }

    private fun fileName(prefix: String): String {
        val stamp = clock.now().toString().replace(':', '-').replace('.', '-')
        return "$prefix-$stamp.json"
    }

    private fun createModal(config: ScanResultModalConfig, context: ComponentContext): ScanResultComponent.Modal =
        when (config) {
            is ScanResultModalConfig.DrawFrame -> ScanResultComponent.Modal.DrawFrame(
                sheetFactories.drawFrame.create(
                    componentContext = context,
                    photoPath = config.photoPath,
                    frame = config.frame,
                    // Orientation only; after a restore the answer is not back yet and the
                    // screen goes without the boxes.
                    view = currentState.view,
                    // Only while this very frame screen is the one in the slot: a late callback
                    // from a screen on its way out must not close or open anything else.
                    onFrameDrawn = { roi -> if (modalSlot.value.child?.configuration == config) onFrameDrawn(roi) },
                    onCancel = { if (modalSlot.value.child?.configuration == config) modalNavigation.dismiss() },
                )
            )
            is ScanResultModalConfig.Compare -> ScanResultComponent.Modal.Compare(
                sheetFactories.compare.create(
                    componentContext = context,
                    photoPath = currentState.photoPath,
                    crop = config.crop,
                    frame = currentState.frame,
                    bottleNumber = config.bottleNumber,
                    cardTitle = config.cardTitle,
                    reference = config.reference,
                    referenceAccess = currentState.referenceAccess,
                    onClose = { modalNavigation.dismiss() },
                )
            )
            is ScanResultModalConfig.More -> ScanResultComponent.Modal.More(
                sheetFactories.more.create(
                    componentContext = context,
                    isRoi = config.isRoi,
                    bottleNumber = config.bottleNumber,
                    canRescanBottle = config.canRescanBottle,
                    canDrawFrame = config.canDrawFrame,
                    onRescanBottle = ::rescanBottle,
                    onDrawFrame = ::drawFrame,
                    onShareFull = ::shareFull,
                    onShareBottle = ::shareBottle,
                    onTechDetails = ::showTechDetails,
                )
            )
            ScanResultModalConfig.TechDetails -> ScanResultComponent.Modal.TechDetails(
                sheetFactories.techDetails.create(
                    componentContext = context,
                    rows = currentState.techRows,
                    onClose = { modalNavigation.dismiss() },
                )
            )
        }

    private companion object {
        const val JSON_MODE = "mode"
        const val JSON_ROI = "roi"
        const val JSON_FRAME_SIZE = "frame_size"
        const val JSON_IMAGE = "image"
        const val JSON_BOTTLE = "bottle"
    }
}

/** The modals of the result screen, bundled so the constructor stays readable. */
class ScanResultSheetFactories(
    val drawFrame: DrawFrameComponent.Factory,
    val compare: CompareComponent.Factory,
    val more: MoreComponent.Factory,
    val techDetails: TechDetailsComponent.Factory,
)
