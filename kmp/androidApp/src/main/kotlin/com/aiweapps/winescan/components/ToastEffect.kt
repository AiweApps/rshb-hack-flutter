package com.aiweapps.winescan.components

import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch

/**
 * Shows [message] once in a snackbar and tells the component it was shown. The component
 * clears its toast field, so the same toast fires again only if it is raised again.
 */
@Composable
fun ToastEffect(
    message: String?,
    host: SnackbarHostState,
    onConsumed: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    LaunchedEffect(message) {
        if (message == null) return@LaunchedEffect
        // Shown from the screen's own scope: consuming the toast clears `message`, which
        // restarts this effect, and a snackbar launched here would be cancelled unseen.
        scope.launch { host.showSnackbar(message = message, duration = SnackbarDuration.Short) }
        onConsumed()
    }
}
