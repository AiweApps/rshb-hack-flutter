package com.aiweapps.winescan.domain.scan.model

import com.aiweapps.winescan.domain.compare.model.CompareCandidate
import kotlinx.serialization.Serializable

/**
 * One bottle on the user's photo: the photo, where the bottle is in it, and its stored scan.
 * Serializable because a screen opened for that bottle carries it as its navigation argument.
 */
@Serializable
data class BottlePhoto(
    val photoPath: String,
    val crop: BottleBox?,
    /** The frame [crop] refers to. */
    val frame: List<Int>?,
    val bottleNumber: Int,
    /** The stored scan the photo belongs to, once the answer is in the history. */
    val scanId: Long?,
) {
    /** What the comparison set needs to take [card] together with this bottle's photo. */
    fun toCompareCandidate(card: WineCard): CompareCandidate = CompareCandidate(
        card = card,
        photoPath = photoPath,
        crop = crop,
        frame = frame,
        scanId = scanId,
    )
}
