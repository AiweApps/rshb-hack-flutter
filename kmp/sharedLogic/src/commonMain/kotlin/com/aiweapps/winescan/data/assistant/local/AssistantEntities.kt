package com.aiweapps.winescan.data.assistant.local

import androidx.room.Entity
import androidx.room.Index

@Entity(tableName = "assistant_conversations")
data class AssistantConversationEntity(
    @androidx.room.PrimaryKey val id: String,
    val title: String,
    val lastMessage: String,
    val draft: String,
    val remoteSessionId: String?,
    val selectedWinePhotoId: String?,
    val selectedWineInstanceId: String?,
    val selectedWineSlug: String?,
    val selectedStoreId: Int?,
    val createdAt: Long,
    val updatedAt: Long,
)

@Entity(
    tableName = "assistant_messages",
    primaryKeys = ["conversationId", "id"],
    indices = [Index(value = ["conversationId", "position"], unique = true)],
)
data class AssistantMessageEntity(
    val id: String,
    val conversationId: String,
    val position: Int,
    val payloadJson: String,
)

@Entity(tableName = "assistant_photos", indices = [Index(value = ["conversationId"])])
data class AssistantPhotoEntity(
    @androidx.room.PrimaryKey val id: String,
    val conversationId: String,
    val fileName: String,
    val displayName: String,
    val mimeType: String?,
    val createdAt: Long,
)

@Entity(tableName = "assistant_draft_attachments", primaryKeys = ["conversationId", "position"])
data class AssistantDraftAttachmentEntity(
    val conversationId: String,
    val position: Int,
    val photoId: String,
)

@Entity(tableName = "assistant_saved_wines")
data class AssistantSavedWineEntity(
    @androidx.room.PrimaryKey val position: Int,
    val slug: String,
    val photoId: String?,
    val instanceId: String?,
    val payloadJson: String,
)
