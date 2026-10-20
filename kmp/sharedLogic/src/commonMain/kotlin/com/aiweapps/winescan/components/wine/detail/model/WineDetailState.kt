package com.aiweapps.winescan.components.wine.detail.model

import com.aiweapps.core.components.model.BaseScreenState
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.core.error.AppError
import com.aiweapps.winescan.components.common.model.WineFacts
import com.aiweapps.winescan.config.CompareLimits
import com.aiweapps.winescan.domain.scan.model.BottlePhoto
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess
import com.aiweapps.winescan.domain.scan.model.WineCard

/** What the comparison buttons of the wine screen report. */
sealed class WineDetailToast {
    data object AddedToCompare : WineDetailToast()
    data object AlreadyInCompare : WineDetailToast()
    data object CompareFull : WineDetailToast()
    data object AddToCompareFailed : WineDetailToast()
    data object RemovedFromCompare : WineDetailToast()
    data object RemoveFromCompareFailed : WineDetailToast()
}

data class WineDetailState(
    /** Always `Content`: the card arrives with the screen and the facts load beside it. */
    override val screenState: ScreenState = ScreenState.Content,
    val card: WineCard,
    /** The user's bottle the card was suggested for; `null` when there is no photo. */
    val bottle: BottlePhoto?,
    /** Colour, sugar, temperature and pairings; `null` while they load, [WineFacts.NO_DATA] when there are none. */
    val facts: WineFacts? = null,
    val isFactsLoading: Boolean = true,
    val factsError: AppError? = null,
    val referenceAccess: ReferenceAccess? = null,
    val isInCompare: Boolean = false,
    val compareCount: Int = 0,
    val toast: WineDetailToast? = null,
) : BaseScreenState {

    /** `null` until a session is open, or when the catalogue has no reference for the wine. */
    val referenceUrl: String? get() = referenceAccess?.resolve(card.reference)

    val canCompareWithPhoto: Boolean get() = bottle != null

    /** The set takes a wine only together with a photo of it. */
    val canAddToCompare: Boolean get() = bottle != null && !isInCompare

    /** The set has no room for this wine; one already there can still be removed. */
    val isCompareFull: Boolean get() = !isInCompare && compareCount >= CompareLimits.MAX_WINES
}
