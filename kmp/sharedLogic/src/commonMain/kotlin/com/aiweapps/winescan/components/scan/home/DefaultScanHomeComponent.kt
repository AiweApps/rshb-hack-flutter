package com.aiweapps.winescan.components.scan.home

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.slot.ChildSlot
import com.arkivanov.decompose.router.slot.SlotNavigation
import com.arkivanov.decompose.router.slot.activate
import com.arkivanov.decompose.router.slot.childSlot
import com.arkivanov.decompose.router.slot.dismiss
import com.arkivanov.decompose.value.Value
import com.arkivanov.essenty.lifecycle.doOnPause
import com.arkivanov.essenty.lifecycle.doOnResume
import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.components.base.BaseStatefulComponent
import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.winescan.components.common.ServiceDetailComponent
import com.aiweapps.winescan.components.scan.home.config.ScanHomeModalConfig
import com.aiweapps.winescan.components.scan.home.model.ScanHomeState
import com.aiweapps.winescan.components.scan.home.model.ScanHomeToast
import com.aiweapps.winescan.components.scan.home.model.ShutterMood
import com.aiweapps.winescan.components.scan.home.model.StatusHint
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.config.AnalyticsValues
import com.aiweapps.winescan.config.ScanLimits
import com.aiweapps.winescan.config.TimingConstants
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.scan.model.CameraAvailability
import com.aiweapps.winescan.domain.scan.model.CameraStatus
import com.aiweapps.winescan.domain.scan.model.ScanTarget
import com.aiweapps.winescan.domain.scan.model.ServiceAvailability
import com.aiweapps.winescan.domain.scan.model.ServiceState
import com.aiweapps.winescan.domain.status.ServiceStatusMonitor
import kotlin.coroutines.CoroutineContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

internal class DefaultScanHomeComponent(
    componentContext: ComponentContext,
    private val statusMonitor: ServiceStatusMonitor,
    private val historyRepository: ScanHistoryRepository,
    private val platformLinks: PlatformLinks,
    private val analytics: AnalyticsTracker,
    private val serviceDetailFactory: ServiceDetailComponent.Factory,
    private val onOpenResult: (ScanTarget) -> Unit,
    private val onOpenHistory: () -> Unit,
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
) : ScanHomeComponent, BaseStatefulComponent<ScanHomeState>(
    componentContext = componentContext,
    initialState = ScanHomeState(),
    mainContext = mainContext,
) {

    private val modalNavigation = SlotNavigation<ScanHomeModalConfig>()

    override val modalSlot: Value<ChildSlot<*, ScanHomeComponent.Modal>> =
        childSlot(
            source = modalNavigation,
            serializer = ScanHomeModalConfig.serializer(),
            handleBackButton = true,
            childFactory = ::createModal,
        )

    private var statusJob: Job? = null
    private var hintJob: Job? = null

    /** The first reading after the tab comes back shows a non-ready status even if unchanged. */
    private var isFirstReading = true

    init {
        // The camera and the status poll run only while this tab is the screen and the app
        // is in the foreground; Decompose stops the component in both other cases.
        lifecycle.doOnResume {
            updateState { copy(isCameraWanted = true) }
            isFirstReading = true
            watchStatus()
        }
        lifecycle.doOnPause {
            statusJob?.cancel()
            hideHint()
            // A permission refusal stays on screen as its own state; only a running camera
            // goes back to «starting» so it is re-opened on return.
            updateState {
                copy(
                    isCameraWanted = false,
                    isFlashOn = false,
                    cameraStatus = if (cameraStatus == CameraStatus.READY) CameraStatus.STARTING else cameraStatus,
                )
            }
        }
        historyRepository.watchRecent(ScanLimits.MAX_RECENT_SCANS_ON_HOME)
            .onEach { items -> updateState { copy(recent = items) } }
            // The strip is a convenience; a failing read leaves the tab without it.
            .catch { }
            .launchIn(scope)
    }

    override fun onCameraAvailabilityReported(availability: CameraAvailability) {
        updateState {
            copy(
                cameraStatus = when (availability) {
                    CameraAvailability.READY -> CameraStatus.READY
                    CameraAvailability.DENIED -> CameraStatus.DENIED
                    CameraAvailability.PERMANENTLY_DENIED -> CameraStatus.PERMANENTLY_DENIED
                    CameraAvailability.UNAVAILABLE -> CameraStatus.UNAVAILABLE
                },
                isFlashOn = false,
            )
        }
    }

    override fun onAllowCameraClicked() {
        updateState {
            copy(cameraStatus = CameraStatus.STARTING, permissionRequestTicket = permissionRequestTicket + 1)
        }
    }

    override fun onOpenSettingsClicked() {
        platformLinks.openAppSettings()
    }

    override fun onShutterClicked() {
        val state = currentState
        if (state.cameraStatus != CameraStatus.READY || state.isBusy) return
        if (state.isShotRefused) {
            updateState { copy(refusedShotTicket = refusedShotTicket + 1) }
            revealHint(StatusHint.STATUS)
            return
        }
        updateState { copy(isCapturing = true) }
        when {
            state.queueAhead > 0 -> revealHint(StatusHint.QUEUED)
            state.shutterMood == ShutterMood.CHECKING -> revealHint(StatusHint.STATUS)
        }
    }

    override fun onPhotoCaptured(photoPath: String) {
        updateState { copy(isCapturing = false) }
        logPhotoTaken(AnalyticsValues.SOURCE_CAMERA)
        onOpenResult(ScanTarget.NewScan(photoPath))
    }

    override fun onCaptureFailed() {
        updateState { copy(isCapturing = false, toast = ScanHomeToast.PHOTO_OPEN_FAILED) }
    }

    override fun onFlashClicked() {
        if (currentState.cameraStatus != CameraStatus.READY) return
        updateState { copy(isFlashOn = !isFlashOn) }
    }

    override fun onStatusHintClicked() {
        val state = currentState
        when {
            state.statusHint != StatusHint.AIM -> openStatusDetails()
            state.serviceState.availability != ServiceAvailability.READY -> revealHint(StatusHint.STATUS)
        }
    }

    override fun onPickPhotoClicked() {
        val state = currentState
        if (state.isBusy) return
        when {
            !state.isShotRefused -> updateState { copy(isPicking = true) }
            state.cameraStatus == CameraStatus.READY -> {
                updateState { copy(refusedShotTicket = refusedShotTicket + 1) }
                revealHint(StatusHint.STATUS)
            }
            else -> openStatusDetails()
        }
    }

    override fun onPhotoPicked(photoPath: String?) {
        updateState { copy(isPicking = false) }
        if (photoPath == null) return
        logPhotoTaken(AnalyticsValues.SOURCE_GALLERY)
        onOpenResult(ScanTarget.NewScan(photoPath))
    }

    override fun onPhotoPickFailed() {
        updateState { copy(isPicking = false, toast = ScanHomeToast.PHOTO_OPEN_FAILED) }
    }

    override fun onRecentScanClicked(scanId: Long) {
        onOpenResult(ScanTarget.Stored(scanId))
    }

    override fun onAllScansClicked() {
        onOpenHistory()
    }

    override fun onModalDismissed() {
        modalNavigation.dismiss()
    }

    override fun onToastConsumed() {
        updateState { copy(toast = null) }
    }

    private fun logPhotoTaken(source: String) {
        analytics.logEvent(AnalyticsEvents.PHOTO_TAKEN, mapOf(AnalyticsParams.SOURCE to source))
    }

    /** Only while the tab is on screen: the monitor polls as long as someone listens. */
    private fun watchStatus() {
        statusJob?.cancel()
        statusJob = statusMonitor.snapshots
            .onEach { snapshot -> onServiceState(snapshot.state) }
            .launchIn(scope)
    }

    /**
     * A new reading: the status shows itself when it turns into something other than «ready»
     * (or into another such state), and folds away as soon as the service is ready again.
     */
    private fun onServiceState(next: ServiceState) {
        val previous = currentState.serviceState.availability
        val isFirst = isFirstReading
        isFirstReading = false
        updateState { copy(serviceState = next) }
        when {
            next.availability == ServiceAvailability.READY -> hideHint()
            isFirst || next.availability != previous -> revealHint(StatusHint.STATUS)
        }
    }

    private fun revealHint(hint: StatusHint) {
        hintJob?.cancel()
        updateState { copy(statusHint = hint) }
        hintJob = scope.launch {
            delay(TimingConstants.STATUS_HINT_VISIBLE_MS)
            updateState { copy(statusHint = StatusHint.AIM) }
        }
    }

    private fun hideHint() {
        hintJob?.cancel()
        if (currentState.statusHint != StatusHint.AIM) updateState { copy(statusHint = StatusHint.AIM) }
    }

    private fun openStatusDetails() {
        modalNavigation.activate(ScanHomeModalConfig.ServiceDetail(currentState.serviceState.availability))
        statusMonitor.refreshNow()
    }

    private fun createModal(config: ScanHomeModalConfig, context: ComponentContext): ScanHomeComponent.Modal =
        when (config) {
            is ScanHomeModalConfig.ServiceDetail -> ScanHomeComponent.Modal.ServiceDetail(
                serviceDetailFactory.create(
                    componentContext = context,
                    availability = config.availability,
                    onClose = { modalNavigation.dismiss() },
                )
            )
        }
}
