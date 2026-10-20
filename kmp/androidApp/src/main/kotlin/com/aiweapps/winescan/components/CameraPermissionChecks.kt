package com.aiweapps.winescan.components

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.aiweapps.winescan.domain.scan.model.CameraAvailability

internal fun Context.hasCameraHardware(): Boolean =
    packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)

internal fun Context.isCameraGranted(): Boolean =
    ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED

/** True once the user has refused the camera at least once and the system would still show its dialog. */
internal fun Context.wasCameraRefusedBefore(): Boolean {
    val activity = findActivity() ?: return false
    return ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.CAMERA)
}

internal fun Context.cameraAvailabilityAfterAnswer(granted: Boolean): CameraAvailability = when {
    granted -> CameraAvailability.READY
    wasCameraRefusedBefore() -> CameraAvailability.DENIED
    else -> CameraAvailability.PERMANENTLY_DENIED
}

internal fun Context.findActivity(): Activity? {
    var current: Context? = this
    while (current is ContextWrapper) {
        if (current is Activity) return current
        current = current.baseContext
    }
    return null
}
