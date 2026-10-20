package com.aiweapps.winescan.components.compare.model

import com.aiweapps.core.components.model.BaseScreenState
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.config.CompareLimits
import com.aiweapps.winescan.domain.compare.model.CompareEntry
import com.aiweapps.winescan.domain.compare.model.CompareRow
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess

enum class WineCompareToast { ADDED, ALREADY_THERE, FULL, ADD_FAILED, REMOVE_FAILED }

data class WineCompareState(
    /** `Loading` until the first read of the set; the set itself may well be empty. */
    override val screenState: ScreenState = ScreenState.Loading,
    val entries: List<CompareEntry> = emptyList(),
    /** Every row in table order: what «All» shows, without splitting by difference. */
    val allRows: List<CompareRow> = emptyList(),
    /** Rows where the wines disagree, in table order. */
    val differentRows: List<CompareRow> = emptyList(),
    /** Rows where every wine says the same (or nothing). */
    val sameRows: List<CompareRow> = emptyList(),
    /** `false` shows the differences and folds the rest; `true` lists every row. */
    val showAll: Boolean = true,
    val referenceAccess: ReferenceAccess? = null,
    val toast: WineCompareToast? = null,
) : BaseScreenState {

    val canAddMore: Boolean get() = entries.size < CompareLimits.MAX_WINES

    /** One wine alone is nothing to compare: the screen suggests a second. */
    val needsSecondWine: Boolean get() = entries.size == 1

    /** A dish can be picked over any set that has a wine in it. */
    val canPairDish: Boolean get() = entries.isNotEmpty()

    /** Three wines do not fit side by side on a phone: the table scrolls sideways. */
    val scrollsSideways: Boolean get() = entries.size > 2
}
