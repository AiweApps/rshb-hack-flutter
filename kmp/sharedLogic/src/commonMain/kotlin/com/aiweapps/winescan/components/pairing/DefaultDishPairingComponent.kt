package com.aiweapps.winescan.components.pairing

import com.arkivanov.decompose.ComponentContext
import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.components.base.BaseStatefulComponent
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.core.error.AppError
import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.winescan.components.common.GastronomyLoader
import com.aiweapps.winescan.components.pairing.model.DishPairingState
import com.aiweapps.winescan.components.pairing.model.DishPairingToast
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.config.AnalyticsScreens
import com.aiweapps.winescan.domain.compare.model.CompareEntry
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.gastronomy.model.DishLabel
import com.aiweapps.winescan.domain.gastronomy.repository.GastronomyRepository
import com.aiweapps.winescan.domain.language.repository.AppLanguageRepository
import com.aiweapps.winescan.domain.pairing.model.DishMatcher
import com.aiweapps.winescan.domain.pairing.model.PairingMatch
import com.aiweapps.winescan.domain.pairing.model.PairingSource
import com.aiweapps.winescan.domain.pairing.model.PairingVerdict
import com.aiweapps.winescan.domain.pairing.model.PairingWine
import com.aiweapps.winescan.domain.pairing.model.SavedPairing
import com.aiweapps.winescan.domain.pairing.repository.SavedPairingRepository
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

internal class DefaultDishPairingComponent(
    componentContext: ComponentContext,
    private val source: PairingSource,
    private val compareRepository: CompareSetRepository,
    private val savedPairingRepository: SavedPairingRepository,
    private val scanRepository: ScanRepository,
    gastronomyRepository: GastronomyRepository,
    appLanguage: AppLanguageRepository,
    private val platformLinks: PlatformLinks,
    private val analytics: AnalyticsTracker,
    private val onClose: () -> Unit,
    private val onOpenScanner: () -> Unit,
    private val onPlanDinner: (List<WineCard>, String) -> Unit,
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
) : DishPairingComponent, BaseStatefulComponent<DishPairingState>(
    componentContext = componentContext,
    initialState = DishPairingState(),
    mainContext = mainContext,
) {

    private var entries: List<CompareEntry> = emptyList()
    private var selectedDishId: String? = null
    private var saved: SavedPairing? = null
    private var setJob: Job? = null

    private val gastronomy = GastronomyLoader(
        repository = gastronomyRepository,
        appLanguage = appLanguage,
        analytics = analytics,
        screen = AnalyticsScreens.DISH_PAIRING,
        scope = scope,
        lifecycle = lifecycle,
        onUpdate = { updatePairing() },
    )

    init {
        scope.launch {
            val access = scanRepository.referenceAccess()
            updateState { copy(referenceAccess = access) }
        }
        when (source) {
            PairingSource.FromCompareSet -> observeSet()
            is PairingSource.Saved -> openSaved(source.id)
        }
    }

    override fun onBackClicked() {
        onClose()
    }

    /** A saved choice opened from the history is shown as it was, until its dish is tapped. */
    private val isSavedView: Boolean get() = setJob == null

    override fun onDishTapped(dishId: String) {
        // A choice being written keeps its dish until the write is done.
        if (currentState.isSaving || currentState.dishes.none { it.id == dishId }) return
        // The saved choice's only chip is its dish: clearing it is the way to a live choice.
        if (isSavedView) {
            observeSet()
            return
        }
        selectedDishId = if (dishId == selectedDishId) null else dishId
        // A new dish after a save is a new choice: it can be saved again.
        updateState { copy(savedId = null) }
        updatePairing()
    }

    override fun onChangeDishClicked() {
        if (currentState.isSaving) return
        if (isSavedView) {
            observeSet()
            return
        }
        selectedDishId = null
        updateState { copy(savedId = null) }
        updatePairing()
    }

    override fun onSaveClicked() {
        val state = currentState
        val snapshot = gastronomy.snapshot
        val dish = selectedDishId?.let { snapshot.dishes[it] } ?: return
        if (!state.canSave) return
        val wines = state.matched.map { it.card }
        updateState { copy(isSaving = true) }
        scope.launch {
            try {
                val id = savedPairingRepository.save(
                    dish = dish,
                    wines = wines,
                    gastronomy = snapshot.bySlug,
                    dishes = snapshot.dishes.dishes,
                    compareSetSize = state.wineCount,
                )
                analytics.logEvent(
                    AnalyticsEvents.PAIRING_SAVED,
                    mapOf(AnalyticsParams.DISH to dish.id, AnalyticsParams.WINES to wines.size.toString()),
                )
                updateState { copy(isSaving = false, savedId = id, toast = DishPairingToast.SAVED) }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                updateState { copy(isSaving = false, toast = DishPairingToast.SAVE_FAILED) }
            }
        }
    }

    override fun onCustomDishRequested(dish: String, prompt: String) {
        val state = currentState
        if (dish.isBlank() || prompt.isBlank() || state.isSaving || state.wines.isEmpty()) return
        onPlanDinner(state.wines.map { it.card }, prompt.trim())
    }

    override fun onAddWineClicked() {
        onOpenScanner()
    }

    override fun onCardLinkClicked(url: String) {
        analytics.logEvent(
            AnalyticsEvents.WINE_PAGE_OPENED,
            mapOf(AnalyticsParams.SCREEN to AnalyticsScreens.DISH_PAIRING),
        )
        platformLinks.openUrl(url)
    }

    override fun onToastConsumed() {
        updateState { copy(toast = null) }
    }

    private fun observeSet() {
        saved = null
        selectedDishId = null
        updateState { copy(screenState = ScreenState.Loading, savedId = null) }
        setJob = compareRepository.watch()
            .onEach { latest ->
                entries = latest
                updateState { copy(screenState = ScreenState.Content) }
                gastronomy.load(latest.map { it.card })
                updatePairing()
            }
            .catch { updateState { copy(screenState = ScreenState.Error(AppError.Unknown)) } }
            .launchIn(scope)
    }

    private fun openSaved(id: Long) {
        scope.launch {
            val pairing = savedPairingRepository.byId(id)
            if (pairing == null) {
                updateState { copy(screenState = ScreenState.Error(AppError.Unknown)) }
                return@launch
            }
            saved = pairing
            updateState { copy(screenState = ScreenState.Content, savedId = pairing.id) }
            gastronomy.show(
                slugs = pairing.wines.map { it.slug },
                gastronomy = pairing.gastronomy,
                dishes = pairing.dishes,
            )
            updatePairing()
        }
    }

    /** The only place the dishes and the answer are rebuilt: from the set or the saved choice, and the gastronomy. */
    private fun updatePairing() {
        val snapshot = gastronomy.snapshot
        val pairing = saved
        if (pairing != null) {
            val dish = DishLabel(id = pairing.dish.id, label = pairing.dish.labelIn(snapshot.language))
            updateState {
                copy(
                    dishes = listOf(dish),
                    selectedDish = dish,
                    wines = pairing.wines.map { PairingWine(card = it, photoPath = null) },
                    matches = pairing.wines.map { PairingMatch(card = it, photoPath = null, verdict = PairingVerdict.MATCH) },
                    facts = snapshot.facts,
                    isLoadingDishes = false,
                    wineCount = pairing.compareSetSize,
                )
            }
            return
        }
        val dishes = DishMatcher.dishes(entries, snapshot.loaded, snapshot.dishes, snapshot.language)
        // A wine added or removed under an open choice changes the answer; a dish no wine lists any more is dropped.
        val selected = dishes.firstOrNull { it.id == selectedDishId }
        if (selected == null && !snapshot.isLoading) selectedDishId = null
        updateState {
            copy(
                dishes = dishes,
                selectedDish = selected,
                wines = entries.map { PairingWine(card = it.card, photoPath = it.photoPath, crop = it.crop, frame = it.frame) },
                matches = selected?.let { DishMatcher.match(entries, snapshot.loaded, it.id) } ?: emptyList(),
                facts = snapshot.facts,
                isLoadingDishes = snapshot.isLoading,
                wineCount = entries.size,
            )
        }
    }
}
