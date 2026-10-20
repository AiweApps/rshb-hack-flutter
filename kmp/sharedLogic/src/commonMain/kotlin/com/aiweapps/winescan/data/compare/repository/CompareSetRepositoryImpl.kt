package com.aiweapps.winescan.data.compare.repository

import com.aiweapps.core.files.FileStore
import com.aiweapps.winescan.config.CompareLimits
import com.aiweapps.winescan.data.compare.dao.CompareEntryDao
import com.aiweapps.winescan.data.compare.model.CompareEntryEntity
import com.aiweapps.winescan.domain.compare.model.AddToCompareResult
import com.aiweapps.winescan.domain.compare.model.CompareCandidate
import com.aiweapps.winescan.domain.compare.model.CompareEntry
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.random.Random
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json

@OptIn(ExperimentalTime::class)
internal class CompareSetRepositoryImpl(
    private val dao: CompareEntryDao,
    private val photos: FileStore,
    private val json: Json,
    private val clock: Clock = Clock.System,
) : CompareSetRepository {

    private val mutationMutex = Mutex()

    override fun watch(): Flow<List<CompareEntry>> =
        dao.observeAll().map { rows -> rows.mapNotNull { it.toEntry() } }

    override suspend fun add(candidate: CompareCandidate): AddToCompareResult = mutationMutex.withLock {
        if (dao.bySlug(candidate.card.slug) != null) return@withLock AddToCompareResult.ALREADY_THERE
        if (dao.all().size >= CompareLimits.MAX_WINES) return@withLock AddToCompareResult.FULL
        val addedAt = clock.now().toEpochMilliseconds()
        val sourcePhoto = candidate.photoPath?.takeIf { it.isNotBlank() }
        require(sourcePhoto != null || !candidate.card.reference.isNullOrBlank())
        // No fake file is created for catalogue-only cards. The old SQL column stays
        // compatible; only its explicit empty sentinel maps to a nullable domain source.
        val photoName = if (sourcePhoto != null)
            "$addedAt-${Random.nextLong().toULong().toString(16)}$PHOTO_EXTENSION" else ""
        try {
            if (sourcePhoto != null) {
                val originalBytes = photos.readBytes(sourcePhoto)
                check(originalBytes != null && originalBytes.isNotEmpty()) { "comparison_source_unreadable" }
                // The planned name is known even if a platform copy throws or is cancelled.
                // Some native implementations return a name after a failed copy, so verify
                // the actual owned file byte-for-byte before committing its database row.
                photos.copy(sourcePhoto, name = photoName)
                val ownedBytes = photos.readBytes(photos.pathFor(photoName))
                check(ownedBytes != null && originalBytes.contentEquals(ownedBytes)) { "comparison_copy_unverified" }
            }
            dao.insert(
                CompareEntryEntity(
                    slug = candidate.card.slug,
                    cardJson = json.encodeToString(candidate.card),
                    photoName = photoName,
                    cropJson = candidate.crop?.let { json.encodeToString(it) },
                    frameWidth = candidate.frame?.getOrNull(0),
                    frameHeight = candidate.frame?.getOrNull(1),
                    scanId = candidate.scanId,
                    addedAt = addedAt,
                )
            )
        } catch (error: CancellationException) {
            discardUncommittedPhoto(candidate.card.slug, photoName)
            throw error
        } catch (error: Exception) {
            discardUncommittedPhoto(candidate.card.slug, photoName)
            throw error
        }
        AddToCompareResult.ADDED
    }

    override suspend fun remove(slug: String) = mutationMutex.withLock {
        val row = dao.bySlug(slug) ?: return@withLock
        dao.deleteBySlug(slug)
        if (row.photoName.isNotEmpty()) photos.delete(row.photoName)
    }

    override suspend fun clear() = mutationMutex.withLock {
        dao.deleteAll()
        photos.deleteAll()
    }

    private suspend fun discardUncommittedPhoto(slug: String, photoName: String) {
        if (photoName.isEmpty()) return
        withContext(NonCancellable) {
            try {
                // Room can commit before cancellation reaches the caller. Keep a file
                // already referenced by that committed row instead of breaking its image.
                if (dao.bySlug(slug)?.photoName != photoName) photos.delete(photoName)
            } catch (error: CancellationException) { throw error }
            catch (_: Exception) {
                // An unreadable row cannot prove the copy unused; preserve it and the original error.
            }
        }
    }

    private suspend fun CompareEntryEntity.toEntry(): CompareEntry? {
        val card = decode<WineCard>(cardJson) ?: return null
        val frame = if (frameWidth != null && frameHeight != null) listOf(frameWidth, frameHeight) else null
        return CompareEntry(
            card = card,
            photoPath = photoName.takeIf { it.isNotBlank() }?.let { photos.pathFor(it) },
            crop = cropJson?.let { decode<BottleBox>(it) },
            frame = frame,
            scanId = scanId,
            addedAtMillis = addedAt,
        )
    }

    // A row whose JSON no longer parses (an old shape of the card) is skipped, not fatal.
    private inline fun <reified T> decode(value: String): T? = try {
        json.decodeFromString<T>(value)
    } catch (_: SerializationException) {
        null
    } catch (_: IllegalArgumentException) {
        null
    }

    private companion object {
        const val PHOTO_EXTENSION = ".jpg"
    }
}
