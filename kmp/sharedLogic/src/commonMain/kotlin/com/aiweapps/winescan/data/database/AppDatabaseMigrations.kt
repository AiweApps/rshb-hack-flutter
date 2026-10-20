package com.aiweapps.winescan.data.database

import androidx.room.migration.Migration
import androidx.sqlite.SQLiteConnection
import androidx.sqlite.execSQL

/**
 * Every schema change of [AppDatabase] lands here, one [Migration] per version step.
 *
 * Adding an entity or a column means, in this order: change the `@Entity`, bump
 * `AppDatabase.version`, add the migration below, and commit the regenerated
 * `sharedLogic/schemas/<database>/<version>.json` — Room compares against that file, so an
 * uncommitted schema turns into a broken update for someone else.
 *
 * Version 3 shipped twice with different contents: the TestFlight scanner build added
 * `saved_pairings.snapshotJson`, the assistant build added the assistant tables. Version 4
 * is their union, and [from3To4] reads the database to find out which of the two it got.
 */
object AppDatabaseMigrations {

    private const val SAVED_PAIRINGS = "saved_pairings"
    private const val SNAPSHOT_COLUMN = "snapshotJson"

    // `PRAGMA table_info` columns: cid, name, type, notnull, dflt_value, pk.
    private const val TABLE_INFO_NAME_COLUMN = 1

    /** Version 2: the comparison set and the saved dish choices. The history is untouched. */
    private val from1To2 = object : Migration(1, 2) {
        override fun migrate(connection: SQLiteConnection) {
            connection.execSQL(
                "CREATE TABLE IF NOT EXISTS `compare_entries` (" +
                    "`slug` TEXT NOT NULL, `cardJson` TEXT NOT NULL, `photoName` TEXT NOT NULL, " +
                    "`cropJson` TEXT, `frameWidth` INTEGER, `frameHeight` INTEGER, `scanId` INTEGER, " +
                    "`addedAt` INTEGER NOT NULL, PRIMARY KEY(`slug`))"
            )
            connection.execSQL(
                "CREATE TABLE IF NOT EXISTS `saved_pairings` (" +
                    "`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `dish` TEXT NOT NULL, " +
                    "`winesJson` TEXT NOT NULL, `createdAt` INTEGER NOT NULL)"
            )
        }
    }

    /** Version 3 (the assistant build's shape): assistant chats, scanner data unchanged. */
    private val from2To3 = object : Migration(2, 3) {
        override fun migrate(connection: SQLiteConnection) {
            createAssistantTables(connection)
        }
    }

    /**
     * Version 4: the union of both version-3 shapes. Idempotent on purpose — it only adds
     * what the database lacks, so it upgrades the scanner build's v3 (no assistant tables)
     * and the assistant build's v3 (no `snapshotJson`) alike.
     */
    private val from3To4 = object : Migration(3, 4) {
        override fun migrate(connection: SQLiteConnection) {
            createAssistantTables(connection)
            if (!hasColumn(connection, SAVED_PAIRINGS, SNAPSHOT_COLUMN)) {
                connection.execSQL("ALTER TABLE `$SAVED_PAIRINGS` ADD COLUMN `$SNAPSHOT_COLUMN` TEXT")
            }
        }
    }

    val ALL: List<Migration> = listOf(from1To2, from2To3, from3To4)

    /** The assistant tables and indices exactly as Room declares them; safe to run twice. */
    private fun createAssistantTables(connection: SQLiteConnection) {
        connection.execSQL(
            "CREATE TABLE IF NOT EXISTS `assistant_conversations` (" +
                "`id` TEXT NOT NULL, `title` TEXT NOT NULL, `lastMessage` TEXT NOT NULL, " +
                "`draft` TEXT NOT NULL, `remoteSessionId` TEXT, `selectedWinePhotoId` TEXT, " +
                "`selectedWineInstanceId` TEXT, `selectedWineSlug` TEXT, `selectedStoreId` INTEGER, " +
                "`createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, PRIMARY KEY(`id`))"
        )
        connection.execSQL(
            "CREATE TABLE IF NOT EXISTS `assistant_messages` (" +
                "`id` TEXT NOT NULL, `conversationId` TEXT NOT NULL, `position` INTEGER NOT NULL, " +
                "`payloadJson` TEXT NOT NULL, PRIMARY KEY(`conversationId`, `id`))"
        )
        connection.execSQL(
            "CREATE UNIQUE INDEX IF NOT EXISTS `index_assistant_messages_conversationId_position` " +
                "ON `assistant_messages` (`conversationId`, `position`)"
        )
        connection.execSQL(
            "CREATE TABLE IF NOT EXISTS `assistant_photos` (" +
                "`id` TEXT NOT NULL, `conversationId` TEXT NOT NULL, `fileName` TEXT NOT NULL, " +
                "`displayName` TEXT NOT NULL, `mimeType` TEXT, `createdAt` INTEGER NOT NULL, " +
                "PRIMARY KEY(`id`))"
        )
        connection.execSQL(
            "CREATE INDEX IF NOT EXISTS `index_assistant_photos_conversationId` " +
                "ON `assistant_photos` (`conversationId`)"
        )
        connection.execSQL(
            "CREATE TABLE IF NOT EXISTS `assistant_draft_attachments` (" +
                "`conversationId` TEXT NOT NULL, `position` INTEGER NOT NULL, `photoId` TEXT NOT NULL, " +
                "PRIMARY KEY(`conversationId`, `position`))"
        )
        connection.execSQL(
            "CREATE TABLE IF NOT EXISTS `assistant_saved_wines` (" +
                "`position` INTEGER NOT NULL, `slug` TEXT NOT NULL, `photoId` TEXT, " +
                "`instanceId` TEXT, `payloadJson` TEXT NOT NULL, PRIMARY KEY(`position`))"
        )
    }

    private fun hasColumn(connection: SQLiteConnection, table: String, column: String): Boolean =
        connection.prepare("PRAGMA table_info(`$table`)").use { statement ->
            var found = false
            while (!found && statement.step()) {
                found = statement.getText(TABLE_INFO_NAME_COLUMN).equals(column, ignoreCase = true)
            }
            found
        }
}
