package com.aiweapps.winescan.data.assistant.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
interface AssistantLocalDao {
    @Query("""
        SELECT EXISTS(SELECT 1 FROM assistant_conversations)
            OR EXISTS(SELECT 1 FROM assistant_messages)
            OR EXISTS(SELECT 1 FROM assistant_photos)
            OR EXISTS(SELECT 1 FROM assistant_draft_attachments)
            OR EXISTS(SELECT 1 FROM assistant_saved_wines)
    """)
    suspend fun hasAnyAssistantData(): Boolean

    @Query("SELECT * FROM assistant_conversations ORDER BY updatedAt DESC")
    fun watchConversations(): Flow<List<AssistantConversationEntity>>

    @Query("SELECT * FROM assistant_conversations WHERE id = :id")
    suspend fun conversation(id: String): AssistantConversationEntity?

    @Query("SELECT * FROM assistant_messages WHERE conversationId = :id ORDER BY position")
    suspend fun messages(id: String): List<AssistantMessageEntity>

    @Query("SELECT * FROM assistant_photos WHERE conversationId = :id")
    suspend fun photos(id: String): List<AssistantPhotoEntity>

    @Query("SELECT * FROM assistant_photos WHERE id = :photoId")
    suspend fun photo(photoId: String): AssistantPhotoEntity?

    @Query("SELECT * FROM assistant_draft_attachments WHERE conversationId = :id ORDER BY position")
    suspend fun draftAttachments(id: String): List<AssistantDraftAttachmentEntity>

    @Query("SELECT * FROM assistant_saved_wines ORDER BY position")
    suspend fun savedWines(): List<AssistantSavedWineEntity>

    @Query("SELECT payloadJson FROM assistant_messages")
    suspend fun messagePayloads(): List<String>

    @Query("SELECT EXISTS(SELECT 1 FROM assistant_draft_attachments WHERE photoId = :photoId)")
    suspend fun hasDraftReference(photoId: String): Boolean

    @Query("SELECT EXISTS(SELECT 1 FROM assistant_saved_wines WHERE photoId = :photoId)")
    suspend fun hasSavedWineReference(photoId: String): Boolean

    @Query("SELECT EXISTS(SELECT 1 FROM assistant_conversations WHERE selectedWinePhotoId = :photoId)")
    suspend fun hasSelectedWineReference(photoId: String): Boolean

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertConversation(row: AssistantConversationEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertPhoto(row: AssistantPhotoEntity)

    @Insert
    suspend fun insertMessages(rows: List<AssistantMessageEntity>)

    @Insert
    suspend fun insertDraftAttachments(rows: List<AssistantDraftAttachmentEntity>)

    @Insert
    suspend fun insertSavedWines(rows: List<AssistantSavedWineEntity>)

    @Query("DELETE FROM assistant_messages WHERE conversationId = :id")
    suspend fun deleteMessages(id: String)

    @Query("DELETE FROM assistant_draft_attachments WHERE conversationId = :id")
    suspend fun deleteDraftAttachments(id: String)

    @Query("DELETE FROM assistant_conversations WHERE id = :id")
    suspend fun deleteConversation(id: String)

    @Query("DELETE FROM assistant_photos WHERE id = :photoId")
    suspend fun deletePhoto(photoId: String)

    @Query("DELETE FROM assistant_saved_wines")
    suspend fun deleteSavedWines()

    @Transaction
    suspend fun replaceConversation(
        row: AssistantConversationEntity,
        messages: List<AssistantMessageEntity>,
        attachments: List<AssistantDraftAttachmentEntity>,
    ) {
        upsertConversation(row)
        deleteMessages(row.id)
        if (messages.isNotEmpty()) insertMessages(messages)
        deleteDraftAttachments(row.id)
        if (attachments.isNotEmpty()) insertDraftAttachments(attachments)
    }

    @Transaction
    suspend fun replaceSavedWines(rows: List<AssistantSavedWineEntity>) {
        deleteSavedWines()
        if (rows.isNotEmpty()) insertSavedWines(rows)
    }

    @Transaction
    suspend fun removeConversation(id: String) {
        deleteMessages(id)
        deleteDraftAttachments(id)
        deleteConversation(id)
    }
}
