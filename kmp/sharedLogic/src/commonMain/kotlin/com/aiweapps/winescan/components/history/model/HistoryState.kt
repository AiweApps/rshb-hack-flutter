package com.aiweapps.winescan.components.history.model

import com.aiweapps.core.components.model.BaseScreenState
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.config.GastronomyConfig
import com.aiweapps.winescan.domain.history.model.HistoryDaySection
import com.aiweapps.winescan.domain.history.model.ScanHistoryItem
import com.aiweapps.winescan.domain.pairing.model.SavedPairing

enum class HistoryToast {
    DELETED, DELETE_FAILED, CLEARED, CLEAR_FAILED,
    PAIRING_DELETED, PAIRING_DELETE_FAILED,
    ADDED_TO_COMPARE, ALREADY_IN_COMPARE, COMPARE_FULL, ADD_TO_COMPARE_FAILED,
    REMOVED_FROM_COMPARE, REMOVE_FROM_COMPARE_FAILED,
    ADDED_TO_FAVORITES, REMOVED_FROM_FAVORITES, FAVORITES_FAILED,
}

data class HistoryState(
    override val screenState: ScreenState = ScreenState.Loading,
    /**
     * Rows the list renders: what the database holds minus the rows the user has already
     * swiped away and whose deletion is still in flight.
     */
    val items: List<ScanHistoryItem> = emptyList(),
    /** [items] grouped by calendar day, newest first — what the list draws. */
    val sections: List<HistoryDaySection> = emptyList(),
    /** Ids swiped away but not yet gone from the database. */
    val pendingDeleteIds: Set<Long> = emptySet(),
    /** Dish choices the user kept, newest first. */
    val savedPairings: List<SavedPairing> = emptyList(),
    /** Slugs of the wines in the comparison set: a row's compare button shows whether its wine is there. */
    val compareSlugs: Set<String> = emptySet(),
    /** Slugs of the wines in «My wines»: a row's heart shows whether its wine is there. */
    val favoriteSlugs: Set<String> = emptySet(),
    /** ISO 639-1 code the saved dishes are named in. */
    val languageCode: String = GastronomyConfig.DEFAULT_LANGUAGE,
    val toast: HistoryToast? = null,
) : BaseScreenState {

    fun isInCompare(item: ScanHistoryItem): Boolean = item.bestSlug != null && item.bestSlug in compareSlugs

    fun isFavorite(item: ScanHistoryItem): Boolean = item.bestSlug != null && item.bestSlug in favoriteSlugs

    /** The saved choice's dish, named in the app's language. */
    fun dishLabelOf(pairing: SavedPairing): String = pairing.dish.labelIn(languageCode)

    /** Nothing scanned and nothing saved: the empty state. */
    val isEmpty: Boolean get() = items.isEmpty() && savedPairings.isEmpty()

    /** The "clear" action only makes sense over a non-empty list. */
    val canClear: Boolean get() = screenState is ScreenState.Content && items.isNotEmpty()
}
