package com.aiweapps.core.database

import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO

expect class DatabaseBuilderProvider

expect inline fun <reified T : RoomDatabase> DatabaseBuilderProvider.databaseBuilder(
    name: String,
): RoomDatabase.Builder<T>

/**
 * The settings every database in this project shares.
 *
 * There is deliberately no `fallbackToDestructiveMigration` here: without an explicit
 * migration a version bump would wipe the user's data on update, and it would do it
 * silently. A missing migration must fail loudly instead — see `add-entity.md`.
 */
fun <T : RoomDatabase> RoomDatabase.Builder<T>.applyDefaults(
    migrations: List<Migration> = emptyList(),
): T {
    return this
        // Added one by one rather than spread into the vararg: a spread copies the array
        // on every call, and this runs on the startup path.
        .apply { migrations.forEach { addMigrations(it) } }
        .setDriver(BundledSQLiteDriver())
        .setQueryCoroutineContext(Dispatchers.IO)
        .build()
}
