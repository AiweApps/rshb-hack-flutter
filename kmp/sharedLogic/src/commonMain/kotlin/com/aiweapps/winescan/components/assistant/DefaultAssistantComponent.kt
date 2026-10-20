package com.aiweapps.winescan.components.assistant

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.value.Value
import com.aiweapps.core.components.base.BaseStatefulComponent
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.core.error.AppError
import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.winescan.components.assistant.model.AssistantState
import com.aiweapps.winescan.components.assistant.model.AssistantCompareNotice
import com.aiweapps.winescan.domain.compare.model.AddToCompareResult
import com.aiweapps.winescan.domain.compare.model.CompareCandidate
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.assistant.model.*
import com.aiweapps.winescan.domain.assistant.repository.AssistantService
import com.aiweapps.winescan.domain.assistant.repository.AssistantDinnerSelectionStale
import com.aiweapps.winescan.domain.assistant.repository.AssistantLocalRepository
import com.aiweapps.winescan.domain.assistant.repository.AssistantLocalState
import com.aiweapps.winescan.domain.assistant.repository.RetailGateway
import com.aiweapps.winescan.domain.assistant.repository.RetailResult
import com.aiweapps.winescan.domain.assistant.repository.RetailUnavailableReason
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.scan.model.ScanOutcome
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.domain.scan.repository.ScanRepository
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.cancellation.CancellationException
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** The single owner of the assistant tab's mutable conversation and photo operation state. */
@OptIn(ExperimentalUuidApi::class)
internal class DefaultAssistantComponent(
    componentContext: ComponentContext,
    private val scanRepository: ScanRepository,
    private val historyRepository: ScanHistoryRepository,
    private val service: AssistantService,
    private val retailGateway: RetailGateway,
    private val accounts: com.aiweapps.winescan.domain.assistant.repository.AssistantAccountRepository,
    private val localRepository: AssistantLocalRepository,
    private val platformLinks: PlatformLinks,
    private val catalog: com.aiweapps.winescan.domain.catalog.repository.WineCatalogRepository,
    private val compareRepository: CompareSetRepository,
    private val onOpenCompare: (AddToCompareResult) -> Unit,
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
) : AssistantComponent, BaseStatefulComponent<AssistantState>(
    componentContext = componentContext,
    initialState = AssistantState(screenState = ScreenState.Loading),
    mainContext = mainContext,
) {

    override val state: Value<AssistantState> get() = super.state

    private var compareJob: Job? = null
    private var compareRevision: Long = 0
    private var comparedSlugs: Set<String> = emptySet()
    private var wineMetadataJob: Job? = null
    private var wineMetadataRevision: Long = 0
    private val favoriteJobs = mutableSetOf<Job>()
    private data class PendingFavorite(
        val revision: Long, val subject: String?, val wine: AssistantWine, val adding: Boolean,
    )
    private var favoriteRevision = 0L
    private val pendingFavorites = mutableMapOf<String, PendingFavorite>()
    private var historyJob: Job? = null
    private var accountStartupJob: Job? = null
    private var accountStartupComplete = false
    private data class PendingComparisonImport(val wines: List<WineCard>, val prompt: String)
    private var pendingComparisonImport: PendingComparisonImport? = null
    private val conversationReady: Boolean
        get() = accountStartupComplete && currentState.screenState == ScreenState.Content
    private var operation: Job? = null
    private var retailOperation: Job? = null
    private val saveMutex = Mutex()
    private var remoteSessionId: String? = null
    private var hasInteracted = false
    private data class PendingSend(
        val requestId: String, val localConversationId: String, val text: String,
        val wine: AssistantWine?, val photoWines: List<AssistantPhotoWine>,
        val photoScans: List<AssistantPhotoScan>, val storeId: Int?,
        val comparisonWines: List<AssistantWine> = emptyList(),
    )
    private var pendingSend: PendingSend? = null
    // A location question completed successfully. This is an unfinished user intent,
    // not a failed transport request; confirming a store may resume it once.
    private var pendingStoreIntent: PendingSend? = null
    private data class PendingReplacement(
        val sourceMessageId: String, val oldProductId: String,
        val replacementProductId: String, val packages: Int, val requestId: String,
    )
    private var pendingReplacement: PendingReplacement? = null
    private var pendingReplacementProductId: String? = null
    private data class PendingDinnerSelection(
        val localConversationId: String, val sourceMessageId: String,
        val optionId: String, val requestId: String,
    )
    private var pendingDinnerSelection: PendingDinnerSelection? = null
    private data class PendingStoreSelection(
        val localConversationId: String, val subject: String?, val storeId: Int,
        val requestId: String, val selectedAt: String,
    )
    private var pendingStoreSelection: PendingStoreSelection? = null
    private sealed interface StoreSearchQuery {
        data class Address(val value: String) : StoreSearchQuery
        data class Coordinates(val latitude: Double, val longitude: Double) : StoreSearchQuery
    }
    private data class PendingStoreSearch(
        val localConversationId: String, val subject: String?, val revision: Long,
        val query: StoreSearchQuery,
    )
    private var storeSearchRevision = 0L
    // Keep the failed address/GPS request separate from older message and basket retries.
    private var pendingStoreSearch: PendingStoreSearch? = null
    private val savedWines = linkedMapOf<String, AssistantWine>()

    init {
        scope.launch {
            try {
                compareRepository.watch().collect { entries ->
                    comparedSlugs = entries.mapTo(linkedSetOf()) { it.slug }
                    updateState { copy(compareSlugs = comparedSlugs) }
                }
            } catch (error: CancellationException) { throw error }
            catch (_: Exception) { /* A comparison read must not stop the conversation. */ }
        }
        scope.launch {
            try {
                val access = scanRepository.referenceAccess()
                updateState { copy(referenceAccess = access) }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                // Local conversations remain usable if the recognition API is offline.
            }
        }
        scope.launch {
            try {
                // «My wines» can change elsewhere too (a heart in the history); keep the cards'
                // enriched copies for wines that are still saved.
                localRepository.watchSavedWinesByOwner().collect { snapshot ->
                    applySavedWines(snapshot.subject, snapshot.wines)
                }
            } catch (error: CancellationException) { throw error }
            catch (_: Exception) { /* The hearts keep what this screen knows. */ }
        }
        startAccountStartup()
    }

    private fun startAccountStartup() {
        if (accountStartupJob?.isActive == true) return
        updateState { copy(screenState = ScreenState.Loading) }
        accountStartupJob = scope.launch {
            try {
                accounts.initialize()
                if (accounts.isFirstUseBootstrapPending()) {
                    // This is a global, source-independent check, not the current subject's view.
                    if (localRepository.hasAnyAssistantData()) accounts.skipFirstUseBootstrap()
                    else accounts.startGuest()
                }
                accountStartupComplete = true
            } catch (error: CancellationException) { throw error }
            catch (_: Exception) {
                // No composer or account switch is exposed before this one-time decision.
                // A first-use marker remains pending; Retry explicitly starts another attempt.
                updateState { copy(screenState = ScreenState.Error(AppError.Unknown)) }
                return@launch
            }
            accounts.account.collect { identity ->
                if (currentState.account?.subject == identity?.subject && currentState.account != null && identity != null) {
                    updateState { copy(account = identity) }
                    return@collect
                }
                cancelCompareOperation()
                operation?.cancel()
                wineMetadataJob?.cancel()
                wineMetadataRevision += 1
                retailOperation?.cancel()
                historyJob?.cancel()
                favoriteJobs.toList().forEach { it.cancel() }
                favoriteJobs.clear()
                pendingFavorites.clear()
                saveMutex.withLock { }
                remoteSessionId = null
                pendingSend = null
                pendingStoreIntent = null
                pendingReplacement = null
                pendingReplacementProductId = null
                pendingDinnerSelection = null
                pendingStoreSelection = null
                cancelStoreSearch()
                savedWines.clear()
                updateState { AssistantState(account = identity, legacyHistory = identity == null,
                    compareSlugs = comparedSlugs, referenceAccess = referenceAccess) }
                hasInteracted = false
                // A user may enter from Compare while the first guest is still starting.
                // Stage only that explicit typed intent; never copy a previous identity's chat.
                val imported = pendingComparisonImport
                pendingComparisonImport = null
                if (imported != null) onComparisonRequested(imported.wines, imported.prompt)
                historyJob = scope.launch { loadAccountHistory() }
            }
        }
    }

    private suspend fun loadAccountHistory() {
            try {
                val subject = currentState.account?.subject
                val storedWines = localRepository.loadSavedWines()
                if (accounts.account.value?.subject != subject || currentState.account?.subject != subject) return
                applySavedWines(subject, storedWines)
                val existing = localRepository.watchConversations().first()
                if (!hasInteracted && existing.isNotEmpty()) {
                    val restored = localRepository.load(existing.first().id)
                    if (restored != null) restore(restored)
                }
                updateState { copy(savedWines = this@DefaultAssistantComponent.savedWines.values.toList()) }
                hydrateConversationWines(currentState.conversationId)
                if (accounts.account.value != null) {
                    try {
                        val subject = accounts.account.value!!.subject
                        val known = localRepository.watchConversations().first().map { it.id }.toSet()
                        service.conversations().forEach { remote ->
                            val id = "$subject::remote::${remote.id}"
                            if (known.none { localId -> localRepository.load(localId)?.remoteSessionId == remote.id }) {
                                val messages = service.messages(remote.id)
                                localRepository.save(AssistantLocalState(id, remote.title, messages, remoteSessionId = remote.id,
                                    selectedStoreId = messages.lastOrNull { it.kind == AssistantMessageKind.STORE_SELECTED }?.stores?.firstOrNull()?.id))
                            }
                        }
                        if (currentState.conversationId == null) {
                            val first = localRepository.watchConversations().first().firstOrNull()
                            first?.let { localRepository.load(it.id) }?.let { restore(it) }
                        }
                    } catch (e: CancellationException) { throw e }
                    catch (_: Exception) { /* Local account history remains available offline. */ }
                }
                localRepository.watchConversations().collect { rows ->
                    updateState { copy(conversations = rows) }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                updateState { copy(errorCode = AssistantUiError.SESSION_OPEN_FAILED) }
            }
    }

    override fun onAccountErrorDismissed() { updateState { copy(accountError = false) } }
    override fun onAccountSubmit(username: String, password: String, register: Boolean) {
        if (!conversationReady || currentState.accountBusy) return
        scope.launch {
            updateState { copy(accountBusy = true, accountError = false) }
            try {
                if (username.isBlank() && password.isBlank()) accounts.startGuest()
                else accounts.authenticate(username, password, register)
            }
            catch (e: CancellationException) { throw e }
            catch (_: Exception) { updateState { copy(accountError = true) } }
            finally { updateState { copy(accountBusy = false) } }
        }
    }
    override fun onLogoutClicked() {
        if (!conversationReady || currentState.accountBusy) return
        scope.launch {
            updateState { copy(accountBusy = true, accountError = false) }
            try { accounts.logout() }
            catch (e: CancellationException) { throw e }
            catch (_: Exception) { updateState { copy(accountError = true) } }
            finally { updateState { copy(accountBusy = false) } }
        }
    }

    private fun newConversationId(): String = accounts.account.value?.subject?.let { "$it::${nextId()}" } ?: nextId()
    private fun ensureLocalConversation(): String {
        hasInteracted = true
        val current = currentState.conversationId
        if (current != null) return current
        val id = newConversationId()
        updateState { copy(conversationId = id) }
        return id
    }

    private fun restore(local: AssistantLocalState) {
        remoteSessionId = local.remoteSessionId.takeIf { currentState.account != null }
        val storedStores = local.messages.flatMap { it.stores }.asReversed().distinctBy { it.id }
        updateState {
            copy(
                conversationId = local.id,
                messages = local.messages,
                draft = local.draft,
                attachments = local.attachments,
                pendingAttachments = 0,
                selectedWine = (local.messages.asSequence().flatMap { it.wines.asSequence() } +
                    this@DefaultAssistantComponent.savedWines.values.asSequence()).firstOrNull {
                    it.slug == local.selectedWineSlug && it.photoId == local.selectedWinePhotoId &&
                        it.instanceId == local.selectedWineInstanceId
                },
                availableStores = storedStores,
                selectedStore = storedStores.firstOrNull { it.id == local.selectedStoreId },
                phase = AssistantPhase.IDLE,
                errorCode = null,
            )
        }
        absorbStores(local.messages)
        recoverStoreIntent(local.id)
        hydrateConversationWines(local.id)
        val remoteId = local.remoteSessionId?.takeIf { currentState.account != null } ?: run {
            markUnansweredUserForRetry(local.id)
            return
        }
        scope.launch {
            try {
                val remoteMessages = service.messages(remoteId).filterNot {
                    it.kind == AssistantMessageKind.USER_TEXT || it.kind == AssistantMessageKind.USER_PHOTOS
                }
                if (currentState.conversationId != local.id) return@launch
                absorbStores(remoteMessages)
                val existingIds = currentState.messages.mapTo(hashSetOf()) { it.id }
                val localWineSlugs = currentState.messages.flatMap { it.wines }.map { it.slug }.toSet()
                val missing = remoteMessages.filterNot { message ->
                    message.id in existingIds || (message.kind == AssistantMessageKind.WINE_RESULTS &&
                        message.wines.isNotEmpty() && message.wines.all { it.slug in localWineSlugs })
                }
                val authoritative = remoteMessages.associateBy { it.id }
                val completedRequests = remoteMessages.filter { it.kind == AssistantMessageKind.ASSISTANT_TEXT }
                    .mapNotNull { it.requestId }.toSet()
                val mealSources = remoteMessages.filter { it.kind == AssistantMessageKind.DINNER_OPTIONS ||
                    (it.kind == AssistantMessageKind.PRODUCTS && it.sourceMessageId != null && it.replacementForProductId == null) }
                    .mapNotNull { it.sourceMessageId }.toSet()
                val cachedMessages = withoutCompletedTransportErrors(currentState.messages, completedRequests)
                val reconciled = mergeMessages(cachedMessages.filterNot { cached ->
                    cached.kind == AssistantMessageKind.PRODUCTS && cached.sourceMessageId == null &&
                        cached.replacementForProductId == null && cached.id !in authoritative &&
                        mealSources.any { parent -> cached.id.removePrefix("$parent-").let { suffix ->
                            cached.id.startsWith("$parent-") && suffix.isNotEmpty() && suffix.all { it.isDigit() }
                        } }
                }.map { cached ->
                    authoritative[cached.id] ?: if (cached.retryContext?.requestId in completedRequests)
                        cached.copy(retryContext = cached.retryContext?.copy(awaitingReply = false)) else cached
                }, missing)
                if (reconciled != currentState.messages) {
                    // This is the local rendering cache. Server history bytes are unchanged;
                    // current read-time projections (price units, snapshots) must reach the UI.
                    updateState { copy(messages = reconciled) }
                    hydrateConversationWines(local.id)
                    persistSoon()
                }
                recoverStoreIntent(local.id)
                markUnansweredUserForRetry(local.id)
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                // Offline reopening keeps local data and exposes a retry for an unanswered message.
                markUnansweredUserForRetry(local.id)
            }
        }
    }

    private fun mergeMessages(existing: List<AssistantMessage>, incoming: List<AssistantMessage>): List<AssistantMessage> =
        (existing + incoming).associateBy { it.id }.values.toList()

    private fun withoutCompletedTransportErrors(
        messages: List<AssistantMessage>, completedRequests: Set<String>,
    ): List<AssistantMessage> {
        var userRequestId: String? = null
        return messages.filter { message ->
            if (message.kind in setOf(AssistantMessageKind.USER_TEXT, AssistantMessageKind.USER_PHOTOS)) {
                userRequestId = message.retryContext?.requestId ?: message.requestId
            }
            // Older local errors have no ID. Bind only those inside this user's
            // request segment; server errors and unrelated requests stay intact.
            !(message.kind == AssistantMessageKind.ERROR && message.source == "local_transport" &&
                (message.requestId ?: userRequestId) in completedRequests)
        }
    }

    private fun recoverStoreIntent(conversationId: String) {
        val messages = currentState.messages
        val lastUser = messages.indexOfLast {
            it.kind == AssistantMessageKind.USER_TEXT || it.kind == AssistantMessageKind.USER_PHOTOS
        }
        val context = messages.getOrNull(lastUser)?.retryContext
        val waiting = lastUser >= 0 && messages.drop(lastUser + 1).any {
            it.kind == AssistantMessageKind.LOCATION_REQUEST &&
                (context == null || it.requestId == context.requestId)
        } && messages.drop(lastUser + 1).none {
            it.kind == AssistantMessageKind.DINNER_OPTIONS || it.kind == AssistantMessageKind.PRODUCTS
        }
        pendingStoreIntent = if (waiting) messages[lastUser].text.takeIf { it.isNotBlank() }?.let { text ->
            val photos = pendingPhotoOnlyContext(messages.take(lastUser + 1)) + messages[lastUser].photos
            val wines = winesForPhotos(photos)
            PendingSend(nextId(), conversationId, text, currentState.selectedWine,
                wines.mapNotNull { wine -> photos.indexOfFirst { it.id == wine.photoId }.takeIf { it >= 0 }
                    ?.let { AssistantPhotoWine(it + 1, wine) } }, photoScansFor(photos, wines), null, comparisonWines())
        } else null
    }

    private fun markUnansweredUserForRetry(conversationId: String) {
        if (currentState.conversationId != conversationId) return
        val messages = currentState.messages
        val lastUser = messages.indexOfLast { message ->
            message.text.isNotBlank() && message.kind in setOf(
                AssistantMessageKind.USER_TEXT, AssistantMessageKind.USER_PHOTOS,
            )
        }
        if (lastUser < 0) return
        val context = messages[lastUser].retryContext
        val after = messages.drop(lastUser + 1)
        if (context != null) {
            if (!context.awaitingReply || after.any { it.kind == AssistantMessageKind.ERROR } ||
                after.any { it.kind == AssistantMessageKind.ASSISTANT_TEXT && it.requestId == context.requestId }) return
        } else if (after.any { it.kind == AssistantMessageKind.ASSISTANT_TEXT || it.kind == AssistantMessageKind.ERROR }) return
        updateState { copy(messages = messages + AssistantMessage(
            id = nextId(), kind = AssistantMessageKind.ERROR,
            errorCode = AssistantUiError.SERVICE_UNAVAILABLE, source = "local_transport",
            requestId = context?.requestId ?: messages[lastUser].requestId,
        )) }
        persistSoon()
    }

    private fun persistSoon(deleteDraftPhotoId: String? = null): Deferred<Boolean>? {
        val snapshot = currentState
        val id = snapshot.conversationId ?: return null
        val remote = remoteSessionId
        val title = snapshot.messages.firstOrNull {
            (it.kind == AssistantMessageKind.USER_TEXT || it.kind == AssistantMessageKind.USER_PHOTOS) && it.text.isNotBlank()
        }
            ?.text?.take(40) ?: snapshot.messages.firstOrNull { it.kind == AssistantMessageKind.WINE_RESULTS }
            ?.wines?.firstOrNull()?.title ?: snapshot.selectedStore?.name.orEmpty()
        val local = AssistantLocalState(
            id = id, title = title, messages = snapshot.messages, draft = snapshot.draft,
            attachments = snapshot.attachments, remoteSessionId = remote,
            selectedWinePhotoId = snapshot.selectedWine?.photoId,
            selectedWineInstanceId = snapshot.selectedWine?.instanceId,
            selectedWineSlug = snapshot.selectedWine?.slug,
            selectedStoreId = snapshot.selectedStore?.id,
        )
        return scope.async {
            try {
                saveMutex.withLock {
                    localRepository.save(local)
                    if (deleteDraftPhotoId != null) localRepository.deleteDraftPhoto(id, deleteDraftPhotoId)
                }
                true
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                updateState { copy(errorCode = AssistantUiError.SESSION_OPEN_FAILED) }
                false
            }
        }
    }

    private fun wineKey(wine: AssistantWine): String = "${wine.photoId.orEmpty()}|${wine.instanceId.orEmpty()}|${wine.slug}"

    override fun onDraftChanged(text: String) {
        if (!conversationReady) return
        ensureLocalConversation()
        updateState { copy(draft = text) }
        persistSoon()
    }

    override fun onPhotoSelectionStarted(): String? =
        if (conversationReady) ensureLocalConversation() else null

    override fun onAttachmentPicked(photoPath: String) {
        if (!conversationReady || photoPath.isBlank()) return
        val conversationId = ensureLocalConversation()
        updateState { copy(pendingAttachments = pendingAttachments + 1) }
        persistSoon()
        val photo = AssistantPhoto(id = nextId(), path = photoPath, name = photoPath.substringAfterLast('/'))
        scope.launch {
            var owned: AssistantPhoto? = null
            try {
                val copied = localRepository.copyPhoto(conversationId, photo)
                owned = copied
                if (currentState.conversationId == conversationId) {
                    updateState { copy(attachments = attachments + copied, errorCode = null) }
                    persistSoon()
                } else {
                    localRepository.deleteDraftPhoto(conversationId, photo.id)
                }
            } catch (e: CancellationException) {
                if (owned != null) withContext(NonCancellable) {
                    localRepository.deleteDraftPhoto(conversationId, photo.id)
                }
                throw e
            } catch (_: Exception) {
                if (currentState.conversationId == conversationId) {
                    updateState { copy(errorCode = AssistantUiError.SCAN_FAILED) }
                }
            } finally {
                if (currentState.conversationId == conversationId) {
                    updateState { copy(pendingAttachments = (pendingAttachments - 1).coerceAtLeast(0)) }
                }
            }
        }
    }

    override fun onRemoveAttachment(id: String) {
        if (!conversationReady) return
        updateState { copy(attachments = attachments.filterNot { it.id == id }) }
        persistSoon(deleteDraftPhotoId = id)
    }

    override fun onSendClicked() {
        val snapshot = currentState
        if (!snapshot.canSend) return
        if ((snapshot.account == null || snapshot.account.expired) && snapshot.draft.isNotBlank()) {
            updateState { copy(accountRequestTicket = accountRequestTicket + 1) }
            return
        }
        pendingStoreIntent = null
        pendingReplacement = null
        pendingReplacementProductId = null
        pendingDinnerSelection = null
        pendingStoreSelection = null
        cancelStoreSearch()
        val text = snapshot.draft.trim()
        val photos = snapshot.attachments
        val message = AssistantMessage(
            id = nextId(), kind = if (photos.isEmpty()) AssistantMessageKind.USER_TEXT else AssistantMessageKind.USER_PHOTOS,
            text = text, photos = photos,
            requestId = if (text.isNotEmpty()) nextId() else null,
        )
        updateState {
            copy(
                messages = messages + message,
                draft = "",
                attachments = emptyList(),
                phase = if (photos.isEmpty()) AssistantPhase.THINKING else AssistantPhase.RECOGNIZING,
                errorCode = null,
            )
        }
        persistSoon()
        val conversationAtStart = currentState.conversationId ?: ensureLocalConversation()
        operation?.cancel()
        operation = scope.launch {
            val recognized = if (photos.isNotEmpty()) recognizePhotos(photos) else emptyList()
            val contextPhotos = if (photos.isNotEmpty()) photos else pendingPhotoOnlyContext(snapshot.messages)
            val contextWines = if (photos.isNotEmpty()) recognized else winesForPhotos(contextPhotos)
            val photoWines = contextWines.mapNotNull { wine ->
                val index = contextPhotos.indexOfFirst { it.id == wine.photoId }
                if (index >= 0) AssistantPhotoWine(index + 1, wine) else null
            }
            if (text.isNotEmpty()) sendText(
                text, conversationAtStart, snapshot.selectedWine, photoWines,
                photoScansFor(contextPhotos, contextWines),
                message.requestId,
            )
            updateState { copy(phase = AssistantPhase.IDLE) }
            persistSoon()
        }
    }

    private suspend fun recognizePhotos(photos: List<AssistantPhoto>): List<AssistantWine> {
        val discovered = mutableListOf<AssistantWine>()
        photos.forEach { photo ->
            val outcome = try { scanRepository.recognize(photo.path, null) }
            catch (e: CancellationException) { throw e }
            catch (_: Exception) {
                updateState { copy(messages = messages + AssistantMessage(
                    id = nextId(), kind = AssistantMessageKind.ERROR,
                    errorCode = AssistantUiError.SCAN_FAILED, photos = listOf(photo),
                )) }
                persistSoon()
                return@forEach
            }
            when (outcome) {
                is ScanOutcome.Recognized -> {
                    val wineCards = outcome.view.bottles.mapNotNull { bottle ->
                        bottle.best?.toAssistantWine(photo, bottle.instanceId, bottle.decision != "matched",
                            outcome.view.cropOf(bottle), outcome.view.frame)
                    }.ifEmpty {
                        listOfNotNull(outcome.view.publishedCard?.toAssistantWine(photo, null, true,
                            outcome.view.roiBox, outcome.view.frame))
                    }
                    var sourceScanId: Long? = null
                    try {
                        sourceScanId = historyRepository.saveCopy(photo.path, outcome.view)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (_: Exception) {
                        // Keep the assistant result even if the legacy scan history is full.
                    }
                    val result = AssistantMessage(
                        id = nextId(),
                        kind = if (wineCards.isEmpty()) AssistantMessageKind.ERROR else AssistantMessageKind.WINE_RESULTS,
                        errorCode = if (wineCards.isEmpty()) AssistantUiError.WINE_UNKNOWN else null,
                        photos = if (wineCards.isEmpty()) listOf(photo) else emptyList(),
                        wines = wineCards.map { it.copy(sourceScanId = sourceScanId) },
                        source = "scanner",
                    )
                    discovered += result.wines
                    updateState { copy(messages = messages + result) }
                    persistSoon()
                }
                is ScanOutcome.Failed -> {
                    updateState {
                        copy(
                            messages = messages + AssistantMessage(
                                id = nextId(), kind = AssistantMessageKind.ERROR,
                                errorCode = AssistantUiError.SCAN_FAILED,
                                photos = listOf(photo),
                            ),
                        )
                    }
                    persistSoon()
                }
            }
        }
        currentState.conversationId?.let(::hydrateConversationWines)
        if (discovered.size == 1 && !discovered.single().uncertain && currentState.selectedWine == null) {
            updateState { copy(selectedWine = discovered.single()) }
            persistSoon()
        }
        return discovered
    }

    private fun pendingPhotoOnlyContext(messages: List<AssistantMessage>): List<AssistantPhoto> {
        val lastSentText = messages.indexOfLast { message ->
            message.text.isNotBlank() && message.kind in setOf(
                AssistantMessageKind.USER_TEXT, AssistantMessageKind.USER_PHOTOS,
            )
        }
        return messages.drop(lastSentText + 1).asSequence().filter {
            it.kind == AssistantMessageKind.USER_PHOTOS && it.text.isBlank()
        }.flatMap { it.photos.asSequence() }.toList().takeLast(10)
    }

    private fun winesForPhotos(photos: List<AssistantPhoto>): List<AssistantWine> {
        val ids = photos.map { it.id }.toSet()
        return currentState.messages.asSequence().filter {
            it.kind == AssistantMessageKind.WINE_RESULTS
        }.flatMap { it.wines.asSequence() }.filter { it.photoId in ids }
            .distinctBy { Triple(it.photoId, it.instanceId, it.slug) }.toList()
    }

    private fun photoScansFor(photos: List<AssistantPhoto>, wines: List<AssistantWine>): List<AssistantPhotoScan> =
        photos.mapIndexed { index, photo ->
            val status = when {
                wines.any { it.photoId == photo.id } -> AssistantPhotoScanStatus.FOUND
                currentState.messages.any { message ->
                    message.kind == AssistantMessageKind.ERROR &&
                        message.errorCode == AssistantUiError.SCAN_FAILED &&
                        message.photos.any { it.id == photo.id }
                } -> AssistantPhotoScanStatus.SCAN_FAILED
                else -> AssistantPhotoScanStatus.UNKNOWN
            }
            AssistantPhotoScan(index + 1, status)
        }

    private suspend fun sendText(text: String, localConversationId: String,
        wineForMessage: AssistantWine?, photoWines: List<AssistantPhotoWine> = emptyList(),
        photoScans: List<AssistantPhotoScan> = emptyList(), requestedId: String? = null) {
        updateState { copy(phase = AssistantPhase.THINKING) }
        try {
            val id = remoteSessionId ?: service.createConversation().also {
                remoteSessionId = it
                persistSoon()
            }
            val idempotencyId = requestedId ?: nextId()
            val request = pendingSend?.takeIf {
                it.localConversationId == localConversationId && it.requestId == idempotencyId
            } ?: PendingSend(idempotencyId, localConversationId, text, wineForMessage, photoWines,
                    photoScans, currentState.selectedStore?.id, comparisonWines())
                    .also { pendingSend = it }
            val userIndex = currentState.messages.indexOfLast {
                it.kind in setOf(AssistantMessageKind.USER_TEXT, AssistantMessageKind.USER_PHOTOS) && it.text == text
            }
            if (userIndex >= 0) {
                val durable = AssistantRequestContext(request.requestId, request.wine?.copy(photoPath = null),
                    request.photoWines.map { it.copy(wine = it.wine.copy(photoPath = null)) },
                    request.photoScans, request.storeId, request.comparisonWines.map { it.copy(photoPath = null) })
                updateState { copy(messages = messages.mapIndexed { index, message ->
                    if (index == userIndex) message.copy(retryContext = durable) else message
                }) }
                check(persistSoon()?.await() == true) { "Request context could not be saved" }
            }
            if (currentState.conversationId != localConversationId) return
            val reply = service.send(
                conversationId = id,
                requestId = request.requestId,
                text = text,
                selectedWine = request.wine,
                photoWines = request.photoWines,
                photoScans = request.photoScans,
                storeId = request.storeId,
                comparisonWines = request.comparisonWines,
            )
            absorbStores(reply)
            updateState {
                copy(
                    messages = mergeMessages(withoutCompletedTransportErrors(messages, setOf(request.requestId)).map { message ->
                        if (message.retryContext?.requestId == request.requestId)
                            message.copy(retryContext = message.retryContext?.copy(awaitingReply = false)) else message
                    }, reply),
                )
            }
            pendingStoreIntent = if (reply.any { it.kind == AssistantMessageKind.LOCATION_REQUEST })
                request else null
            // A server-side unavailable event is a completed request, so replaying its
            // request ID would return the same failure. Retry must make a new attempt.
            pendingSend = if (reply.any { it.kind == AssistantMessageKind.ERROR }) {
                request.copy(requestId = nextId(), storeId = currentState.selectedStore?.id)
            } else null
            persistSoon()
        } catch (e: CancellationException) {
            throw e
        } catch (_: com.aiweapps.winescan.domain.assistant.repository.AssistantStoreContextChanged) {
            pendingStoreIntent = pendingSend
            val requestId = pendingStoreIntent?.requestId
            pendingSend = null
            val currentRemote = remoteSessionId
            val refreshed = if (currentRemote != null) try { service.messages(currentRemote) }
                catch (e: CancellationException) { throw e }
                catch (_: Exception) { emptyList() } else emptyList()
            absorbStores(refreshed)
            updateState { copy(selectedStore = null, messages = messages + AssistantMessage(nextId(),
                AssistantMessageKind.LOCATION_REQUEST, text = "store_context_changed", requestId = requestId), errorCode = null) }
            persistSoon()
        } catch (_: Exception) {
            updateState {
                copy(messages = messages.dropLastWhile { it.kind == AssistantMessageKind.ERROR &&
                    it.source == "local_transport" } + AssistantMessage(
                    id = nextId(), kind = AssistantMessageKind.ERROR,
                    errorCode = AssistantUiError.SERVICE_UNAVAILABLE, source = "local_transport",
                    requestId = pendingSend?.requestId ?: requestedId,
                ), errorCode = null)
            }
            persistSoon()
        }
    }

    override fun onNewConversationClicked() {
        if (!conversationReady) {
            pendingComparisonImport = null
            return
        }
        cancelCompareOperation()
        wineMetadataJob?.cancel()
        wineMetadataRevision += 1
        operation?.cancel()
        retailOperation?.cancel()
        hasInteracted = true
        remoteSessionId = null
        pendingSend = null
        pendingStoreIntent = null
        pendingReplacement = null
        pendingReplacementProductId = null
        pendingDinnerSelection = null
        pendingStoreSelection = null
        cancelStoreSearch()
        updateState { AssistantState(
            account = account, legacyHistory = legacyHistory,
            conversationId = newConversationId(), conversations = conversations,
            savedWines = this@DefaultAssistantComponent.savedWines.values.toList(),
            compareSlugs = comparedSlugs,
            referenceAccess = referenceAccess,
        ) }
    }

    override fun onConversationSelected(id: String) {
        if (!conversationReady) return
        cancelCompareOperation()
        wineMetadataJob?.cancel()
        wineMetadataRevision += 1
        operation?.cancel()
        retailOperation?.cancel()
        hasInteracted = true
        pendingSend = null
        pendingStoreIntent = null
        pendingReplacement = null
        pendingReplacementProductId = null
        pendingDinnerSelection = null
        pendingStoreSelection = null
        cancelStoreSearch()
        operation = scope.launch {
            try {
                saveMutex.withLock { /* Wait for queued saves before loading this conversation. */ }
                val local = localRepository.load(id)
                if (local != null) restore(local)
                else updateState { copy(errorCode = AssistantUiError.SESSION_OPEN_FAILED) }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                updateState { copy(errorCode = AssistantUiError.SESSION_OPEN_FAILED) }
            }
        }
    }

    override fun onComparisonRequested(wines: List<WineCard>, prompt: String) {
        val cards = wines.distinctBy { it.slug }.take(3)
        if (cards.isEmpty()) return
        if (!conversationReady) {
            pendingComparisonImport = PendingComparisonImport(cards, prompt)
            return
        }
        // A separate conversation preserves the existing draft, photo attachments and history.
        persistSoon()
        onNewConversationClicked()
        val imported = cards.map { card ->
            AssistantWine(card.slug, card.presentationTitle, card.producer, card.region, card.category,
                card.pairings.orEmpty(), card.reference, card.catalogueUrl,
                null, null, null, true, card.description, card.dishes)
        }
        updateState { copy(
            messages = listOf(AssistantMessage(nextId(), AssistantMessageKind.WINE_RESULTS,
                wines = imported, comparisonContext = true)),
            selectedWine = imported.singleOrNull(),
            draft = prompt,
        ) }
        persistSoon()
        hydrateConversationWines(currentState.conversationId, importedFromCurrentComparison = true)
    }

    private fun hydrateConversationWines(conversationId: String?, importedFromCurrentComparison: Boolean = false) {
        wineMetadataJob?.cancel()
        val revision = ++wineMetadataRevision
        val subject = currentState.account?.subject
        // Current selection and the latest visible conversation results precede old
        // history and favourites. Publish each ready card without waiting for the rest.
        val wines = (listOfNotNull(currentState.selectedWine) +
            currentState.messages.asReversed().flatMap { it.wines } + savedWines.values).distinctBy { it.slug }
        if (wines.isEmpty()) return
        wineMetadataJob = scope.launch {
            if (importedFromCurrentComparison) {
                // Capture the current set before any credentials/catalogue network wait.
                hydrateComparisonPhotos(conversationId, revision, subject)
            }
            try {
                // Initialization can run offline. Revisit the current guest credentials
                // when real wine content is opened, without replacing a usable access on failure.
                val access = scanRepository.referenceAccess()
                if (wineMetadataRevision != revision || currentState.conversationId != conversationId ||
                    currentState.account?.subject != subject) return@launch
                if (access != null) updateState { copy(referenceAccess = access) }
            } catch (error: CancellationException) { throw error }
            catch (_: Exception) { /* Private local photos remain available offline. */ }
            for (wine in wines) {
                val card = catalog.enrich(WineCard(slug = wine.slug, title = wine.title,
                    producer = wine.producer, region = wine.region, category = wine.category,
                    foodPairings = wine.foodPairings, reference = wine.reference, pageUrl = wine.pageUrl,
                    description = wine.description, dishes = wine.dishes))
                if (wineMetadataRevision != revision || currentState.conversationId != conversationId ||
                    currentState.account?.subject != subject) return@launch
                fun AssistantWine.withMetadata(): AssistantWine {
                    if (slug != card.slug) return this
                    return copy(producer = card.producer, region = card.region, category = card.category,
                        title = card.presentationTitle, foodPairings = card.pairings.orEmpty(),
                        reference = card.reference, pageUrl = card.catalogueUrl,
                        description = card.description, dishes = card.dishes)
                }
                savedWines.keys.toList().forEach { key ->
                    savedWines[key]?.let { savedWines[key] = it.withMetadata() }
                }
                updateState { copy(
                    savedWines = this@DefaultAssistantComponent.savedWines.values.toList(),
                    messages = messages.map { message -> message.copy(wines = message.wines.map { it.withMetadata() }) },
                    selectedWine = selectedWine?.withMetadata(),
                ) }
            }
        }
    }

    /** Comparison owns its own files; the chat needs its own durable copy before removal of that set. */
    private suspend fun hydrateComparisonPhotos(conversationId: String?, revision: Long, subject: String?) {
        if (conversationId == null) return
        val imported = currentState.messages.filter { it.comparisonContext }.flatMap { it.wines }
            .filter { it.photoPath == null }.distinctBy { it.slug }
        if (imported.isEmpty()) return
        val entries = try { compareRepository.watch().first().associateBy { it.slug } }
        catch (error: CancellationException) { throw error }
        catch (_: Exception) { return }
        fun isCurrent() = wineMetadataRevision == revision && currentState.conversationId == conversationId &&
            currentState.account?.subject == subject
        for (wine in imported) {
            if (!isCurrent()) return
            val entry = entries[wine.slug] ?: continue
            val sourcePath = entry.photoPath ?: continue
            val source = AssistantPhoto(nextId(), sourcePath, sourcePath.substringAfterLast('/'))
            var published = false
            try {
                val photo = localRepository.copyPhoto(conversationId, source)
                if (!isCurrent()) {
                    localRepository.deleteDraftPhoto(conversationId, photo.id)
                    return
                }
                fun AssistantWine.withPhoto(): AssistantWine = if (slug == wine.slug && photoPath == null) {
                    copy(photoId = photo.id, photoPath = photo.path, sourceCrop = entry.crop, sourceFrame = entry.frame)
                } else this
                updateState { copy(
                    messages = messages.map { message -> if (message.comparisonContext) {
                        message.copy(wines = message.wines.map { it.withPhoto() })
                    } else message },
                    selectedWine = selectedWine?.withPhoto(),
                ) }
                published = true
                // Persist the same photo identity and source geometry that were just published.
                persistSoon()
            } catch (error: CancellationException) {
                withContext(NonCancellable) {
                    if (!published) localRepository.deleteDraftPhoto(conversationId, source.id)
                }
                throw error
            } catch (_: Exception) {
                // An unavailable source photo must not block reference images or metadata.
                if (!published) localRepository.deleteDraftPhoto(conversationId, source.id)
            }
        }
    }

    private fun comparisonWines(): List<AssistantWine> = currentState.messages
        .lastOrNull { it.comparisonContext }?.wines.orEmpty().distinctBy { it.slug }.take(3)

    override fun onWineSelected(slug: String) {
        onWineInstanceSelected(null, null, slug)
    }

    override fun onWineInstanceSelected(photoId: String?, instanceId: String?, slug: String) {
        if (!conversationReady) return
        val wine = currentState.messages.asReversed().asSequence().flatMap { it.wines.asSequence() }
            .firstOrNull { it.slug == slug && (photoId == null || it.photoId == photoId) &&
                (instanceId == null || it.instanceId == instanceId) }
            ?: savedWines.values.firstOrNull { it.slug == slug && (photoId == null || it.photoId == photoId) &&
                (instanceId == null || it.instanceId == instanceId) } ?: return
        ensureLocalConversation()
        updateState { copy(selectedWine = wine) }
        hydrateConversationWines(currentState.conversationId)
        persistSoon()
    }

    override fun onWineDinnerRequested(photoId: String?, instanceId: String?, slug: String, prompt: String) {
        if (!conversationReady || currentState.phase != AssistantPhase.IDLE || prompt.isBlank()) return
        if (currentState.account == null || currentState.account?.expired == true) {
            updateState { copy(accountRequestTicket = accountRequestTicket + 1) }
            return
        }
        onWineInstanceSelected(photoId, instanceId, slug)
        val wine = currentState.selectedWine?.takeIf { it.slug == slug } ?: return
        val localId = ensureLocalConversation()
        val requestId = nextId()
        pendingStoreIntent = null
        pendingReplacement = null
        pendingReplacementProductId = null
        pendingDinnerSelection = null
        pendingStoreSelection = null
        cancelStoreSearch()
        updateState { copy(messages = messages + AssistantMessage(nextId(),
            AssistantMessageKind.USER_TEXT, text = prompt, requestId = requestId),
            phase = AssistantPhase.THINKING, errorCode = null) }
        persistSoon()
        operation?.cancel()
        operation = scope.launch {
            sendText(prompt, localId, wine, requestedId = requestId)
            if (currentState.conversationId == localId) updateState { copy(phase = AssistantPhase.IDLE) }
            persistSoon()
        }
    }

    override fun onWineInstanceCompareClicked(photoId: String?, instanceId: String?, slug: String) {
        if (currentState.compareBusyKey != null) return
        val wine = (currentState.messages.asReversed().flatMap { it.wines } + savedWines.values)
            .firstOrNull { it.slug == slug && (photoId == null || it.photoId == photoId) &&
                (instanceId == null || it.instanceId == instanceId) }
        if (wine == null) {
            updateState { copy(compareNotice = AssistantCompareNotice.SOURCE_UNAVAILABLE) }
            return
        }
        if (slug in comparedSlugs) {
            onOpenCompare(AddToCompareResult.ALREADY_THERE)
            return
        }
        val conversation = currentState.conversationId
        val subject = currentState.account?.subject
        val revision = ++compareRevision
        updateState { copy(compareBusyKey = wineKey(wine), compareNotice = null) }
        compareJob = scope.launch {
            try {
                val card = catalog.enrich(WineCard(
                    slug = wine.slug, title = wine.title, producer = wine.producer,
                    category = wine.category, region = wine.region, reference = wine.reference,
                    pageUrl = wine.pageUrl, foodPairings = wine.foodPairings,
                    description = wine.description, dishes = wine.dishes,
                ))
                if (compareRevision != revision || currentState.conversationId != conversation ||
                    currentState.account?.subject != subject) return@launch
                val photoPath = wine.photoPath?.takeIf { it.isNotBlank() }
                if (photoPath == null && card.reference.isNullOrBlank()) {
                    updateState { copy(compareNotice = AssistantCompareNotice.SOURCE_UNAVAILABLE) }
                    return@launch
                }
                val result = compareRepository.add(CompareCandidate(
                    card = card, photoPath = photoPath,
                    crop = wine.sourceCrop, frame = wine.sourceFrame, scanId = wine.sourceScanId,
                ))
                if (compareRevision == revision && currentState.conversationId == conversation &&
                    currentState.account?.subject == subject) onOpenCompare(result)
            } catch (error: CancellationException) { throw error }
            catch (_: Exception) {
                if (compareRevision == revision && currentState.conversationId == conversation &&
                    currentState.account?.subject == subject) {
                    updateState { copy(compareNotice = AssistantCompareNotice.FAILED) }
                }
            } finally {
                if (compareRevision == revision) updateState { copy(compareBusyKey = null) }
            }
        }
    }

    override fun onCompareNoticeConsumed() {
        updateState { copy(compareNotice = null) }
    }

    private fun cancelCompareOperation() {
        compareJob?.cancel()
        compareRevision += 1
        updateState { copy(compareBusyKey = null, compareNotice = null) }
    }

    override fun onWineFavoriteClicked(slug: String) {
        onWineInstanceFavoriteClicked(null, null, slug)
    }

    private fun applySavedWines(subject: String?, wines: List<AssistantWine>) {
        if (subject != accounts.account.value?.subject || subject != currentState.account?.subject) return
        val merged = wines.associateBy(::wineKey)
            .mapValues { (key, wine) -> savedWines[key] ?: wine }.toMutableMap()
        // A preceding commit must not undo a later optimistic tap that is still queued.
        pendingFavorites.filterValues { it.subject == subject }.forEach { (key, change) ->
            if (change.adding) merged[key] = change.wine else merged.remove(key)
        }
        savedWines.clear()
        savedWines.putAll(merged)
        updateState { copy(savedWines = this@DefaultAssistantComponent.savedWines.values.toList()) }
    }

    override fun onWineInstanceFavoriteClicked(photoId: String?, instanceId: String?, slug: String) {
        val subject = accounts.account.value?.subject
        if (!conversationReady || currentState.account?.subject != subject) return
        val wine = currentState.messages.asReversed().asSequence().flatMap { it.wines.asSequence() }
            .firstOrNull { it.slug == slug && (photoId == null || it.photoId == photoId) &&
                (instanceId == null || it.instanceId == instanceId) } ?: return
        val key = wineKey(wine)
        val adding = !savedWines.containsKey(key)
        val revision = ++favoriteRevision
        pendingFavorites[key] = PendingFavorite(revision, subject, wine, adding)
        if (adding) savedWines[key] = wine else savedWines.remove(key)
        updateState { copy(savedWines = this@DefaultAssistantComponent.savedWines.values.toList()) }
        val job = scope.launch(start = CoroutineStart.LAZY) {
            // Applied to what is stored, not to this screen's copy: the history may have
            // changed «My wines» since.
            var committed: List<AssistantWine>? = null
            try {
                committed = localRepository.updateSavedWines(subject) { stored ->
                    val others = stored.filterNot { wineKey(it) == key }
                    if (adding) others + wine else others
                }
            }
            catch (e: CancellationException) { throw e }
            catch (_: Exception) {
                if (accounts.account.value?.subject == subject && currentState.account?.subject == subject) {
                    updateState { copy(errorCode = AssistantUiError.SESSION_OPEN_FAILED) }
                    committed = try { localRepository.loadSavedWines() }
                    catch (e: CancellationException) { throw e }
                    catch (_: Exception) { null }
                }
            } finally {
                if (pendingFavorites[key]?.revision == revision) pendingFavorites.remove(key)
                committed?.let { applySavedWines(subject, it) }
                coroutineContext[Job]?.let { favoriteJobs.remove(it) }
            }
        }
        favoriteJobs.add(job)
        job.start()
    }

    override fun onLocationCardRequested() {
        if (!conversationReady) return
        ensureLocalConversation()
        updateState { copy(messages = messages + AssistantMessage(nextId(), AssistantMessageKind.LOCATION_REQUEST)) }
        persistSoon()
    }

    override fun onLocationRequested() {
        if (!conversationReady) return
        updateState { copy(locationRequestTicket = locationRequestTicket + 1) }
    }

    override fun onLocationResolved(latitude: Double, longitude: Double, address: String) {
        if (!conversationReady) return
        updateState { copy(location = AssistantLocation(address, AssistantLocationSource.GPS, latitude, longitude)) }
        findStores(StoreSearchQuery.Coordinates(latitude, longitude))
    }

    override fun onAddressEntered(address: String) {
        if (!conversationReady) return
        if (address.isBlank()) return
        updateState { copy(location = AssistantLocation(address.trim(), AssistantLocationSource.MANUAL)) }
        findStores(StoreSearchQuery.Address(address.trim()))
    }

    private fun cancelStoreSearch() {
        if (pendingStoreSearch != null) retailOperation?.cancel()
        storeSearchRevision += 1
        pendingStoreSearch = null
    }

    private fun findStores(query: StoreSearchQuery) {
        if (currentState.account == null || currentState.account?.expired == true) {
            updateState { copy(accountRequestTicket = accountRequestTicket + 1) }
            return
        }
        val localId = ensureLocalConversation()
        cancelStoreSearch()
        val request = PendingStoreSearch(localId, currentState.account?.subject, storeSearchRevision, query)
        pendingStoreSearch = request
        pendingStoreSelection = null
        fun isCurrent() = pendingStoreSearch == request && storeSearchRevision == request.revision &&
            currentState.conversationId == request.localConversationId &&
            currentState.account?.subject == request.subject && accounts.account.value?.subject == request.subject
        retailOperation?.cancel()
        updateState { copy(phase = AssistantPhase.SEARCHING_STORE, errorCode = null) }
        retailOperation = scope.launch {
            try {
                val stores = when (val search = request.query) {
                    is StoreSearchQuery.Address -> service.searchStores(search.value)
                    is StoreSearchQuery.Coordinates -> service.nearbyStores(search.latitude, search.longitude)
                }
                coroutineContext.ensureActive()
                if (!isCurrent()) return@launch
                pendingStoreSearch = null
                updateState { copy(availableStores = stores, suggestedStore = stores.firstOrNull(),
                    messages = messages + AssistantMessage(nextId(), AssistantMessageKind.STORE_CANDIDATES, stores = stores),
                    phase = AssistantPhase.IDLE) }
                persistSoon()
            } catch (e: CancellationException) { throw e }
            catch (_: Exception) {
                coroutineContext.ensureActive()
                if (isCurrent()) updateState { copy(phase = AssistantPhase.IDLE, errorCode = AssistantUiError.STORE_UNAVAILABLE) }
            }
        }
    }

    private fun absorbStores(messages: List<AssistantMessage>) {
        val stores = messages.flatMap { it.stores }
        val control = messages.lastOrNull { it.kind in setOf(AssistantMessageKind.STORE_SELECTED,
            AssistantMessageKind.STORE_CANDIDATES, AssistantMessageKind.LOCATION_REQUEST) }
        val incoming = control?.takeIf { it.kind == AssistantMessageKind.STORE_SELECTED }?.stores?.firstOrNull()
        val needsConfirmation = control?.kind in setOf(AssistantMessageKind.STORE_CANDIDATES, AssistantMessageKind.LOCATION_REQUEST)
        val now = kotlin.time.Clock.System.now()
        val current = currentState.selectedStore
        var selected = when {
            needsConfirmation -> null
            incoming == null -> current
            incoming.id == current?.id -> incoming.copy(selectedAt = current.selectedAt ?: incoming.selectedAt ?: now.toString(),
                checkedAt = current.checkedAt.takeIf { current.selectedAt != null })
            else -> incoming.copy(selectedAt = incoming.selectedAt ?: now.toString(), checkedAt = null)
        }
        selected?.let { store ->
            val boundary = store.selectedAt?.let { runCatching { kotlin.time.Instant.parse(it) }.getOrNull() }
            val checked = messages.asSequence().filter { message ->
                message.source == "live_catalog" && message.retailStoreId == store.id &&
                    message.kind in setOf(AssistantMessageKind.PRODUCTS, AssistantMessageKind.DINNER_OPTIONS) &&
                    message.products.isNotEmpty()
            }.mapNotNull { it.checkedAt?.let { text -> runCatching { kotlin.time.Instant.parse(text) }.getOrNull() } }
                .filter { boundary != null && it >= boundary && it <= now }
                .maxOrNull()
            val previous = store.checkedAt?.let { runCatching { kotlin.time.Instant.parse(it) }.getOrNull() }
            if (checked != null && (previous == null || checked > previous)) selected = store.copy(checkedAt = checked.toString())
        }
        updateState { copy(availableStores = (availableStores + stores).distinctBy { it.id }, selectedStore = selected) }
    }

    override fun onStoreSelected(storeId: Int) {
        if (!conversationReady || currentState.availableStores.none { it.id == storeId }) return
        if (currentState.account == null || currentState.account?.expired == true) {
            updateState { copy(accountRequestTicket = accountRequestTicket + 1) }
            return
        }
        cancelStoreSearch()
        val request = PendingStoreSelection(ensureLocalConversation(), currentState.account?.subject,
            storeId, nextId(), kotlin.time.Clock.System.now().toString())
        pendingStoreSelection = request
        selectStore(request)
    }

    private fun selectStore(request: PendingStoreSelection) {
        val localId = request.localConversationId
        fun isCurrent() = currentState.conversationId == localId &&
            currentState.account?.subject == request.subject && pendingStoreSelection == request
        if (!isCurrent()) return
        if (currentState.account == null || currentState.account?.expired == true) {
            updateState { copy(accountRequestTicket = accountRequestTicket + 1) }
            return
        }
        val store = currentState.availableStores.firstOrNull { it.id == request.storeId }?.copy(
            checkedAt = null, selectedAt = request.selectedAt) ?: return
        retailOperation?.cancel()
        updateState { copy(selectedStore = null, phase = AssistantPhase.SEARCHING_STORE, errorCode = null) }
        retailOperation = scope.launch {
            try {
                val remote = remoteSessionId ?: service.createConversation().also {
                    if (!isCurrent()) return@launch
                    remoteSessionId = it
                }
                if (!isCurrent()) return@launch
                val reply = service.confirmStore(remote, request.requestId, request.storeId).map { message ->
                    if (message.kind == AssistantMessageKind.STORE_SELECTED) message.copy(stores = message.stores.map {
                        it.copy(checkedAt = null, selectedAt = store.selectedAt)
                    }) else message
                }
                if (!isCurrent()) return@launch
                absorbStores(reply)
                updateState { copy(selectedStore = store,
                    messages = messages + reply.filter { incoming -> messages.none { it.id == incoming.id } }) }
                // User confirmation does not claim a successful retailer read.
                retailGateway.configureStore(store)
                val verified = retailGateway.selectStore(request.storeId)
                if (!isCurrent()) return@launch
                if (verified is RetailResult.Success) {
                    updateState { copy(selectedStore = verified.store.copy(selectedAt = store.selectedAt),
                        messages = messages + AssistantMessage(nextId(), AssistantMessageKind.STORE_SELECTED,
                            stores = listOf(verified.store.copy(selectedAt = store.selectedAt)), storeVerified = verified.storeVerified, checkedAt = verified.store.checkedAt)) }
                } else if (verified is RetailResult.Unavailable && verified.reason == RetailUnavailableReason.ACCESS_REQUIRED) {
                    updateState { copy(errorCode = AssistantUiError.RETAIL_ACCESS_REQUIRED) }
                }
                if (!isCurrent()) return@launch
                pendingStoreSelection = null
                val intent = pendingStoreIntent?.takeIf { it.localConversationId == localId }
                if (intent != null) {
                    pendingStoreIntent = null
                    // No duplicate user bubble and no draft reset: only the confirmed
                    // missing store is added to the original authorized request.
                    pendingSend = null
                    sendText(intent.text, localId, intent.wine, intent.photoWines,
                        intent.photoScans)
                }
                if (currentState.conversationId == localId) updateState { copy(phase = AssistantPhase.IDLE) }
                persistSoon()
            } catch (e: CancellationException) { throw e }
            catch (_: Exception) {
                if (isCurrent()) updateState { copy(phase = AssistantPhase.IDLE, errorCode = AssistantUiError.STORE_UNAVAILABLE) }
            }
        }
    }

    override fun onSearchProductsRequested(query: String) {
        if (!conversationReady) return
        val store = currentState.selectedStore ?: return
        val cleaned = query.trim().take(100)
        if (cleaned.isEmpty()) return
        cancelStoreSearch()
        ensureLocalConversation()
        retailOperation?.cancel()
        updateState { copy(phase = AssistantPhase.SEARCHING_STORE, errorCode = null) }
        retailOperation = scope.launch {
            when (val result = retailGateway.searchProducts(cleaned, store.id)) {
                is RetailResult.Success -> updateState {
                    copy(
                        selectedStore = result.store,
                        phase = AssistantPhase.IDLE,
                        messages = messages + AssistantMessage(
                            id = nextId(), kind = AssistantMessageKind.PRODUCTS,
                            products = result.products,
                            source = if (result.storeVerified) "live_catalog" else "session_context",
                            checkedAt = result.store.checkedAt,
                            retailStoreId = result.store.id,
                        ),
                    )
                }
                is RetailResult.Unavailable -> updateState {
                    copy(phase = AssistantPhase.IDLE, errorCode = if (result.reason == RetailUnavailableReason.ACCESS_REQUIRED)
                        AssistantUiError.RETAIL_ACCESS_REQUIRED else AssistantUiError.RETAIL_SEARCH_FAILED)
                }
            }
            persistSoon()
        }
    }

    override fun onDinnerSelected(id: String) {
        if (currentState.phase != AssistantPhase.IDLE) return
        val source = currentState.messages.firstOrNull { message -> message.dinners.any { it.id == id } } ?: return
        val dinner = source.dinners.first { it.id == id }
        if (dinner.remoteOptionId != null) {
            val remoteId = remoteSessionId ?: return
            val localId = currentState.conversationId ?: return
            val sourceId = source.sourceMessageId ?: return
            val latestChoice = currentState.messages.asReversed().firstOrNull {
                it.selectedDinnerOptionId != null
            }?.selectedDinnerOptionId
            if (latestChoice == dinner.remoteOptionId) return
            val request = PendingDinnerSelection(localId, sourceId, dinner.remoteOptionId, nextId())
            pendingDinnerSelection = request
            selectDinner(remoteId, request)
            return
        }
        updateState {
            copy(messages = messages + AssistantMessage(
                id = nextId(), kind = AssistantMessageKind.PRODUCTS,
                text = dinner.title, products = dinner.products, totalKopeks = dinner.totalKopeks,
                sourceMessageId = source.sourceMessageId, source = source.source,
                checkedAt = source.checkedAt,
            ))
        }
        persistSoon()
    }

    private fun selectDinner(remoteId: String, request: PendingDinnerSelection) {
        cancelStoreSearch()
        retailOperation?.cancel()
        updateState { copy(phase = AssistantPhase.SELECTING_DINNER, errorCode = null) }
        retailOperation = scope.launch {
            try {
                val selected = service.selectDinner(
                    remoteId, request.sourceMessageId, request.requestId, request.optionId,
                )
                if (currentState.conversationId != request.localConversationId) return@launch
                absorbStores(selected)
                updateState { copy(messages = messages + selected, phase = AssistantPhase.IDLE) }
                pendingDinnerSelection = null
                persistSoon()
            } catch (e: CancellationException) {
                throw e
            } catch (_: AssistantDinnerSelectionStale) {
                if (currentState.conversationId == request.localConversationId) {
                    pendingDinnerSelection = null
                    updateState { copy(phase = AssistantPhase.IDLE, errorCode = AssistantUiError.DINNER_SELECTION_STALE) }
                }
            } catch (_: Exception) {
                if (currentState.conversationId == request.localConversationId) {
                    updateState { copy(phase = AssistantPhase.IDLE, errorCode = AssistantUiError.DINNER_SELECTION_UNAVAILABLE) }
                }
            }
        }
    }

    override fun onProductReplacementRequested(productId: String) {
        currentState.activeBasketMessageId?.let { onProductReplacementRequestedFrom(it, productId) }
    }

    override fun onProductReplacementRequestedFrom(messageId: String, productId: String) {
        if (currentState.phase != AssistantPhase.IDLE) return
        val source = currentState.messages.firstOrNull { it.id == messageId && it.id == currentState.activeBasketMessageId &&
            it.products.any { product -> product.id == productId } } ?: run {
            updateState { copy(errorCode = AssistantUiError.REPLACEMENT_UNAVAILABLE) }
            return
        }
        val remoteId = remoteSessionId ?: run {
            updateState { copy(errorCode = AssistantUiError.REPLACEMENT_UNAVAILABLE) }
            return
        }
        val product = source.products.first { it.id == productId }
        val rawSourceId = source.sourceMessageId ?: return
        pendingReplacementProductId = productId
        val replacementQuery = product.title.trim().substringBefore(' ').substringBefore(',').take(40)
        if (replacementQuery.isBlank()) return
        cancelStoreSearch()
        retailOperation?.cancel()
        updateState { copy(phase = AssistantPhase.SEARCHING_STORE, errorCode = null) }
        retailOperation = scope.launch {
            try {
                val batch = service.replacementCandidates(remoteId, rawSourceId, replacementQuery)
                val candidates = batch.products.filterNot { it.id == productId }
                if (candidates.isEmpty()) {
                    updateState { copy(phase = AssistantPhase.IDLE, errorCode = AssistantUiError.REPLACEMENT_UNAVAILABLE) }
                } else {
                    pendingReplacementProductId = null
                    updateState { copy(
                        phase = AssistantPhase.IDLE,
                        messages = messages + AssistantMessage(
                            id = nextId(), kind = AssistantMessageKind.PRODUCTS,
                            text = product.title, products = candidates, source = batch.source,
                            checkedAt = batch.checkedAt, retailStoreId = batch.storeId,
                            sourceMessageId = rawSourceId, replacementForProductId = productId,
                        ),
                    ) }
                    persistSoon()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (_: com.aiweapps.winescan.domain.assistant.repository.AssistantRetailAccessRequired) {
                updateState { copy(phase = AssistantPhase.IDLE, errorCode = AssistantUiError.RETAIL_ACCESS_REQUIRED) }
            } catch (_: Exception) {
                updateState { copy(phase = AssistantPhase.IDLE, errorCode = AssistantUiError.REPLACEMENT_UNAVAILABLE) }
            }
        }
    }

    override fun onReplacementCandidateSelected(productId: String) {
        val matches = currentState.messages.filter { it.replacementForProductId != null &&
            it.products.any { product -> product.id == productId } }
        val candidates = matches.singleOrNull() ?: return
        onReplacementCandidateChosen(candidates.id, candidates.replacementForProductId ?: return, productId)
    }

    override fun onReplacementCandidateChosen(messageId: String, originalProductId: String, productId: String) {
        if (currentState.phase != AssistantPhase.IDLE) return
        val candidates = currentState.messages.firstOrNull { it.id == messageId &&
            it.replacementForProductId == originalProductId && it.products.any { product -> product.id == productId } }
            ?: return
        if (currentState.activeReplacementMessageId != messageId) {
            updateState { copy(errorCode = AssistantUiError.REPLACEMENT_UNAVAILABLE) }
            return
        }
        val sourceMessageId = candidates.sourceMessageId ?: return
        val oldProductId = candidates.replacementForProductId ?: return
        val source = currentState.messages.asReversed().firstOrNull { it.sourceMessageId == sourceMessageId && it.replacementForProductId == null }
            ?: return
        val packages = source.products.firstOrNull { it.id == oldProductId }?.quantity ?: return
        val remoteId = remoteSessionId ?: return
        val request = PendingReplacement(sourceMessageId, oldProductId, productId, packages, nextId())
        pendingReplacement = request
        replaceProduct(remoteId, request)
    }

    private fun replaceProduct(remoteId: String, request: PendingReplacement) {
        cancelStoreSearch()
        retailOperation?.cancel()
        updateState { copy(phase = AssistantPhase.REPLACING_PRODUCT, errorCode = null) }
        retailOperation = scope.launch {
            try {
                val updated = service.replaceProduct(
                    remoteId, request.sourceMessageId, request.requestId,
                    request.oldProductId, request.replacementProductId, request.packages,
                )
                absorbStores(updated)
                updateState { copy(
                    messages = messages.filterNot {
                        it.replacementForProductId != null && it.sourceMessageId == request.sourceMessageId
                    } + updated,
                    phase = AssistantPhase.IDLE,
                ) }
                pendingReplacement = null
                persistSoon()
            } catch (e: CancellationException) {
                throw e
            } catch (_: com.aiweapps.winescan.domain.assistant.repository.AssistantRetailAccessRequired) {
                updateState { copy(phase = AssistantPhase.IDLE, errorCode = AssistantUiError.RETAIL_ACCESS_REQUIRED) }
            } catch (_: Exception) {
                updateState { copy(phase = AssistantPhase.IDLE, errorCode = AssistantUiError.REPLACEMENT_UNAVAILABLE) }
            }
        }
    }

    override fun onLinkClicked(url: String) {
        val allowedInMessages = currentState.messages.asSequence().flatMap { message ->
            message.wines.asSequence().mapNotNull { it.pageUrl } +
                message.products.asSequence().mapNotNull { it.url }
        }.any { it == url }
        val allowed = allowedInMessages || currentState.selectedWine?.pageUrl == url ||
            savedWines.values.any { it.pageUrl == url }
        if (allowed && url.startsWith("https://")) platformLinks.openUrl(url)
    }

    override fun onMessageRetryClicked(messageId: String) {
        if (!conversationReady || currentState.phase != AssistantPhase.IDLE ||
            messageId !in currentState.retryableMessageIds) return
        val error = currentState.messages.firstOrNull { it.id == messageId } ?: return
        val textRequest = if (error.photos.isEmpty()) pendingSendFor(error) ?: return else null
        cancelStoreSearch()
        retailOperation?.cancel()
        operation?.cancel()
        pendingStoreSelection = null
        pendingStoreIntent = null
        pendingDinnerSelection = null
        pendingReplacement = null
        pendingReplacementProductId = null
        pendingSend = textRequest
        updateState { copy(errorCode = null) }
        if (error.photos.isNotEmpty()) {
            val localId = currentState.conversationId
            operation = scope.launch {
                updateState { copy(phase = AssistantPhase.RECOGNIZING) }
                recognizePhotos(error.photos)
                coroutineContext.ensureActive()
                if (currentState.conversationId == localId) {
                    updateState { copy(phase = AssistantPhase.IDLE) }
                    persistSoon()
                }
            }
        } else if (textRequest != null) retrySend(textRequest)
    }

    private fun pendingSendFor(error: AssistantMessage): PendingSend? {
        if (error.errorCode !in setOf(AssistantUiError.STORE_UNAVAILABLE,
                AssistantUiError.SERVICE_UNAVAILABLE, AssistantUiError.RETAIL_ACCESS_REQUIRED)) return null
        val conversationId = currentState.conversationId ?: return null
        val errorIndex = currentState.messages.indexOfFirst { it.id == error.id }
        if (errorIndex < 0) return null
        val preceding = currentState.messages.take(errorIndex)
        val user = preceding.lastOrNull {
            it.kind in setOf(AssistantMessageKind.USER_TEXT, AssistantMessageKind.USER_PHOTOS) && it.text.isNotBlank()
        } ?: return null
        val durable = user.retryContext
        val failedRequestId = error.requestId ?: durable?.requestId ?: user.requestId
        if (error.source == "local_transport" && failedRequestId != null &&
            currentState.messages.any { it.kind == AssistantMessageKind.ASSISTANT_TEXT &&
                it.requestId == failedRequestId }) return null
        val photos = if (user.photos.isNotEmpty()) user.photos else
            pendingPhotoOnlyContext(preceding.takeWhile { it.id != user.id })
        val photoIds = photos.map { it.id }
        val recognizedWines = winesForPhotos(photos)
        val recognized = recognizedWines.mapNotNull { wine ->
            val index = photos.indexOfFirst { it.id == wine.photoId }
            if (index >= 0) AssistantPhotoWine(index + 1, wine) else null
        }
        val selected = currentState.selectedWine?.takeUnless { it.photoId in photoIds }
        val retryId = if (error.source == "local_transport") durable?.requestId ?: user.requestId ?: nextId() else nextId()
        return PendingSend(retryId, conversationId, user.text, if (durable != null) durable.wine else selected,
            durable?.photoWines ?: recognized, durable?.photoScans ?: photoScansFor(photos, recognizedWines),
            if (durable != null) durable.storeId else currentState.selectedStore?.id,
            durable?.comparisonWines ?: comparisonWines())
    }

    private fun retrySend(pending: PendingSend) {
        operation?.cancel()
        operation = scope.launch {
            sendText(pending.text, pending.localConversationId, pending.wine,
                pending.photoWines, pending.photoScans, pending.requestId)
            coroutineContext.ensureActive()
            if (currentState.conversationId == pending.localConversationId) updateState { copy(phase = AssistantPhase.IDLE) }
        }
    }

    override fun onRetryClicked() {
        if (currentState.phase != AssistantPhase.IDLE) return
        if (!accountStartupComplete) {
            startAccountStartup()
            return
        }
        val storeSearch = pendingStoreSearch
        if (currentState.errorCode == AssistantUiError.STORE_UNAVAILABLE && storeSearch != null &&
            storeSearch.localConversationId == currentState.conversationId &&
            storeSearch.subject == currentState.account?.subject &&
            storeSearch.subject == accounts.account.value?.subject && storeSearch.revision == storeSearchRevision) {
            findStores(storeSearch.query)
            return
        }
        val accessRequired = currentState.errorCode == AssistantUiError.RETAIL_ACCESS_REQUIRED
        updateState { copy(errorCode = null) }
        val storeSelection = pendingStoreSelection
        if (storeSelection != null && storeSelection.localConversationId == currentState.conversationId &&
            storeSelection.subject == currentState.account?.subject) {
            selectStore(storeSelection)
            return
        }
        val dinnerSelection = pendingDinnerSelection
        if (dinnerSelection != null && dinnerSelection.localConversationId == currentState.conversationId &&
            remoteSessionId != null) {
            selectDinner(remoteSessionId!!, dinnerSelection)
            return
        }
        val replacement = pendingReplacement
        if (replacement != null && remoteSessionId != null) {
            replaceProduct(remoteSessionId!!, replacement)
            return
        }
        val candidateProductId = pendingReplacementProductId
        if (candidateProductId != null) {
            onProductReplacementRequested(candidateProductId)
            return
        }
        val pending = pendingSend ?: run {
            val lastUserIndex = currentState.messages.indexOfLast {
                it.kind in setOf(AssistantMessageKind.USER_TEXT, AssistantMessageKind.USER_PHOTOS) && it.text.isNotBlank()
            }
            currentState.messages.drop(lastUserIndex + 1).lastOrNull { it.kind == AssistantMessageKind.ERROR }
                ?.let(::pendingSendFor)?.also { pendingSend = it }
        }
        if (pending != null && pending.localConversationId == currentState.conversationId) {
            retrySend(pending)
            return
        }
        if (accessRequired) {
            currentState.selectedStore?.let { onStoreSelected(it.id) }
            return
        }
        val failedPhoto = currentState.messages.lastOrNull {
            it.kind == AssistantMessageKind.ERROR && it.photos.isNotEmpty()
        }?.photos?.firstOrNull()
        if (failedPhoto != null) {
            operation?.cancel()
            operation = scope.launch {
                updateState { copy(phase = AssistantPhase.RECOGNIZING) }
                recognizePhotos(listOf(failedPhoto))
                updateState { copy(phase = AssistantPhase.IDLE) }
            }
            return
        }
    }

    private fun WineCard.toAssistantWine(photo: AssistantPhoto, instanceId: String?, uncertain: Boolean,
        sourceCrop: com.aiweapps.winescan.domain.scan.model.BottleBox?, sourceFrame: List<Int>?) = AssistantWine(
        slug = slug,
        title = presentationTitle,
        producer = producer,
        region = region,
        category = category,
        foodPairings = pairings.orEmpty(),
        reference = reference,
        pageUrl = catalogueUrl,
        photoId = photo.id,
        photoPath = photo.path,
        instanceId = instanceId,
        uncertain = uncertain,
        description = description,
        dishes = dishes,
        sourceCrop = sourceCrop,
        sourceFrame = sourceFrame,
    )

    private fun nextId(): String = Uuid.random().toString()
}
