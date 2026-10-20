package com.aiweapps.winescan.domain.pairing.repository

import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.pairing.model.SavedPairing
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlinx.coroutines.flow.Flow

/**
 * Dish choices the user saved. Strategy: local-only; [watchAll] streams from the database
 * so the history tab shows a new choice the moment it is kept.
 */
interface SavedPairingRepository {

    /** Newest first. */
    fun watchAll(): Flow<List<SavedPairing>>

    suspend fun byId(id: Long): SavedPairing?

    /**
     * [dishes] are the labels of every dish [gastronomy] lists, so the choice renders offline.
     * [compareSetSize] is how many wines the choice was made among; [wines] are the matching ones.
     */
    suspend fun save(
        dish: Dish,
        wines: List<WineCard>,
        gastronomy: Map<String, WineGastronomy>,
        dishes: List<Dish>,
        compareSetSize: Int,
    ): Long

    suspend fun delete(id: Long)
}
