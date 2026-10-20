package com.aiweapps.winescan.components.pairing.model

import com.aiweapps.core.components.model.BaseScreenState
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.components.common.model.WineFacts
import com.aiweapps.winescan.domain.gastronomy.model.DishLabel
import com.aiweapps.winescan.domain.pairing.model.PairingMatch
import com.aiweapps.winescan.domain.pairing.model.PairingVerdict
import com.aiweapps.winescan.domain.pairing.model.PairingWine
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess

enum class DishPairingToast { SAVED, SAVE_FAILED }

data class DishPairingState(
    /** `Loading` until the set (or the saved choice) is read; `Error` when a saved choice is gone. */
    override val screenState: ScreenState = ScreenState.Loading,
    /** Dishes some wine of the set lists, in the catalogue's order, named in the app's language. */
    val dishes: List<DishLabel> = emptyList(),
    val selectedDish: DishLabel? = null,
    /** The wines the choice is made among (or the saved choice's), shown before a dish is chosen. */
    val wines: List<PairingWine> = emptyList(),
    /** One per wine, for [selectedDish]; empty while no dish is chosen. */
    val matches: List<PairingMatch> = emptyList(),
    /** The wines' gastronomy by slug; a slug still loading is absent. */
    val facts: Map<String, WineFacts> = emptyMap(),
    /** The wines' gastronomy is on its way: [dishes] may still grow. */
    val isLoadingDishes: Boolean = false,
    /**
     * How many wines the choice is made among: the comparison set now, or, for a saved
     * choice, the set as it was when the choice was kept — the subtitle «Among N wines from
     * the comparison». A choice saved before the size was kept counts its own wines.
     */
    val wineCount: Int = 0,
    /** The saved choice on screen, or the one just saved: then there is nothing more to save. */
    val savedId: Long? = null,
    val isSaving: Boolean = false,
    val referenceAccess: ReferenceAccess? = null,
    val toast: DishPairingToast? = null,
) : BaseScreenState {

    val matched: List<PairingMatch> get() = matches.filter { it.verdict == PairingVerdict.MATCH }

    /** Wines the catalogue lists pairings for, without the chosen dish. */
    val unmatched: List<PairingMatch> get() = matches.filter { it.verdict == PairingVerdict.NO_MATCH }

    val withoutData: List<PairingMatch> get() = matches.filter { it.verdict == PairingVerdict.NO_DATA }

    /** A dish is chosen and no wine lists it: the «no such pairing in the catalogue» state. */
    val hasNoMatches: Boolean get() = selectedDish != null && matched.isEmpty()

    /** Nothing loading and no wine of the set lists any dish: there is nothing to choose from. */
    val hasNoDishes: Boolean get() = screenState is ScreenState.Content && !isLoadingDishes && dishes.isEmpty()

    val canSave: Boolean get() = matched.isNotEmpty() && savedId == null && !isSaving
}
