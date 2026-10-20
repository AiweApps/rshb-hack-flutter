package com.aiweapps.winescan.error

import androidx.compose.runtime.Composable
import com.aiweapps.core.error.AppError
import org.jetbrains.compose.resources.stringResource
import winescan.sharedui.generated.resources.Res
import winescan.sharedui.generated.resources.error_network
import winescan.sharedui.generated.resources.error_server
import winescan.sharedui.generated.resources.error_timeout
import winescan.sharedui.generated.resources.error_unauthorized
import winescan.sharedui.generated.resources.error_unknown

/**
 * The single place where an [AppError] turns into user-facing text. Every Compose screen
 * goes through this instead of repeating the `when` — that is what keeps the wording (and
 * its translations) consistent, and what keeps raw server payloads off the screen.
 */
@Composable
fun AppError.asText(): String = when (this) {
    AppError.Network -> stringResource(Res.string.error_network)
    AppError.Timeout -> stringResource(Res.string.error_timeout)
    AppError.Unauthorized -> stringResource(Res.string.error_unauthorized)
    is AppError.Server -> stringResource(Res.string.error_server)
    AppError.Unknown -> stringResource(Res.string.error_unknown)
}
