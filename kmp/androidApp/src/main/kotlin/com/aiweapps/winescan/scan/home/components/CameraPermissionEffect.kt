package com.aiweapps.winescan.scan.home.components

import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.platform.LocalContext
import com.aiweapps.winescan.components.cameraAvailabilityAfterAnswer
import com.aiweapps.winescan.components.hasCameraHardware
import com.aiweapps.winescan.components.isCameraGranted
import com.aiweapps.winescan.components.wasCameraRefusedBefore
import com.aiweapps.winescan.domain.scan.model.CameraAvailability
import com.aiweapps.winescan.domain.scan.model.CameraStatus

/**
 * Bridges the system permission dialog to the component: asks while the tab wants the
 * camera and has not decided yet, asks again only when the user presses «Allow», and
 * reports what the platform answered. The decision about what to show stays in the component.
 */
@Composable
fun CameraPermissionEffect(
    isCameraWanted: Boolean,
    cameraStatus: CameraStatus,
    requestTicket: Int,
    onAvailabilityReported: (CameraAvailability) -> Unit,
) {
    val context = LocalContext.current
    val report by rememberUpdatedState(onAvailabilityReported)

    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        report(context.cameraAvailabilityAfterAnswer(granted))
    }

    LaunchedEffect(isCameraWanted, cameraStatus) {
        if (!isCameraWanted) return@LaunchedEffect
        if (cameraStatus == CameraStatus.DENIED || cameraStatus == CameraStatus.PERMANENTLY_DENIED) {
            // Resume after Settings keeps the shared refusal state. Only observe a new
            // grant here; asking again still requires the user's explicit Allow action.
            if (context.hasCameraHardware() && context.isCameraGranted()) report(CameraAvailability.READY)
            return@LaunchedEffect
        }
        if (cameraStatus != CameraStatus.STARTING) return@LaunchedEffect
        when {
            !context.hasCameraHardware() -> report(CameraAvailability.UNAVAILABLE)
            context.isCameraGranted() -> report(CameraAvailability.READY)
            // Already refused once, for instance in the intro: the tab shows its own «Allow» button.
            context.wasCameraRefusedBefore() -> report(CameraAvailability.DENIED)
            else -> launcher.launch(Manifest.permission.CAMERA)
        }
    }

    // Only a tick the user caused re-prompts; the value at composition time is not one.
    val seenTicket = remember { mutableIntStateOf(requestTicket) }
    LaunchedEffect(requestTicket) {
        if (requestTicket == seenTicket.intValue) return@LaunchedEffect
        seenTicket.intValue = requestTicket
        if (context.isCameraGranted()) report(CameraAvailability.READY) else launcher.launch(Manifest.permission.CAMERA)
    }
}
