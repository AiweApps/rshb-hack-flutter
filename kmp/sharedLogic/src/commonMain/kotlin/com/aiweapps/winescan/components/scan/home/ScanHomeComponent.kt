package com.aiweapps.winescan.components.scan.home

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.common.ServiceDetailComponent
import com.aiweapps.winescan.components.scan.home.model.ScanHomeState
import com.aiweapps.winescan.domain.scan.model.CameraAvailability
import com.aiweapps.winescan.domain.scan.model.ScanTarget

/**
 * The scan tab: the viewfinder, the shutter, the gallery, the service status, and — while
 * the camera cannot run — the last scans.
 *
 * The camera itself is platform UI (CameraX, AVFoundation); this component decides
 * **whether** it should run ([ScanHomeState.isCameraWanted]) and what the tab shows, and
 * the UI reports back what the platform told it.
 */
interface ScanHomeComponent {

    val state: Value<ScanHomeState>

    val modalSlot: Value<ChildSlot<*, Modal>>

    /** The platform checked (or asked for) the permission and started the camera, or could not. */
    fun onCameraAvailabilityReported(availability: CameraAvailability)

    /** «Allow the camera»: the UI should ask the system again. */
    fun onAllowCameraClicked()

    fun onOpenSettingsClicked()

    /**
     * The shutter. Shoots while the service can answer (a busy one queues the photo and says
     * so, one we are still connecting to brings the status back); refuses while it cannot,
     * and brings the status back instead.
     */
    fun onShutterClicked()

    /** The capture the shutter asked for finished; [photoPath] is downsized for upload. */
    fun onPhotoCaptured(photoPath: String)

    fun onCaptureFailed()

    fun onFlashClicked()

    /**
     * The hint over the shutter: while it shows the status, opens the details; otherwise
     * brings the status back for a few seconds.
     */
    fun onStatusHintClicked()

    /**
     * The gallery. Opens the picker while the service can answer; otherwise says why not:
     * with the viewfinder up like a refused shot, without it in the status details.
     */
    fun onPickPhotoClicked()

    /** The system picker closed; `null` when the user dismissed it. */
    fun onPhotoPicked(photoPath: String?)

    fun onPhotoPickFailed()

    fun onRecentScanClicked(scanId: Long)

    fun onAllScansClicked()

    fun onModalDismissed()

    fun onToastConsumed()

    sealed class Modal {
        class ServiceDetail(val component: ServiceDetailComponent) : Modal()
    }

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            onOpenResult: (ScanTarget) -> Unit,
            onOpenHistory: () -> Unit,
        ): ScanHomeComponent
    }
}
