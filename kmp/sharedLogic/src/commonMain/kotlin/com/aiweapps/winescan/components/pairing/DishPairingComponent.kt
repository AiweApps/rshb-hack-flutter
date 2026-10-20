package com.aiweapps.winescan.components.pairing

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.pairing.model.DishPairingState
import com.aiweapps.winescan.domain.pairing.model.PairingSource
import com.aiweapps.winescan.domain.scan.model.WineCard

/**
 * «Pick a wine for the dish»: the dishes the catalogue lists for the compared wines, and
 * which of those wines it recommends for the chosen one. Only the catalogue speaks here —
 * no taste model, no scores.
 */
interface DishPairingComponent {

    val state: Value<DishPairingState>

    fun onBackClicked()

    /**
     * A dish chip was tapped; [dishId] is a [com.aiweapps.winescan.domain.gastronomy.model.DishLabel.id]
     * from the state's dishes. It toggles: another dish becomes the chosen one, the chosen
     * dish is cleared — back to the dishes with none chosen. On a saved choice opened from
     * the history its only chip is the chosen dish, so the tap leaves the saved choice for a
     * live one over today's comparison set, with no dish chosen.
     */
    fun onDishTapped(dishId: String)

    /**
     * «Change the dish»: back to the dishes with none chosen. From a saved choice opened from
     * the history this leaves it for a live choice over today's comparison set.
     */
    fun onChangeDishClicked()

    fun onSaveClicked()

    /**
     * A dish the catalogue does not list: a separate assistant conversation opens with the
     * wines on screen and [prompt], which the user can still edit there.
     */
    fun onCustomDishRequested(dish: String, prompt: String)

    /** «Add a wine»: back to the scanner. */
    fun onAddWineClicked()

    fun onCardLinkClicked(url: String)

    fun onToastConsumed()

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            source: PairingSource,
            onClose: () -> Unit,
            onOpenScanner: () -> Unit,
            onPlanDinner: (List<WineCard>, String) -> Unit,
        ): DishPairingComponent
    }
}
