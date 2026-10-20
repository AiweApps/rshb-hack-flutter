package com.aiweapps.winescan.data.assistant.local

import com.aiweapps.core.files.FileStore
import com.aiweapps.winescan.domain.assistant.model.AssistantConversation
import com.aiweapps.winescan.domain.assistant.model.AssistantMessage
import com.aiweapps.winescan.domain.assistant.model.AssistantPhoto
import com.aiweapps.winescan.domain.assistant.model.AssistantWine
import com.aiweapps.winescan.domain.assistant.repository.AssistantLocalRepository
import com.aiweapps.winescan.domain.assistant.repository.AssistantLocalState
import com.aiweapps.winescan.domain.assistant.repository.AssistantSavedWinesSnapshot
import kotlin.random.Random
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.coroutines.cancellation.CancellationException
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.transformLatest
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json

@OptIn(ExperimentalTime::class)
internal class AssistantLocalRepositoryImpl(
    private val dao: AssistantLocalDao,
    private val photos: FileStore,
    private val json: Json,
    private val accounts: com.aiweapps.winescan.domain.assistant.repository.AssistantAccountRepository,
    private val preferences: com.aiweapps.core.storage.KeyValueStorage,
    /** Wines saved from the history have no assistant photo: they show their scan's. */
    private val history: ScanHistoryRepository,
    private val clock: Clock = Clock.System,
) : AssistantLocalRepository {

    private val writeMutex = Mutex()

    /** Bumped after every write of the saved wines, so their watchers read them again. */
    private val savedWinesRevision = MutableStateFlow(0L)

    override val savedWinesSubject: String? get() = accounts.account.value?.subject

    override suspend fun hasAnyAssistantData(): Boolean = dao.hasAnyAssistantData()

    override fun watchConversations(): Flow<List<AssistantConversation>> =
        dao.watchConversations().map { rows ->
            val subject = accounts.account.value?.subject
            rows.filter { owns(it.id, subject) }.map { AssistantConversation(it.id, it.title, it.lastMessage) }
        }

    override suspend fun load(conversationId: String): AssistantLocalState? {
        if (!owns(conversationId, accounts.account.value?.subject)) return null
        val row = dao.conversation(conversationId) ?: return null
        val attachments = dao.draftAttachments(conversationId).mapNotNull { item ->
            dao.photo(item.photoId)?.toDomain()
        }
        return AssistantLocalState(
            id = row.id,
            title = row.title,
            messages = dao.messages(conversationId).mapNotNull { entity ->
                try {
                    resolveMessage(json.decodeFromString<AssistantMessage>(entity.payloadJson))
                } catch (_: SerializationException) {
                    null
                } catch (_: IllegalArgumentException) {
                    null
                }
            },
            draft = row.draft,
            attachments = attachments,
            remoteSessionId = row.remoteSessionId,
            selectedWinePhotoId = row.selectedWinePhotoId,
            selectedWineInstanceId = row.selectedWineInstanceId,
            selectedWineSlug = row.selectedWineSlug,
            selectedStoreId = row.selectedStoreId,
        )
    }

    override suspend fun save(state: AssistantLocalState) = writeMutex.withLock {
        require(state.id.isNotBlank())
        val now = clock.now().toEpochMilliseconds()
        val lastMessage = state.messages.lastOrNull()?.text.orEmpty().take(PREVIEW_LENGTH)
        val row = AssistantConversationEntity(
            id = state.id,
            title = state.title,
            lastMessage = lastMessage,
            draft = state.draft,
            remoteSessionId = state.remoteSessionId,
            selectedWinePhotoId = state.selectedWinePhotoId,
            selectedWineInstanceId = state.selectedWineInstanceId,
            selectedWineSlug = state.selectedWineSlug,
            selectedStoreId = state.selectedStoreId,
            createdAt = dao.conversation(state.id)?.createdAt ?: now,
            updatedAt = now,
        )
        dao.replaceConversation(
            row = row,
            messages = state.messages.mapIndexed { position, message ->
                AssistantMessageEntity(
                    id = message.id,
                    conversationId = state.id,
                    position = position,
                    payloadJson = json.encodeToString(message.withoutPaths()),
                )
            },
            attachments = state.attachments.mapIndexed { position, photo ->
                AssistantDraftAttachmentEntity(state.id, position, photo.id)
            },
        )
    }

    override suspend fun delete(conversationId: String) = writeMutex.withLock {
        val savedPhotoIds = (dao.savedWines().mapNotNull { it.photoId } + loadSavedWines().mapNotNull { it.photoId }).toSet()
        val unused = dao.photos(conversationId).filterNot { it.id in savedPhotoIds }
        dao.removeConversation(conversationId)
        // Keep photo metadata and bytes if a saved wine still points at this conversation.
        unused.forEach { photo ->
            dao.deletePhoto(photo.id)
            photos.delete(photo.fileName)
        }
    }

    override suspend fun loadSavedWines(): List<AssistantWine> {
        val subject = savedWinesSubject
        return readSavedWines(subject).also { requireSavedWinesOwner(subject) }
    }

    private suspend fun readSavedWines(subject: String?): List<AssistantWine> {
        if (subject != null) return preferences.getString(
            com.aiweapps.winescan.data.storage.StorageKeys.ASSISTANT_SAVED_WINES + subject,
        )?.let { runCatching { json.decodeFromString<List<AssistantWine>>(it) }.getOrNull() }.orEmpty()
            .map { resolveWine(it) }
        return dao.savedWines().mapNotNull { row ->
            try {
                resolveWine(json.decodeFromString<AssistantWine>(row.payloadJson))
            } catch (_: SerializationException) {
                null
            } catch (_: IllegalArgumentException) {
                null
            }
        }
    }

    override suspend fun saveSavedWines(wines: List<AssistantWine>) {
        val subject = savedWinesSubject
        writeMutex.withLock {
            requireSavedWinesOwner(subject)
            writeSavedWines(subject, wines)
        }
    }

    override fun watchSavedWines(): Flow<List<AssistantWine>> =
        watchSavedWinesByOwner().map { it.wines }

    @OptIn(ExperimentalCoroutinesApi::class)
    override fun watchSavedWinesByOwner(): Flow<AssistantSavedWinesSnapshot> =
        accounts.account.map { it?.subject }.distinctUntilChanged().flatMapLatest { subject ->
            flow {
                // Clear the old owner's hearts before resolving the new owner's photos.
                if (savedWinesSubject == subject) emit(AssistantSavedWinesSnapshot(subject, emptyList()))
                emitAll(savedWinesRevision.transformLatest { revision ->
                    if (savedWinesSubject != subject) return@transformLatest
                    val wines = readSavedWines(subject)
                    if (savedWinesSubject == subject && savedWinesRevision.value == revision) {
                        emit(AssistantSavedWinesSnapshot(subject, wines))
                    }
                })
            }
        }

    override suspend fun updateSavedWines(
        transform: (List<AssistantWine>) -> List<AssistantWine>,
    ): List<AssistantWine> = updateSavedWines(savedWinesSubject, transform)

    override suspend fun updateSavedWines(
        expectedSubject: String?,
        transform: (List<AssistantWine>) -> List<AssistantWine>,
    ): List<AssistantWine> = writeMutex.withLock {
        requireSavedWinesOwner(expectedSubject)
        val stored = readSavedWines(expectedSubject)
        requireSavedWinesOwner(expectedSubject)
        transform(stored).also { writeSavedWines(expectedSubject, it) }
    }

    private suspend fun writeSavedWines(subject: String?, wines: List<AssistantWine>) {
        try {
            requireSavedWinesOwner(subject)
            storeSavedWines(subject, wines)
            requireSavedWinesOwner(subject)
        } finally {
            savedWinesRevision.value += 1
        }
    }

    private fun requireSavedWinesOwner(subject: String?) {
        if (savedWinesSubject != subject) throw CancellationException("Saved wines owner changed")
    }

    private suspend fun storeSavedWines(subject: String?, wines: List<AssistantWine>) {
        if (subject != null) {
            preferences.putString(com.aiweapps.winescan.data.storage.StorageKeys.ASSISTANT_SAVED_WINES + subject,
                json.encodeToString(wines.map { it.copy(photoPath = null) }))
            return
        }
        dao.replaceSavedWines(wines.mapIndexed { position, wine ->
            AssistantSavedWineEntity(
                position = position,
                slug = wine.slug,
                photoId = wine.photoId,
                instanceId = wine.instanceId,
                payloadJson = json.encodeToString(wine.copy(photoPath = null)),
            )
        })
    }

    override suspend fun copyPhoto(conversationId: String, photo: AssistantPhoto): AssistantPhoto = writeMutex.withLock {
        require(conversationId.isNotBlank() && photo.id.isNotBlank() && photo.path.isNotBlank())
        val existing = dao.photo(photo.id)
        if (existing != null) {
            require(existing.conversationId == conversationId) { "Photo ID belongs to another conversation" }
            return existing.toDomain()
        }
        val extension = photo.name.substringAfterLast('.', "").lowercase()
            .takeIf { it in PHOTO_EXTENSIONS } ?: DEFAULT_EXTENSION
        val fileName = "${clock.now().toEpochMilliseconds()}-${Random.nextLong().toULong().toString(16)}.$extension"
        photos.copy(photo.path, fileName)
        val storedPath = photos.pathFor(fileName)
        require(photos.readBytes(storedPath) != null) { "Photo copy failed" }
        val row = AssistantPhotoEntity(
            id = photo.id,
            conversationId = conversationId,
            fileName = fileName,
            displayName = photo.name.substringAfterLast('/'),
            mimeType = when (extension) {
                "png" -> "image/png"
                "heic" -> "image/heic"
                "webp" -> "image/webp"
                else -> "image/jpeg"
            },
            createdAt = clock.now().toEpochMilliseconds(),
        )
        try {
            dao.upsertPhoto(row)
        } catch (error: CancellationException) {
            photos.delete(fileName)
            throw error
        } catch (error: Exception) {
            photos.delete(fileName)
            throw error
        }
        return photo.copy(path = storedPath, name = row.displayName)
    }

    override suspend fun deleteDraftPhoto(conversationId: String, photoId: String) = writeMutex.withLock {
        val row = dao.photo(photoId) ?: return@withLock
        if (row.conversationId != conversationId) return@withLock
        if (loadSavedWines().any { it.photoId == photoId }) return@withLock
        if (dao.hasDraftReference(photoId) || dao.hasSavedWineReference(photoId) ||
            dao.hasSelectedWineReference(photoId)
        ) return@withLock
        val mentioned = dao.messagePayloads().any { payload ->
            val message = try {
                json.decodeFromString<AssistantMessage>(payload)
            } catch (_: SerializationException) {
                // A message we cannot read might still use this photo. Keep the bytes.
                return@withLock
            } catch (_: IllegalArgumentException) {
                return@withLock
            }
            message.photos.any { it.id == photoId } || message.wines.any { it.photoId == photoId }
        }
        if (mentioned) return@withLock
        dao.deletePhoto(photoId)
        photos.delete(row.fileName)
    }

    override suspend fun resolvePhotoPath(photoId: String): String? =
        dao.photo(photoId)?.let { photos.pathFor(it.fileName) }

    private suspend fun AssistantPhotoEntity.toDomain(): AssistantPhoto =
        AssistantPhoto(id, photos.pathFor(fileName), displayName)

    private suspend fun resolveMessage(message: AssistantMessage): AssistantMessage = message.copy(
        photos = message.photos.map { photo ->
            photo.copy(path = resolvePhotoPath(photo.id).orEmpty())
        },
        wines = message.wines.map { resolveWine(it) },
        // Reopened prices are a saved observation, never a fresh catalog read.
        source = if (message.source == "live_catalog") "saved_snapshot" else message.source,
    )

    private suspend fun resolveWine(wine: AssistantWine): AssistantWine =
        wine.copy(photoPath = wine.photoId?.let { resolvePhotoPath(it) } ?: wine.scanPhotoPath())

    private suspend fun AssistantWine.scanPhotoPath(): String? {
        val scanId = sourceScanId ?: return null
        return try {
            history.byId(scanId)?.photoPath
        } catch (e: CancellationException) {
            throw e
        } catch (_: Exception) {
            null
        }
    }

    private fun AssistantMessage.withoutPaths(): AssistantMessage = copy(
        photos = photos.map { it.copy(path = "") },
        wines = wines.map { it.copy(photoPath = null) },
    )

    private fun owns(id: String, subject: String?): Boolean =
        if (subject == null) !id.contains("::") else id.startsWith("$subject::")

    private companion object {
        const val PREVIEW_LENGTH = 160
        const val DEFAULT_EXTENSION = "jpg"
        val PHOTO_EXTENSIONS = setOf("jpg", "jpeg", "png", "heic", "webp")
    }
}
