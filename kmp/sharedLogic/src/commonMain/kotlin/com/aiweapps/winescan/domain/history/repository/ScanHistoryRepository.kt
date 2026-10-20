package com.aiweapps.winescan.domain.history.repository

import com.aiweapps.winescan.domain.history.model.ScanHistoryItem
import com.aiweapps.winescan.domain.history.model.ScanRecord
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import kotlinx.coroutines.flow.Flow

/**
 * Scans kept on the device: rows in the database, photos in the file store.
 *
 * Strategy: local-only. The list is a stream from the database, so every screen showing
 * it updates itself when a scan is added or removed.
 */
interface ScanHistoryRepository {

    fun watchAll(): Flow<List<ScanHistoryItem>>

    fun watchRecent(limit: Int): Flow<List<ScanHistoryItem>>

    /** `null` when the scan is gone, or when its stored answer no longer parses. */
    suspend fun byId(id: Long): ScanRecord?

    /** Takes ownership of the photo at [photoPath] and stores the answer. */
    suspend fun save(photoPath: String, view: RecognitionView): Long

    /** Stores the answer while leaving an assistant-owned photo in place. */
    suspend fun saveCopy(photoPath: String, view: RecognitionView): Long = save(photoPath, view)

    suspend fun delete(id: Long)

    suspend fun clear()
}
