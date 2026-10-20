package com.aiweapps.core.database

import android.content.Context
import androidx.room.Room
import androidx.room.RoomDatabase

actual class DatabaseBuilderProvider(@PublishedApi internal val context: Context)

actual inline fun <reified T : RoomDatabase> DatabaseBuilderProvider.databaseBuilder(
    name: String,
): RoomDatabase.Builder<T> {
    val dbFile = context.getDatabasePath(name)
    return Room.databaseBuilder<T>(
        context = context,
        name = dbFile.absolutePath,
    )
}
