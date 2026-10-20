package com.aiweapps.winescan.domain.compare.model

import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlinx.serialization.Serializable

/**
 * One wine in the comparison set: the catalogue card the user picked and the photo it was
 * recognised from. The set holds at most [com.aiweapps.winescan.config.CompareLimits.MAX_WINES]
 * entries and never two with the same [WineCard.slug].
 */
@Serializable
data class CompareEntry(
    val card: WineCard,
    /** The set's own photo copy, or null for a source catalogue reference without a user photo. */
    val photoPath: String? = null,
    /** Where the bottle is in the photo, when the answer said. */
    val crop: BottleBox?,
    /** The frame every box refers to. */
    val frame: List<Int>?,
    /** The stored scan it came from, when that scan was stored. */
    val scanId: Long?,
    val addedAtMillis: Long,
) {
    val slug: String get() = card.slug
}

/** What a screen hands over to add a wine: the card and the photo it was found in. */
data class CompareCandidate(
    val card: WineCard,
    val photoPath: String? = null,
    val crop: BottleBox?,
    val frame: List<Int>?,
    val scanId: Long?,
)

/** Why an add did or did not change the set. */
enum class AddToCompareResult { ADDED, ALREADY_THERE, FULL }
