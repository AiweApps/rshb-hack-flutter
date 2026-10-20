package com.aiweapps.winescan.scan.home.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import android.os.Build
import android.view.HapticFeedbackConstants
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.scan.home.model.ShutterMood
import com.aiweapps.winescan.uikit.theme.AppDesign

private const val DISABLED_ALPHA = 0.4f

/**
 * Gallery, shutter and flash in one row; all of them are inert while a capture or pick runs.
 * The shutter pours on a shot ([shotTicket]) and wobbles when the service refuses one; a refused
 * gallery tap gets the same reject haptic.
 */
@Composable
fun CameraControls(
    isFlashOn: Boolean,
    isBusy: Boolean,
    shutterMood: ShutterMood,
    queueAhead: Int,
    isShotRefused: Boolean,
    shotTicket: Int,
    refusedShotTicket: Int,
    onShutterClicked: () -> Unit,
    onFlashClicked: () -> Unit,
    onPickPhotoClicked: () -> Unit,
) {
    val onPhoto = AppDesign.colors.onPhoto
    val view = LocalView.current
    val buttonColors = IconButtonDefaults.filledIconButtonColors(
        containerColor = AppDesign.colors.scrim.copy(alpha = 0.4f),
        contentColor = onPhoto,
        disabledContainerColor = AppDesign.colors.scrim.copy(alpha = 0.2f),
        disabledContentColor = onPhoto.copy(alpha = DISABLED_ALPHA),
    )

    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconButton(
            onClick = {
                // A refused pick shakes and rejects like the shutter, but never confirms or flashes.
                if (isShotRefused) view.performHapticFeedback(rejectHaptic())
                onPickPhotoClicked()
            },
            enabled = !isBusy,
            modifier = Modifier.size(56.dp),
            colors = buttonColors,
        ) {
            Icon(AppIcons.Photos, contentDescription = stringResource(R.string.scan_pick_photo))
        }

        BottleShutter(
            mood = shutterMood,
            queueAhead = queueAhead,
            shotTicket = shotTicket,
            refusedTicket = refusedShotTicket,
            enabled = !isBusy,
            onClick = {
                view.performHapticFeedback(if (isShotRefused) rejectHaptic() else confirmHaptic())
                onShutterClicked()
            },
        )

        IconButton(
            onClick = onFlashClicked,
            enabled = !isBusy,
            modifier = Modifier.size(56.dp),
            colors = IconButtonDefaults.filledIconButtonColors(
                containerColor = AppDesign.colors.scrim.copy(alpha = 0.4f),
                contentColor = if (isFlashOn) AppDesign.colors.gold else onPhoto,
                disabledContainerColor = AppDesign.colors.scrim.copy(alpha = 0.2f),
                disabledContentColor = onPhoto.copy(alpha = DISABLED_ALPHA),
            ),
        ) {
            Icon(
                imageVector = if (isFlashOn) AppIcons.Flash else AppIcons.FlashOff,
                contentDescription = stringResource(R.string.scan_flash),
            )
        }
    }
}

/** A shot taken: «confirm» where the platform has it (API 30+), a context click before. */
private fun confirmHaptic(): Int =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        HapticFeedbackConstants.CONFIRM
    } else {
        HapticFeedbackConstants.CONTEXT_CLICK
    }

/** A shot refused: «reject» where the platform has it (API 30+), a long press before. */
private fun rejectHaptic(): Int =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        HapticFeedbackConstants.REJECT
    } else {
        HapticFeedbackConstants.LONG_PRESS
    }
