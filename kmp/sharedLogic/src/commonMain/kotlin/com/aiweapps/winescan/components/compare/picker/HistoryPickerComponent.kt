package com.aiweapps.winescan.components.compare.picker

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.value.Value
import com.aiweapps.core.components.base.BaseStatefulComponent
import com.aiweapps.core.components.model.BaseScreenState
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.core.error.AppError
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.history.model.ScanHistoryItem
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import kotlin.coroutines.CoroutineContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

/** The stored scans that have a match, to pick a wine for the comparison from. */
interface HistoryPickerComponent {

    val state: Value<HistoryPickerState>

    fun onScanClicked(scanId: Long)

    fun onCloseClicked()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            onPick: (scanId: Long) -> Unit,
            onClose: () -> Unit,
        ): HistoryPickerComponent
    }
}

data class HistoryPickerState(
    override val screenState: ScreenState = ScreenState.Loading,
    /** Only scans whose best card exists: a scan without a match has nothing to compare. */
    val items: List<ScanHistoryItem> = emptyList(),
    val compareSlugs: Set<String> = emptySet(),
) : BaseScreenState {

    fun isInCompare(item: ScanHistoryItem): Boolean = item.bestSlug != null && item.bestSlug in compareSlugs
}

internal class DefaultHistoryPickerComponent(
    componentContext: ComponentContext,
    historyRepository: ScanHistoryRepository,
    compareRepository: CompareSetRepository,
    private val onPick: (scanId: Long) -> Unit,
    private val onClose: () -> Unit,
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
) : HistoryPickerComponent, BaseStatefulComponent<HistoryPickerState>(
    componentContext = componentContext,
    initialState = HistoryPickerState(),
    mainContext = mainContext,
) {

    init {
        combine(historyRepository.watchAll(), compareRepository.watch()) { items, entries ->
            items.filter { it.bestSlug != null } to entries.map { it.slug }.toSet()
        }
            .onEach { (items, slugs) ->
                updateState { copy(screenState = ScreenState.Content, items = items, compareSlugs = slugs) }
            }
            // A local database read failing is not something we can classify any further.
            .catch { updateState { copy(screenState = ScreenState.Error(AppError.Unknown)) } }
            .launchIn(scope)
    }

    override fun onScanClicked(scanId: Long) {
        onPick(scanId)
    }

    override fun onCloseClicked() {
        onClose()
    }
}
