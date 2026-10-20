package com.aiweapps.winescan.data.database

import androidx.room.ConstructedBy
import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.RoomDatabaseConstructor
import com.aiweapps.winescan.data.compare.dao.CompareEntryDao
import com.aiweapps.winescan.data.compare.model.CompareEntryEntity
import com.aiweapps.winescan.data.assistant.local.AssistantConversationEntity
import com.aiweapps.winescan.data.assistant.local.AssistantDraftAttachmentEntity
import com.aiweapps.winescan.data.assistant.local.AssistantLocalDao
import com.aiweapps.winescan.data.assistant.local.AssistantMessageEntity
import com.aiweapps.winescan.data.assistant.local.AssistantPhotoEntity
import com.aiweapps.winescan.data.assistant.local.AssistantSavedWineEntity
import com.aiweapps.winescan.data.history.dao.ScanHistoryDao
import com.aiweapps.winescan.data.history.model.ScanHistoryEntity
import com.aiweapps.winescan.data.pairing.dao.SavedPairingDao
import com.aiweapps.winescan.data.pairing.model.SavedPairingEntity

@Database(
    entities = [
        ScanHistoryEntity::class, CompareEntryEntity::class, SavedPairingEntity::class,
        AssistantConversationEntity::class, AssistantMessageEntity::class,
        AssistantPhotoEntity::class, AssistantDraftAttachmentEntity::class,
        AssistantSavedWineEntity::class,
    ],
    version = 4,
)
@ConstructedBy(AppDatabaseConstructor::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun scanHistoryDao(): ScanHistoryDao
    abstract fun compareEntryDao(): CompareEntryDao
    abstract fun savedPairingDao(): SavedPairingDao
    abstract fun assistantLocalDao(): AssistantLocalDao
}

@Suppress("NO_ACTUAL_FOR_EXPECT")
expect object AppDatabaseConstructor : RoomDatabaseConstructor<AppDatabase> {
    override fun initialize(): AppDatabase
}
