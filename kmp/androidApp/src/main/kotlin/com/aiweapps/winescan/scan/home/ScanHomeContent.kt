package com.aiweapps.winescan.scan.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppModalBottomSheet
import com.aiweapps.winescan.components.ErrorState
import com.aiweapps.winescan.components.LoadingState
import com.aiweapps.winescan.components.ServiceDetailSheet
import com.aiweapps.winescan.components.ToastEffect
import com.aiweapps.winescan.components.scan.home.ScanHomeComponent
import com.aiweapps.winescan.components.scan.home.model.ScanHomeToast
import com.aiweapps.winescan.domain.scan.model.CameraStatus
import com.aiweapps.winescan.scan.home.components.CameraPermissionEffect
import com.aiweapps.winescan.scan.home.components.CameraStage
import com.aiweapps.winescan.scan.home.components.CameraUnavailableView
import com.aiweapps.winescan.scan.home.components.PhotoPickerEffect
import com.aiweapps.winescan.uikit.theme.AppDesign
import com.arkivanov.decompose.extensions.compose.subscribeAsState

@Composable
fun ScanHomeContent(component: ScanHomeComponent) {
    val state by component.state.subscribeAsState()
    val modalSlot by component.modalSlot.subscribeAsState()
    val snackbarHost = remember { SnackbarHostState() }

    ToastEffect(
        message = when (state.toast) {
            ScanHomeToast.PHOTO_OPEN_FAILED -> stringResource(R.string.scan_error_photo_open)
            null -> null
        },
        host = snackbarHost,
        onConsumed = component::onToastConsumed,
    )
    CameraPermissionEffect(
        isCameraWanted = state.isCameraWanted,
        cameraStatus = state.cameraStatus,
        requestTicket = state.permissionRequestTicket,
        onAvailabilityReported = component::onCameraAvailabilityReported,
    )
    PhotoPickerEffect(
        isPicking = state.isPicking,
        onPicked = component::onPhotoPicked,
        onFailed = component::onPhotoPickFailed,
    )

    when (val screenState = state.screenState) {
        is ScreenState.Loading -> LoadingState()
        is ScreenState.Error -> ErrorState(error = screenState.error)
        is ScreenState.Content -> Box(Modifier.fillMaxSize()) {
            when (state.cameraStatus) {
                CameraStatus.READY -> CameraStage(
                    state = state,
                    onShutterClicked = component::onShutterClicked,
                    onFlashClicked = component::onFlashClicked,
                    onPickPhotoClicked = component::onPickPhotoClicked,
                    onStatusHintClicked = component::onStatusHintClicked,
                    onPhotoCaptured = component::onPhotoCaptured,
                    onCaptureFailed = component::onCaptureFailed,
                )
                CameraStatus.STARTING -> Box(Modifier.fillMaxSize().background(AppDesign.colors.scrim))
                CameraStatus.DENIED,
                CameraStatus.PERMANENTLY_DENIED,
                CameraStatus.UNAVAILABLE,
                -> CameraUnavailableView(
                    state = state,
                    onAllowCameraClicked = component::onAllowCameraClicked,
                    onOpenSettingsClicked = component::onOpenSettingsClicked,
                    onPickPhotoClicked = component::onPickPhotoClicked,
                    onRecentScanClicked = component::onRecentScanClicked,
                    onAllScansClicked = component::onAllScansClicked,
                )
            }
            SnackbarHost(snackbarHost, Modifier.align(Alignment.BottomCenter))
        }
    }

    AppModalBottomSheet(
        modal = modalSlot.child?.instance,
        onDismissRequest = component::onModalDismissed,
    ) { modal ->
        when (modal) {
            is ScanHomeComponent.Modal.ServiceDetail -> ServiceDetailSheet(modal.component)
        }
    }
}
