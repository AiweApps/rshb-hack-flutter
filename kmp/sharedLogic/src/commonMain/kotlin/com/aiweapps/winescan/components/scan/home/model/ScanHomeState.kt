package com.aiweapps.winescan.components.scan.home.model

import com.aiweapps.core.components.model.BaseScreenState
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.domain.history.model.ScanHistoryItem
import com.aiweapps.winescan.domain.scan.model.CameraStatus
import com.aiweapps.winescan.domain.scan.model.ServiceAvailability
import com.aiweapps.winescan.domain.scan.model.ServiceState

enum class ScanHomeToast { PHOTO_OPEN_FAILED }

/**
 * What the shutter shows about the service. The bottle in it is full when the service is
 * ready, sloshes while we connect, fills up while there is a queue, and is empty when a
 * photo would get no answer.
 */
enum class ShutterMood {
    CHECKING,
    READY,
    BUSY,
    /** The service answers nothing: down, unreachable, no access, maintenance. */
    BLOCKED,
    /** The phone cannot reach the service at all: its own network problem. */
    OFFLINE,
}

/** What the hint over the shutter says right now. */
enum class StatusHint {
    /** «Point at the label»: the resting text. */
    AIM,
    /** The service status itself, for a few seconds. */
    STATUS,
    /** «Your photo is in the queue»: right after a shot while the service is busy. */
    QUEUED,
}

data class ScanHomeState(
    override val screenState: ScreenState = ScreenState.Content,
    val cameraStatus: CameraStatus = CameraStatus.STARTING,
    /**
     * Whether the viewfinder should run right now: only while this tab is the screen and
     * the app is in the foreground. The UI binds and unbinds the camera to this flag.
     */
    val isCameraWanted: Boolean = false,
    /**
     * Bumped every time the user asks for the permission again; the UI re-prompts when it
     * changes, and never on its own after a refusal.
     */
    val permissionRequestTicket: Int = 0,
    val isFlashOn: Boolean = false,
    /** A capture is in flight: the UI takes the picture once this turns true. */
    val isCapturing: Boolean = false,
    val serviceState: ServiceState = ServiceState.checking,
    /** Shown while the camera is not available, so the tab is not empty. */
    val recent: List<ScanHistoryItem> = emptyList(),
    /** The system picker is open; the buttons are disabled meanwhile. */
    val isPicking: Boolean = false,
    val toast: ScanHomeToast? = null,
    val statusHint: StatusHint = StatusHint.AIM,
    /** Bumped when the shutter is pressed but cannot shoot: the UI shakes the hint. */
    val refusedShotTicket: Int = 0,
) : BaseScreenState {

    val isBusy: Boolean get() = isCapturing || isPicking

    val shutterMood: ShutterMood
        get() = when (serviceState.availability) {
            ServiceAvailability.READY -> ShutterMood.READY
            ServiceAvailability.CHECKING -> ShutterMood.CHECKING
            // A rate limit clears by itself and the result screen retries on its own.
            ServiceAvailability.BUSY, ServiceAvailability.RATE_LIMITED -> ShutterMood.BUSY
            ServiceAvailability.OFFLINE -> ShutterMood.OFFLINE
            ServiceAvailability.DOWN, ServiceAvailability.UNAVAILABLE,
            ServiceAvailability.NO_ACCESS, ServiceAvailability.DEV -> ShutterMood.BLOCKED
        }

    /** A shot now would get no answer, so the shutter refuses it and says why. */
    val isShotRefused: Boolean get() = shutterMood == ShutterMood.BLOCKED || shutterMood == ShutterMood.OFFLINE

    /**
     * Whether the hint over the shutter is up: the status and the queue notice show for a
     * while, «point at the label» only when a shot would get an answer right away.
     */
    val isHintShown: Boolean get() = statusHint != StatusHint.AIM || shutterMood == ShutterMood.READY

    /** How many photos wait ahead, for the badge on the shutter; 0 hides it. */
    val queueAhead: Int get() = if (shutterMood == ShutterMood.BUSY) serviceState.waiting else 0
}
