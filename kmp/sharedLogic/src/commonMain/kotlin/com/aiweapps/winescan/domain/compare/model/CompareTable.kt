package com.aiweapps.winescan.domain.compare.model

import com.aiweapps.winescan.domain.gastronomy.model.DishDictionary
import com.aiweapps.winescan.domain.gastronomy.model.DishLabel
import com.aiweapps.winescan.domain.gastronomy.model.ServingTemperature
import com.aiweapps.winescan.domain.gastronomy.model.WineColor
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.gastronomy.model.WineSugar
import com.aiweapps.winescan.domain.scan.model.WineCard

/** The characteristics compared side by side, in the order the table shows them. */
enum class CompareAttribute { COLOR, SUGAR, ALCOHOL, GRAPES, REGION, PAIRINGS, TEMPERATURE }

/** One cell of the table. Colour, sugar and temperature come as values the UI localises and formats. */
sealed class CompareValue {
    data class Text(val value: String) : CompareValue()

    data class Color(val color: WineColor, val isSparkling: Boolean?) : CompareValue()

    data class Sugar(val sugar: WineSugar) : CompareValue()

    data class Temperature(val range: ServingTemperature) : CompareValue()

    /** Empty [dishes] is «the catalogue lists none»; [sharedIds] are the dishes every wine lists. */
    data class Pairings(val dishes: List<DishLabel>, val sharedIds: Set<String>) : CompareValue()

    /** The wine's gastronomy is still loading. */
    data object Pending : CompareValue()

    /** Nothing in the catalogue: «no data». */
    data object None : CompareValue()
}

/** One row of the table: the attribute and one cell per entry, in the set's order. */
data class CompareRow(
    val attribute: CompareAttribute,
    val values: List<CompareValue>,
    /** At least two entries disagree, or one has the value and another does not; never while loading. */
    val isDifferent: Boolean,
)

/**
 * Builds the comparison table from the set. Pure: the screen only sorts and draws what
 * comes out, so the rule for «different» lives in one place and is testable.
 */
object CompareTable {

    /** [gastronomy] maps a loaded slug to its data or to `null` (no data); a slug not in it is still loading. */
    fun build(
        entries: List<CompareEntry>,
        gastronomy: Map<String, WineGastronomy?>,
        dishes: DishDictionary,
        language: String,
    ): List<CompareRow> {
        if (entries.isEmpty()) return emptyList()
        val pairings = entries.map { entry ->
            if (entry.slug in gastronomy) dishes.labels(gastronomy[entry.slug]?.pairingIds, language) else null
        }
        val shared = sharedIds(pairings)
        return CompareAttribute.entries.map { attribute ->
            val values = entries.mapIndexed { index, entry ->
                val isLoaded = entry.slug in gastronomy
                when {
                    attribute.isGastronomy && !isLoaded -> CompareValue.Pending
                    attribute == CompareAttribute.PAIRINGS ->
                        pairings[index]?.let { CompareValue.Pairings(it, shared) } ?: CompareValue.None
                    else -> valueOf(entry.card, gastronomy[entry.slug], attribute)
                }
            }
            CompareRow(attribute = attribute, values = values, isDifferent = isDifferent(values))
        // A card attribute nobody has is dropped; a gastronomy row stays even when empty,
        // because its empty cells say «no data», which is an answer in itself.
        }.filter { row -> row.attribute.isGastronomy || row.values.any { it != CompareValue.None } }
    }

    // Alcohol, grapes and region are on the card itself; the rest waits for the gastronomy.
    private val CompareAttribute.isGastronomy: Boolean
        get() = this != CompareAttribute.GRAPES && this != CompareAttribute.REGION && this != CompareAttribute.ALCOHOL

    private fun valueOf(card: WineCard, gastronomy: WineGastronomy?, attribute: CompareAttribute): CompareValue =
        when (attribute) {
            CompareAttribute.COLOR -> gastronomy?.color?.takeIf { it != WineColor.UNKNOWN }
                ?.let { CompareValue.Color(it, gastronomy.isSparkling) } ?: CompareValue.None
            CompareAttribute.SUGAR -> gastronomy?.sugar?.takeIf { it != WineSugar.UNKNOWN }
                ?.let { CompareValue.Sugar(it) } ?: CompareValue.None
            CompareAttribute.TEMPERATURE -> gastronomy?.servingTemperature
                ?.let { CompareValue.Temperature(it) } ?: CompareValue.None
            CompareAttribute.ALCOHOL -> text(
                card.validAlcohol
                    ?.toString()?.removeSuffix(".0")?.let { "$it %" }
            )
            CompareAttribute.GRAPES -> text(card.grapes)
            CompareAttribute.REGION -> text(card.region)
            CompareAttribute.PAIRINGS -> CompareValue.None
        }

    private fun text(value: String?): CompareValue =
        value?.trim()?.takeIf { it.isNotEmpty() }?.let { CompareValue.Text(it) } ?: CompareValue.None

    /** Dishes on every wine's list; none when a wine has no list or an empty one. */
    private fun sharedIds(pairings: List<List<DishLabel>?>): Set<String> {
        if (pairings.any { it.isNullOrEmpty() }) return emptySet()
        return pairings.map { list -> list.orEmpty().map { it.id }.toSet() }.reduce { acc, ids -> acc intersect ids }
    }

    private fun isDifferent(values: List<CompareValue>): Boolean {
        if (values.any { it == CompareValue.Pending }) return false
        val keys = values.map { value ->
            when (value) {
                is CompareValue.Text -> value.value.lowercase()
                is CompareValue.Color -> "${value.color}|${value.isSparkling == true}"
                is CompareValue.Sugar -> value.sugar.name
                is CompareValue.Temperature -> "${value.range.minC}-${value.range.maxC}"
                is CompareValue.Pairings -> value.dishes.map { it.id }.sorted().joinToString("|")
                CompareValue.Pending, CompareValue.None -> null
            }
        }
        return keys.distinct().size > 1
    }
}
