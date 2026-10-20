package com.aiweapps.winescan.components.common

import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.error.AppError
import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.components.common.model.WineFacts
import com.aiweapps.winescan.components.common.model.toFacts
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.config.AnalyticsValues
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.DishDictionary
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.gastronomy.repository.GastronomyRepository
import com.aiweapps.winescan.domain.language.repository.AppLanguageRepository
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.arkivanov.essenty.lifecycle.Lifecycle
import com.arkivanov.essenty.lifecycle.doOnResume
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch

/** What a screen knows about its wines' gastronomy so far. */
internal data class GastronomySnapshot(
    val language: String,
    val isLoading: Boolean = false,
    /** Slugs with a successful answer, with data in [bySlug] or without; failures remain retryable. */
    val loadedSlugs: Set<String> = emptySet(),
    /** Finished failures are unavailable for display, but never count as successful cache hits. */
    val failedSlugs: Set<String> = emptySet(),
    /** Failures are not a successful empty catalogue answer; readers can offer an inline retry. */
    val errorsBySlug: Map<String, AppError> = emptyMap(),
    val pendingSlugs: Set<String> = emptySet(),
    val bySlug: Map<String, WineGastronomy> = emptyMap(),
    val dishes: DishDictionary = DishDictionary.EMPTY,
) {
    /** Completed slugs to their data or `null`; only a pending request is absent. */
    val loaded: Map<String, WineGastronomy?> get() = (loadedSlugs + failedSlugs).associateWith { bySlug[it] }

    val facts: Map<String, WineFacts> get() = (loadedSlugs + failedSlugs).associateWith { bySlug[it].toFacts(dishes, language) }
}

/**
 * Loads the gastronomy beside the screen. A failure leaves it unavailable and retryable
 * and reports an analytics event. The language is re-read on every resume.
 */
internal class GastronomyLoader(
    private val repository: GastronomyRepository,
    private val appLanguage: AppLanguageRepository,
    private val analytics: AnalyticsTracker,
    private val screen: String,
    private val scope: CoroutineScope,
    lifecycle: Lifecycle,
    private val onUpdate: (GastronomySnapshot) -> Unit,
) {

    var snapshot: GastronomySnapshot = GastronomySnapshot(language = appLanguage.language.value)
        private set

    private var loadJob: Job? = null
    private var loadRevision = 0L
    private var dictionaryLoaded = false
    // Null denotes a saved/offline snapshot: resuming it must not start a network load.
    private var requestedCards: List<WineCard>? = null

    init {
        lifecycle.doOnResume {
            appLanguage.refresh()
            // Retry only on a real lifecycle transition (or the next explicit load),
            // never from onUpdate: failures cannot create a request/render loop.
            if (loadJob?.isActive != true) requestedCards?.let { load(it) }
        }
        appLanguage.language
            .onEach { language -> if (language != snapshot.language) publish(snapshot.copy(language = language)) }
            .launchIn(scope)
    }

    /** Loads what is not loaded yet among [cards], replacing a load still in flight. */
    fun load(cards: List<WineCard>) {
        requestedCards = cards.toList()
        val missing = cards.distinctBy { it.slug }.filterNot { it.slug in snapshot.loadedSlugs }
        if (cards.isEmpty() || (dictionaryLoaded && missing.isEmpty())) {
            loadRevision += 1
            loadJob?.cancel()
            loadJob = null
            if (snapshot.isLoading) publish(snapshot.copy(isLoading = false, pendingSlugs = emptySet()))
            return
        }
        val revision = ++loadRevision
        loadJob?.cancel()
        val wanted = missing.mapTo(mutableSetOf()) { it.slug }
        publish(snapshot.copy(
            isLoading = true,
            pendingSlugs = wanted,
            failedSlugs = snapshot.failedSlugs - wanted,
            errorsBySlug = snapshot.errorsBySlug - wanted,
        ))
        loadJob = scope.launch {
            // An alternative failing must not hide the best wine, including a cached one.
            // Singleton requests retain the repository's success/empty/failure contract:
            // a transient failure is never cached as an omitted (empty) successful slug.
            missing.map { card ->
                launch cardLoad@ {
                    val result = repository.gastronomy(listOf(card))
                    val dishes = if (result is ApiResponse.Success) repository.dishes() else null
                    ensureActive()
                    if (revision != loadRevision) return@cardLoad
                    var next = snapshot.copy(pendingSlugs = snapshot.pendingSlugs - card.slug)
                    next = when (result) {
                        is ApiResponse.Success -> next.copy(
                            loadedSlugs = next.loadedSlugs + card.slug,
                            failedSlugs = next.failedSlugs - card.slug,
                            errorsBySlug = next.errorsBySlug - card.slug,
                            bySlug = next.bySlug + result.data,
                        )
                        is ApiResponse.Error -> {
                            report(AnalyticsValues.REQUEST_WINES, result.error)
                            next.copy(
                                failedSlugs = next.failedSlugs + card.slug,
                                errorsBySlug = next.errorsBySlug + (card.slug to result.error),
                            )
                        }
                    }
                    if (dishes != null) next = withDictionary(next, dishes)
                    publish(next)
                }
            }.joinAll()
            // Also retries a failed dictionary when every wine is already cached.
            val dishes = repository.dishes()
            ensureActive()
            if (revision != loadRevision) return@launch
            publish(withDictionary(snapshot, dishes).copy(isLoading = false, pendingSlugs = emptySet()))
        }
    }

    /** Successful wines stay on screen and in cache; only unavailable data are asked for again. */
    fun retryFailed() {
        if (loadJob?.isActive == true) return
        requestedCards?.let(::load)
    }

    /** Shows data already at hand, such as a saved choice's snapshot, without the network. */
    fun show(slugs: Collection<String>, gastronomy: Map<String, WineGastronomy>, dishes: List<Dish>) {
        loadRevision += 1
        loadJob?.cancel()
        requestedCards = null
        publish(
            snapshot.copy(
                isLoading = false,
                loadedSlugs = snapshot.loadedSlugs + slugs,
                failedSlugs = snapshot.failedSlugs - slugs.toSet(),
                errorsBySlug = snapshot.errorsBySlug - slugs.toSet(),
                pendingSlugs = emptySet(),
                bySlug = snapshot.bySlug + gastronomy,
                dishes = merged(snapshot.dishes.dishes, DishDictionary(dishes)),
            )
        )
    }

    // The fuller list leads, so the dictionary's order wins over a saved choice's subset.
    private fun merged(primary: List<Dish>, extra: DishDictionary): DishDictionary {
        val ids = primary.map { it.id }.toSet()
        return DishDictionary(primary + extra.dishes.filterNot { it.id in ids })
    }

    private fun withDictionary(current: GastronomySnapshot, response: ApiResponse<List<Dish>>): GastronomySnapshot =
        when (response) {
            is ApiResponse.Success -> {
                dictionaryLoaded = true
                current.copy(dishes = merged(response.data, current.dishes))
            }
            is ApiResponse.Error -> {
                dictionaryLoaded = false
                report(AnalyticsValues.REQUEST_DISHES, response.error)
                current
            }
        }

    private fun publish(next: GastronomySnapshot) {
        snapshot = next
        onUpdate(next)
    }

    private fun report(request: String, error: AppError) {
        analytics.logEvent(
            AnalyticsEvents.GASTRONOMY_FAILED,
            mapOf(
                AnalyticsParams.SCREEN to screen,
                AnalyticsParams.REQUEST to request,
                AnalyticsParams.REASON to when (error) {
                    AppError.Network -> AnalyticsValues.REASON_NETWORK
                    AppError.Timeout -> AnalyticsValues.REASON_TIMEOUT
                    AppError.Unauthorized -> AnalyticsValues.REASON_UNAUTHORIZED
                    is AppError.Server -> AnalyticsValues.REASON_SERVER
                    AppError.Unknown -> AnalyticsValues.REASON_UNKNOWN
                },
            ),
        )
    }
}
