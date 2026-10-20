package com.aiweapps.winescan.data.compare.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.aiweapps.winescan.data.compare.model.CompareEntryEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface CompareEntryDao {

    @Query("SELECT * FROM compare_entries ORDER BY addedAt ASC")
    fun observeAll(): Flow<List<CompareEntryEntity>>

    @Query("SELECT * FROM compare_entries ORDER BY addedAt ASC")
    suspend fun all(): List<CompareEntryEntity>

    @Query("SELECT * FROM compare_entries WHERE slug = :slug")
    suspend fun bySlug(slug: String): CompareEntryEntity?

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(entity: CompareEntryEntity)

    @Query("DELETE FROM compare_entries WHERE slug = :slug")
    suspend fun deleteBySlug(slug: String)

    @Query("DELETE FROM compare_entries")
    suspend fun deleteAll()
}
