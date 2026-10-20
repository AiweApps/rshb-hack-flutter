package com.aiweapps.core.files

/**
 * A named folder of files inside the app's private storage, outside any gallery and
 * removed together with the app.
 *
 * It deals in **file names, never absolute paths**: on iOS the app's container moves on
 * every update, so a stored absolute path stops pointing at the file. Persist the name
 * from [keep] and turn it back into a path with [pathFor] at read time.
 */
interface FileStore {

    /** Moves the file at [sourcePath] into the store under [name] and returns that name. */
    suspend fun keep(sourcePath: String, name: String): String

    /**
     * Copies the file at [sourcePath] into the store under [name] and returns that name.
     * The source stays where it is: for a file another store owns.
     */
    suspend fun copy(sourcePath: String, name: String): String

    suspend fun pathFor(name: String): String

    suspend fun delete(name: String)

    suspend fun deleteAll()

    /** The whole file at [path], anywhere on disk; `null` when it cannot be read. */
    suspend fun readBytes(path: String): ByteArray?
}

expect class FileStoreProvider {
    fun create(directoryName: String): FileStore
}
