package com.aiweapps.winescan.platform

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import com.aiweapps.core.platform.PlatformLinks

/** Android side of [PlatformLinks]: the browser and the app's page in the system settings. */
internal class AndroidLinks(private val context: Context) : PlatformLinks {

    override fun openUrl(url: String) {
        start(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    }

    override fun openAppSettings() {
        start(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts(PACKAGE_SCHEME, context.packageName, null))
        )
    }

    private fun start(intent: Intent) {
        try {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (_: ActivityNotFoundException) {
            // A device without a browser, or a settings page that does not exist on this
            // OEM build: there is nothing to show the user instead, and nothing broke.
        }
    }

    private companion object {
        const val PACKAGE_SCHEME = "package"
    }
}
