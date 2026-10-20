package com.aiweapps.winescan.scan.home.components

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import com.aiweapps.winescan.platform.rememberPhotoPreparer
import kotlinx.coroutines.launch

/** Opens the system photo picker while the component says a pick is in progress. */
@Composable
fun PhotoPickerEffect(
    isPicking: Boolean,
    onPicked: (String?) -> Unit,
    onFailed: () -> Unit,
) {
    val preparer = rememberPhotoPreparer()
    val scope = rememberCoroutineScope()
    val picked by rememberUpdatedState(onPicked)
    val failed by rememberUpdatedState(onFailed)

    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri == null) {
            picked(null)
        } else {
            scope.launch {
                val path = preparer.prepare(uri)
                if (path != null) picked(path) else failed()
            }
        }
    }

    LaunchedEffect(isPicking) {
        if (isPicking) {
            launcher.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
        }
    }
}
