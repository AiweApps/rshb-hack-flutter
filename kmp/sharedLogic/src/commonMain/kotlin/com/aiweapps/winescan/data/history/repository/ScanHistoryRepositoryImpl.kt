package com.aiweapps.winescan.data.history.repository

import com.aiweapps.core.files.FileStore
import com.aiweapps.winescan.data.history.dao.ScanHistoryDao
import com.aiweapps.winescan.data.history.model.ScanHistoryEntity
import com.aiweapps.winescan.data.history.model.toItem
import com.aiweapps.winescan.domain.history.model.ScanHistoryItem
import com.aiweapps.winescan.domain.history.model.ScanRecord
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlin.random.Random

@OptIn(ExperimentalTime::class)
internal class ScanHistoryRepositoryImpl(
    private val dao: ScanHistoryDao,
    private val photos: FileStore,
    private val json: Json,
    private val clock: Clock = Clock.System,
) : ScanHistoryRepository {

    override fun watchAll(): Flow<List<ScanHistoryItem>> = dao.observeAll().map { toItems(it) }

    override fun watchRecent(limit: Int): Flow<List<ScanHistoryItem>> =
        dao.observeRecent(limit).map { toItems(it) }

    override suspend fun byId(id: Long): ScanRecord? {
        val row = dao.byId(id) ?: return null
        val view = try {
            json.decodeFromString<RecognitionView>(row.viewJson)
        } catch (_: SerializationException) {
            // An unsupported old answer is unavailable to this reader, not disposable:
            // keep both its raw JSON and photo for recovery or a compatible app version.
            return null
        } catch (_: IllegalArgumentException) {
            return null
        }
        return ScanRecord(
            id = row.id,
            createdAtMillis = row.createdAt,
            photoPath = photos.pathFor(row.photoName),
            view = view,
        )
    }

    override suspend fun save(photoPath: String, view: RecognitionView): Long {
        return saveInternal(photoPath, view, copyPhoto = false)
    }

    override suspend fun saveCopy(photoPath: String, view: RecognitionView): Long {
        return saveInternal(photoPath, view, copyPhoto = true)
    }

    private suspend fun saveInternal(photoPath: String, view: RecognitionView, copyPhoto: Boolean): Long {
        val createdAt = clock.now().toEpochMilliseconds()
        val storedName = if (copyPhoto) photos.copy(
            photoPath, name = "$createdAt-${Random.nextLong().toULong().toString(16)}$PHOTO_EXTENSION"
        )
        else photos.keep(photoPath, name = "$createdAt$PHOTO_EXTENSION")
        val best = view.bottles.firstOrNull()?.best
        return dao.insert(
            ScanHistoryEntity(
                createdAt = createdAt,
                photoName = storedName,
                viewJson = json.encodeToString(view),
                bestTitle = best?.title,
                bestProducer = best?.producer,
                bestSlug = best?.slug,
                bestReference = best?.reference,
                bottleCount = view.bottles.size,
            )
        )
    }

    override suspend fun delete(id: Long) {
        val row = dao.byId(id) ?: return
        dao.deleteById(id)
        photos.delete(row.photoName)
    }

    override suspend fun clear() {
        dao.deleteAll()
        photos.deleteAll()
    }

    private suspend fun toItems(rows: List<ScanHistoryEntity>): List<ScanHistoryItem> =
        rows.map { it.toItem(photoPath = photos.pathFor(it.photoName)) }

    private companion object {
        const val PHOTO_EXTENSION = ".jpg"
    }
}
