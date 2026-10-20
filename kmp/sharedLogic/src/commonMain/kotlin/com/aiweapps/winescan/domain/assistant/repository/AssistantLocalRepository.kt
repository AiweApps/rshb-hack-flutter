package com.aiweapps.winescan.domain.assistant.repository

import com.aiweapps.winescan.domain.assistant.model.AssistantConversation
import com.aiweapps.winescan.domain.assistant.model.AssistantMessage
import com.aiweapps.winescan.domain.assistant.model.AssistantPhoto
import com.aiweapps.winescan.domain.assistant.model.AssistantWine
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/** Null subject is the pre-account local collection, never a replacement guest. */
data class AssistantSavedWinesSnapshot(val subject: String?, val wines: List<AssistantWine>)

/** One local conversation. A remote session is optional and can be recreated. */
data class AssistantLocalState(
    val id: String,
    val title: String,
    val messages: List<AssistantMessage> = emptyList(),
    val draft: String = "",
    val attachments: List<AssistantPhoto> = emptyList(),
    val remoteSessionId: String? = null,
    val selectedWinePhotoId: String? = null,
    val selectedWineInstanceId: String? = null,
    val selectedWineSlug: String? = null,
    val selectedStoreId: Int? = null,
)

/** Durable chat data; photo paths are resolved when read and never stored in Room. */
interface AssistantLocalRepository {
    /** Across all identities, including legacy/orphaned photos; never a scoped history check. */
    suspend fun hasAnyAssistantData(): Boolean

    fun watchConversations(): Flow<List<AssistantConversation>>

    suspend fun load(conversationId: String): AssistantLocalState?

    suspend fun save(state: AssistantLocalState)

    suspend fun delete(conversationId: String)

    suspend fun loadSavedWines(): List<AssistantWine>

    suspend fun saveSavedWines(wines: List<AssistantWine>)

    /**
     * The current identity's saved wines («My wines»), read again after every write and on
     * every change of identity, so the assistant and the history show the same hearts.
     */
    fun watchSavedWines(): Flow<List<AssistantWine>>

    /** Rewrites the saved wines from the stored ones in one step; returns what was written. */
    suspend fun updateSavedWines(transform: (List<AssistantWine>) -> List<AssistantWine>): List<AssistantWine>

    /** Capture at the user intent, before launching work or waiting for a scan/mutex. */
    val savedWinesSubject: String? get() = null

    /** Legacy implementations have only the null/local owner; account-aware storage overrides this. */
    fun watchSavedWinesByOwner(): Flow<AssistantSavedWinesSnapshot> =
        watchSavedWines().map {
            check(savedWinesSubject == null) { "Account-aware saved wines require an owner-bound stream" }
            AssistantSavedWinesSnapshot(null, it)
        }

    /** Account-aware storage must use this same subject for both the read and the write. */
    suspend fun updateSavedWines(
        expectedSubject: String?,
        transform: (List<AssistantWine>) -> List<AssistantWine>,
    ): List<AssistantWine> {
        check(expectedSubject == null && savedWinesSubject == null) { "Account-aware saved wines require an owner-bound update" }
        return updateSavedWines { stored ->
            check(expectedSubject == savedWinesSubject) { "Saved wines owner changed" }
            transform(stored)
        }.also { check(expectedSubject == savedWinesSubject) { "Saved wines owner changed" } }
    }

    /** Copy picker bytes immediately into the assistant's private photo store. */
    suspend fun copyPhoto(conversationId: String, photo: AssistantPhoto): AssistantPhoto

    /** Remove a withdrawn draft photo only if no saved content still uses it. */
    suspend fun deleteDraftPhoto(conversationId: String, photoId: String)

    suspend fun resolvePhotoPath(photoId: String): String?
}
