package com.aiweapps.winescan.data.database

import androidx.room.Room
import androidx.sqlite.SQLiteConnection
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import androidx.sqlite.execSQL
import com.aiweapps.core.database.applyDefaults
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.coroutines.test.runTest
import platform.Foundation.NSFileManager
import platform.Foundation.NSTemporaryDirectory

/**
 * Version 3 shipped in two shapes; both must open as version 4 with their data intact.
 * Room itself checks the migrated schema against version 4 on open, so a missing table,
 * column or index fails these tests the way it would fail the app on update.
 *
 * iOS only: the bundled SQLite driver ships no native library for the JVM host tests.
 */
@OptIn(ExperimentalForeignApi::class)
class AppDatabaseMigrationTest {

    private val path = NSTemporaryDirectory() + "winescan-migration-test.db"

    @AfterTest
    fun tearDown() {
        listOf("", "-wal", "-shm", "-journal").forEach { NSFileManager.defaultManager.removeItemAtPath(path + it, null) }
    }

    @Test
    fun theScannerBuildsV3GetsTheAssistantTables() = runTest {
        createV3(MAIN_V3_IDENTITY, assistantTables = false, snapshotColumn = true)

        val database = open()

        val saved = assertNotNull(database.savedPairingDao().byId(1))
        assertEquals("""{"dish":"kept"}""", saved.snapshotJson, "the scanner's saved choice keeps its snapshot")
        assertTrue(database.assistantLocalDao().savedWines().isEmpty())
        assertNull(database.assistantLocalDao().conversation("c1"))
        database.close()
    }

    @Test
    fun theAssistantBuildsV3GetsTheSnapshotColumn() = runTest {
        createV3(BRANCH_V3_IDENTITY, assistantTables = true, snapshotColumn = false)

        val database = open()

        val saved = assertNotNull(database.savedPairingDao().byId(1))
        assertNull(saved.snapshotJson, "a choice saved before the column has no snapshot")
        assertEquals("Chat", assertNotNull(database.assistantLocalDao().conversation("c1")).title)
        database.close()
    }

    @Test
    fun theMigrationIsIdempotent() {
        createV3(BRANCH_V3_IDENTITY, assistantTables = true, snapshotColumn = true)
        val connection = BundledSQLiteDriver().open(path)
        val migration = AppDatabaseMigrations.ALL.single { it.startVersion == 3 }

        migration.migrate(connection)
        migration.migrate(connection)

        assertEquals(1, columnCount(connection, "saved_pairings", "snapshotJson"))
        connection.close()
    }

    private suspend fun open(): AppDatabase {
        val database = Room.databaseBuilder<AppDatabase>(name = path).applyDefaults(AppDatabaseMigrations.ALL)
        // The first query opens the file: the migration runs and Room validates version 4.
        database.savedPairingDao().byId(0)
        return database
    }

    private fun createV3(identity: String, assistantTables: Boolean, snapshotColumn: Boolean) {
        val connection = BundledSQLiteDriver().open(path)
        V2_TABLES.forEach { connection.execSQL(it) }
        if (snapshotColumn) connection.execSQL("ALTER TABLE `saved_pairings` ADD COLUMN `snapshotJson` TEXT")
        if (assistantTables) ASSISTANT_TABLES.forEach { connection.execSQL(it) }
        connection.execSQL("CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT)")
        connection.execSQL("INSERT OR REPLACE INTO room_master_table (id,identity_hash) VALUES(42, '$identity')")
        val snapshot = if (snapshotColumn) ", `snapshotJson`" else ""
        val snapshotValue = if (snapshotColumn) ", '{\"dish\":\"kept\"}'" else ""
        connection.execSQL(
            "INSERT INTO `saved_pairings` (`id`, `dish`, `winesJson`, `createdAt`$snapshot) " +
                "VALUES (1, 'Сыры', '[]', 1$snapshotValue)"
        )
        if (assistantTables) {
            connection.execSQL(
                "INSERT INTO `assistant_conversations` (`id`, `title`, `lastMessage`, `draft`, `createdAt`, `updatedAt`) " +
                    "VALUES ('c1', 'Chat', '', '', 1, 1)"
            )
        }
        connection.execSQL("PRAGMA user_version = 3")
        connection.close()
    }

    private fun columnCount(connection: SQLiteConnection, table: String, column: String): Int =
        connection.prepare("PRAGMA table_info(`$table`)").use { statement ->
            var count = 0
            while (statement.step()) if (statement.getText(1) == column) count++
            count
        }

    private companion object {
        // The identity hashes of the two version-3 schemas as they shipped.
        const val MAIN_V3_IDENTITY = "3de464766f72f0e616af30698a0ef974"
        const val BRANCH_V3_IDENTITY = "44742cf52cb02288ab460555e43df898"

        val V2_TABLES = listOf(
            "CREATE TABLE IF NOT EXISTS `scan_history` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, " +
                "`createdAt` INTEGER NOT NULL, `photoName` TEXT NOT NULL, `viewJson` TEXT NOT NULL, " +
                "`bestTitle` TEXT, `bestProducer` TEXT, `bestSlug` TEXT, `bestReference` TEXT, " +
                "`bottleCount` INTEGER NOT NULL)",
            "CREATE TABLE IF NOT EXISTS `compare_entries` (`slug` TEXT NOT NULL, `cardJson` TEXT NOT NULL, " +
                "`photoName` TEXT NOT NULL, `cropJson` TEXT, `frameWidth` INTEGER, `frameHeight` INTEGER, " +
                "`scanId` INTEGER, `addedAt` INTEGER NOT NULL, PRIMARY KEY(`slug`))",
            "CREATE TABLE IF NOT EXISTS `saved_pairings` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, " +
                "`dish` TEXT NOT NULL, `winesJson` TEXT NOT NULL, `createdAt` INTEGER NOT NULL)",
        )

        val ASSISTANT_TABLES = listOf(
            "CREATE TABLE IF NOT EXISTS `assistant_conversations` (`id` TEXT NOT NULL, `title` TEXT NOT NULL, " +
                "`lastMessage` TEXT NOT NULL, `draft` TEXT NOT NULL, `remoteSessionId` TEXT, " +
                "`selectedWinePhotoId` TEXT, `selectedWineInstanceId` TEXT, `selectedWineSlug` TEXT, " +
                "`selectedStoreId` INTEGER, `createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, " +
                "PRIMARY KEY(`id`))",
            "CREATE TABLE IF NOT EXISTS `assistant_messages` (`id` TEXT NOT NULL, `conversationId` TEXT NOT NULL, " +
                "`position` INTEGER NOT NULL, `payloadJson` TEXT NOT NULL, PRIMARY KEY(`conversationId`, `id`))",
            "CREATE UNIQUE INDEX IF NOT EXISTS `index_assistant_messages_conversationId_position` " +
                "ON `assistant_messages` (`conversationId`, `position`)",
            "CREATE TABLE IF NOT EXISTS `assistant_photos` (`id` TEXT NOT NULL, `conversationId` TEXT NOT NULL, " +
                "`fileName` TEXT NOT NULL, `displayName` TEXT NOT NULL, `mimeType` TEXT, " +
                "`createdAt` INTEGER NOT NULL, PRIMARY KEY(`id`))",
            "CREATE INDEX IF NOT EXISTS `index_assistant_photos_conversationId` ON `assistant_photos` (`conversationId`)",
            "CREATE TABLE IF NOT EXISTS `assistant_draft_attachments` (`conversationId` TEXT NOT NULL, " +
                "`position` INTEGER NOT NULL, `photoId` TEXT NOT NULL, PRIMARY KEY(`conversationId`, `position`))",
            "CREATE TABLE IF NOT EXISTS `assistant_saved_wines` (`position` INTEGER NOT NULL, `slug` TEXT NOT NULL, " +
                "`photoId` TEXT, `instanceId` TEXT, `payloadJson` TEXT NOT NULL, PRIMARY KEY(`position`))",
        )
    }
}
