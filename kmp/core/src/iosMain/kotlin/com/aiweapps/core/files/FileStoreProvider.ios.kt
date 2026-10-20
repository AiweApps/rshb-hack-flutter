package com.aiweapps.core.files

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.usePinned
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import platform.Foundation.NSApplicationSupportDirectory
import platform.Foundation.NSData
import platform.Foundation.NSFileManager
import platform.Foundation.NSUserDomainMask
import platform.Foundation.dataWithContentsOfFile
import platform.posix.memcpy

actual class FileStoreProvider {

    actual fun create(directoryName: String): FileStore = SupportDirectoryFileStore(directoryName)
}

/**
 * Lives in Application Support: private to the app, backed up, and out of the Photos
 * library — unlike Documents it never shows up in the Files app either.
 */
@OptIn(ExperimentalForeignApi::class)
private class SupportDirectoryFileStore(private val directoryName: String) : FileStore {

    private val fileManager = NSFileManager.defaultManager

    override suspend fun keep(sourcePath: String, name: String): String = withContext(Dispatchers.IO) {
        val target = pathFor(name)
        ensureDirectory()
        if (fileManager.fileExistsAtPath(target)) {
            fileManager.removeItemAtPath(target, error = null)
        }
        // The picker cache sits on another volume: a move fails there and a copy does the job.
        if (!fileManager.moveItemAtPath(sourcePath, toPath = target, error = null)) {
            fileManager.copyItemAtPath(sourcePath, toPath = target, error = null)
            fileManager.removeItemAtPath(sourcePath, error = null)
        }
        name
    }

    override suspend fun copy(sourcePath: String, name: String): String = withContext(Dispatchers.IO) {
        val target = pathFor(name)
        ensureDirectory()
        if (fileManager.fileExistsAtPath(target)) {
            fileManager.removeItemAtPath(target, error = null)
        }
        fileManager.copyItemAtPath(sourcePath, toPath = target, error = null)
        name
    }

    override suspend fun pathFor(name: String): String = directoryPath() + "/" + name

    override suspend fun delete(name: String) {
        withContext(Dispatchers.IO) { fileManager.removeItemAtPath(pathFor(name), error = null) }
    }

    override suspend fun deleteAll() {
        withContext(Dispatchers.IO) { fileManager.removeItemAtPath(directoryPath(), error = null) }
    }

    override suspend fun readBytes(path: String): ByteArray? = withContext(Dispatchers.IO) {
        NSData.dataWithContentsOfFile(path)?.toByteArray()
    }

    private fun ensureDirectory() {
        fileManager.createDirectoryAtPath(
            directoryPath(),
            withIntermediateDirectories = true,
            attributes = null,
            error = null,
        )
    }

    private fun directoryPath(): String {
        val support = fileManager.URLForDirectory(
            directory = NSApplicationSupportDirectory,
            inDomain = NSUserDomainMask,
            appropriateForURL = null,
            create = true,
            error = null,
        )
        return requireNotNull(support?.path) + "/" + directoryName
    }
}

@OptIn(ExperimentalForeignApi::class)
private fun NSData.toByteArray(): ByteArray {
    val size = length.toInt()
    if (size == 0) return ByteArray(0)
    return ByteArray(size).also { bytes ->
        bytes.usePinned { pinned -> memcpy(pinned.addressOf(0), this.bytes, length) }
    }
}
