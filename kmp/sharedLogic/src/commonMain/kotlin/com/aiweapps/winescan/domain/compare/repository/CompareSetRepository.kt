package com.aiweapps.winescan.domain.compare.repository

import com.aiweapps.winescan.domain.compare.model.AddToCompareResult
import com.aiweapps.winescan.domain.compare.model.CompareCandidate
import com.aiweapps.winescan.domain.compare.model.CompareEntry
import kotlinx.coroutines.flow.Flow

/**
 * The wines picked for comparison: rows in the database, the set's own copies of the
 * photos in its file store, so a cleared history does not empty the comparison.
 *
 * Strategy: local-only, the database is the source of truth and [watch] is a stream from
 * it, so every screen with a «Compare · N» pill follows adds and removals by itself.
 */
interface CompareSetRepository {

    /** Oldest first: the order the table shows them in. */
    fun watch(): Flow<List<CompareEntry>>

    /** Adds the wine unless the set is full or already has that slug; nothing is copied in those cases. */
    suspend fun add(candidate: CompareCandidate): AddToCompareResult

    suspend fun remove(slug: String)

    suspend fun clear()
}
