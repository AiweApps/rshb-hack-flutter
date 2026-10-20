package com.aiweapps.core.files

import android.content.Context
import java.io.File
import java.io.IOException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

actual class FileStoreProvider(private val context: Context) {

    actual fun create(directoryName: String): FileStore =
        DirectoryFileStore(File(context.filesDir, directoryName))
}

private class DirectoryFileStore(private val directory: File) : FileStore {

    override suspend fun keep(sourcePath: String, name: String): String = withContext(Dispatchers.IO) {
        directory.mkdirs()
        val source = File(sourcePath)
        val target = File(directory, name)
        // rename() cannot cross file systems (a picker cache on another volume); a copy
        // does the same job.
        if (!source.renameTo(target)) {
            source.copyTo(target, overwrite = true)
            source.delete()
        }
        name
    }

    override suspend fun copy(sourcePath: String, name: String): String = withContext(Dispatchers.IO) {
        directory.mkdirs()
        File(sourcePath).copyTo(File(directory, name), overwrite = true)
        name
    }

    override suspend fun pathFor(name: String): String = File(directory, name).absolutePath

    override suspend fun delete(name: String) {
        withContext(Dispatchers.IO) { File(directory, name).delete() }
    }

    override suspend fun deleteAll() {
        withContext(Dispatchers.IO) { directory.deleteRecursively() }
    }

    override suspend fun readBytes(path: String): ByteArray? = withContext(Dispatchers.IO) {
        try {
            File(path).takeIf { it.isFile }?.readBytes()
        } catch (_: IOException) {
            null
        }
    }
}
