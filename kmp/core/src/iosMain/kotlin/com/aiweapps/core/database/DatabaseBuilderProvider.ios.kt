package com.aiweapps.core.database

import androidx.room.Room
import androidx.room.RoomDatabase
import kotlinx.cinterop.ExperimentalForeignApi
import platform.Foundation.NSDocumentDirectory
import platform.Foundation.NSFileManager
import platform.Foundation.NSUserDomainMask

actual class DatabaseBuilderProvider

@OptIn(ExperimentalForeignApi::class)
actual inline fun <reified T : RoomDatabase> DatabaseBuilderProvider.databaseBuilder(
    name: String,
): RoomDatabase.Builder<T> {
    val documentDirectory = NSFileManager.defaultManager.URLForDirectory(
        directory = NSDocumentDirectory,
        inDomain = NSUserDomainMask,
        appropriateForURL = null,
        create = false,
        error = null,
    )
    val dbFile = requireNotNull(documentDirectory?.path) + "/$name"
    return Room.databaseBuilder<T>(name = dbFile)
}
