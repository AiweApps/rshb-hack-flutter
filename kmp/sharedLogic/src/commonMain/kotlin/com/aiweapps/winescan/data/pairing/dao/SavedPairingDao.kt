package com.aiweapps.winescan.data.pairing.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.aiweapps.winescan.data.pairing.model.SavedPairingEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface SavedPairingDao {

    @Query("SELECT * FROM saved_pairings ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<SavedPairingEntity>>

    @Query("SELECT * FROM saved_pairings WHERE id = :id")
    suspend fun byId(id: Long): SavedPairingEntity?

    @Insert
    suspend fun insert(entity: SavedPairingEntity): Long

    @Query("DELETE FROM saved_pairings WHERE id = :id")
    suspend fun deleteById(id: Long)
}
