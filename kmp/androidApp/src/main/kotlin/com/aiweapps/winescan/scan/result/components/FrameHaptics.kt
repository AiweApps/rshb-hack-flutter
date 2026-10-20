package com.aiweapps.winescan.scan.result.components

import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalView

/**
 * The frame screen's haptic vocabulary on top of the platform constants; each call falls
 * back to the closest older constant below the API that added the better one.
 */
class FrameHaptics(private val view: View) {

    /** A frame has just become big enough to count as drawn. */
    fun frameStarted() {
        view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
    }

    /** The finger left a frame it was moving or resizing. */
    fun frameAdjusted() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            view.performHapticFeedback(HapticFeedbackConstants.SEGMENT_TICK)
        } else {
            view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
        }
    }

    /** «Scan» was pressed. */
    fun scanConfirmed() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
        } else {
            view.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)
        }
    }
}

@Composable
fun rememberFrameHaptics(): FrameHaptics {
    val view = LocalView.current
    return remember(view) { FrameHaptics(view) }
}
