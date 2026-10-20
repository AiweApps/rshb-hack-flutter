package com.aiweapps.winescan.data.pairing.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import kotlinx.serialization.Serializable

/** A dish choice the user kept, with the matching cards frozen as JSON at that moment. */
@Entity(tableName = "saved_pairings")
data class SavedPairingEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    /** The dish label in the default language; the whole dish lives in [snapshotJson]. */
    val dish: String,
    /** The matching [com.aiweapps.winescan.domain.scan.model.WineCard]s, JSON-encoded. */
    val winesJson: String,
    val createdAt: Long,
    /** A [SavedPairingSnapshot], JSON-encoded; `null` for a row saved before version 3. */
    val snapshotJson: String? = null,
)

/** What a saved choice needs to render offline besides the cards. */
@Serializable
internal data class SavedPairingSnapshot(
    val dish: Dish,
    val gastronomy: List<WineGastronomy>,
    val dishes: List<Dish>,
    /** How many wines the choice was made among; absent in a snapshot written before it was kept. */
    val compareSetSize: Int? = null,
)
