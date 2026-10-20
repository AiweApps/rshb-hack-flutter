package com.aiweapps.winescan.domain.pairing.model

import com.aiweapps.winescan.domain.compare.model.CompareEntry
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.DishDictionary
import com.aiweapps.winescan.domain.gastronomy.model.DishLabel
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.domain.scan.model.BottleBox
import kotlinx.serialization.Serializable

/** How one wine of the set relates to the chosen dish. */
enum class PairingVerdict {
    /** The catalogue lists the dish for the wine. */
    MATCH,

    /** The catalogue lists pairings for the wine, the dish is not among them. */
    NO_MATCH,

    /** The catalogue lists no pairings for the wine: «no data», not «does not go». */
    NO_DATA,
}

/** One wine against the dish; [photoPath] is `null` for a saved choice, which keeps cards only. */
data class PairingMatch(
    val card: WineCard,
    val photoPath: String?,
    val verdict: PairingVerdict,
    val crop: BottleBox? = null,
    val frame: List<Int>? = null,
)

/** A wine shown before a dish is selected; there is no pairing verdict yet. */
data class PairingWine(
    val card: WineCard,
    val photoPath: String?,
    val crop: BottleBox? = null,
    val frame: List<Int>? = null,
)

/** A dish choice the user kept, with what it needs to render without the network. */
@Serializable
data class SavedPairing(
    val id: Long,
    /** A choice saved before dishes had ids has its old label as the id and as every label. */
    val dish: Dish,
    val wines: List<WineCard>,
    /** The wines' gastronomy when the choice was saved, by slug. */
    val gastronomy: Map<String, WineGastronomy>,
    /** The dishes those wines list, with their labels. */
    val dishes: List<Dish>,
    val createdAtMillis: Long,
    /**
     * How many wines of the comparison the choice was made among; [wines] are only the
     * matching ones. A choice saved before this was kept counts [wines].
     */
    val compareSetSize: Int,
)

/**
 * The pairing rules, in one place and pure. Only what the catalogue says counts: no taste
 * model, no scores — a wine either lists the dish or it does not. Dishes match by id.
 */
object DishMatcher {

    /** Every dish some wine of the set lists, in the dictionary's order. */
    fun dishes(
        entries: List<CompareEntry>,
        gastronomy: Map<String, WineGastronomy?>,
        dictionary: DishDictionary,
        language: String,
    ): List<DishLabel> {
        val listed = entries.flatMap { gastronomy[it.slug]?.pairingIds.orEmpty() }.distinct()
        return dictionary.labels(listed, language).orEmpty()
    }

    /** A wine whose gastronomy is missing or not loaded is «no data». */
    fun match(entries: List<CompareEntry>, gastronomy: Map<String, WineGastronomy?>, dishId: String): List<PairingMatch> =
        entries.map { entry ->
            val pairings = gastronomy[entry.slug]?.pairingIds
            val verdict = when {
                pairings == null -> PairingVerdict.NO_DATA
                dishId in pairings -> PairingVerdict.MATCH
                else -> PairingVerdict.NO_MATCH
            }
            PairingMatch(
                card = entry.card,
                photoPath = entry.photoPath,
                verdict = verdict,
                crop = entry.crop,
                frame = entry.frame,
            )
        }
}
