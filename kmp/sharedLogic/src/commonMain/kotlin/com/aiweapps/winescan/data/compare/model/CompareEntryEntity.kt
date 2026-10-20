package com.aiweapps.winescan.data.compare.model

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * One wine of the comparison set. The slug is the key: the same card cannot be added twice.
 * The card and the crop are kept as JSON, the way the history keeps the answer, so the
 * table never has to follow the card's fields.
 */
@Entity(tableName = "compare_entries")
data class CompareEntryEntity(
    @PrimaryKey val slug: String,
    /** The [com.aiweapps.winescan.domain.scan.model.WineCard], JSON-encoded. */
    val cardJson: String,
    /** Owned photo name; empty means source-reference-only. The adapter maps that sentinel to null, never a path. */
    val photoName: String,
    /** The bottle box as a JSON array, `null` when the answer had none. */
    val cropJson: String?,
    val frameWidth: Int?,
    val frameHeight: Int?,
    val scanId: Long?,
    val addedAt: Long,
)
