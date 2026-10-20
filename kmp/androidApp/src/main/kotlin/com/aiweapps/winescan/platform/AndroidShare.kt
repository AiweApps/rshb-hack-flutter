package com.aiweapps.winescan.platform

import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import com.aiweapps.core.share.PlatformShare
import com.aiweapps.core.share.ShareFilePayload
import com.aiweapps.core.share.SharePayload
import com.aiweapps.winescan.R
import java.io.File

/**
 * Android side of [PlatformShare]: an `ACTION_SEND` chooser.
 *
 * The wording lives here, not in the payload — `share_text_with_url` is an Android string
 * resource, localized alongside the rest of this app. Shared code passes the title and the
 * address and stays out of the sentence.
 *
 * Uses the application context and therefore has to start the chooser in its own task.
 */
internal class AndroidShare(private val context: Context) : PlatformShare {

    override fun share(payload: SharePayload) {
        val text = payload.url
            ?.let { context.getString(R.string.share_text_with_url, payload.title, it) }
            ?: payload.title

        val send = Intent(Intent.ACTION_SEND).apply {
            type = MIME_TYPE_PLAIN_TEXT
            putExtra(Intent.EXTRA_TITLE, payload.title)
            putExtra(Intent.EXTRA_TEXT, text)
        }
        startChooser(send)
    }

    override fun shareFile(payload: ShareFilePayload) {
        // Other apps can only read the file through the provider, so it is written into the
        // cache folder the provider exposes rather than handed over as a path.
        val directory = File(context.cacheDir, SHARED_DIRECTORY).apply { mkdirs() }
        val file = File(directory, payload.fileName)
        file.writeText(payload.content)
        val uri = FileProvider.getUriForFile(context, "${context.packageName}$PROVIDER_SUFFIX", file)

        val send = Intent(Intent.ACTION_SEND).apply {
            type = payload.mimeType
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startChooser(send)
    }

    private fun startChooser(send: Intent) {
        val chooser = Intent.createChooser(send, context.getString(R.string.share_chooser_title))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(chooser)
    }

    private companion object {
        const val MIME_TYPE_PLAIN_TEXT = "text/plain"
        const val SHARED_DIRECTORY = "shared"
        const val PROVIDER_SUFFIX = ".fileprovider"
    }
}
