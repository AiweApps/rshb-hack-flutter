package com.aiweapps.winescan.scan.home.components

import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.view.CameraController
import androidx.camera.view.LifecycleCameraController
import androidx.camera.view.PreviewView
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.camera.core.ImageCaptureException
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.scan.home.model.ScanHomeState
import com.aiweapps.winescan.platform.rememberPhotoPreparer
import com.aiweapps.winescan.uikit.theme.AppDesign
import java.io.File
import kotlinx.coroutines.launch

private const val SCRIM_ALPHA = 0.55f
private const val FLASH_PEAK_ALPHA = 0.85f
private const val FLASH_MS = 450
private const val CAPTURE_PREFIX = "capture_"
private const val CAPTURE_SUFFIX = ".jpg"
private const val CAPTURE_LOG_TAG = "CameraStage"

/** The live viewfinder with the title and status on top and the controls at the bottom. */
@Composable
fun CameraStage(
    state: ScanHomeState,
    onShutterClicked: () -> Unit,
    onFlashClicked: () -> Unit,
    onPickPhotoClicked: () -> Unit,
    onStatusHintClicked: () -> Unit,
    onPhotoCaptured: (String) -> Unit,
    onCaptureFailed: () -> Unit,
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val controller = remember {
        LifecycleCameraController(context).apply {
            setEnabledUseCases(CameraController.IMAGE_CAPTURE)
            cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
            // PreviewView converts taps through its actual crop/rotation transform.
            isTapToFocusEnabled = true
        }
    }

    DisposableEffect(controller, lifecycleOwner, state.isCameraWanted) {
        if (state.isCameraWanted) controller.bindToLifecycle(lifecycleOwner)
        onDispose { controller.unbind() }
    }
    LaunchedEffect(controller, state.isFlashOn) {
        controller.imageCaptureFlashMode =
            if (state.isFlashOn) ImageCapture.FLASH_MODE_ON else ImageCapture.FLASH_MODE_OFF
    }
    CaptureEffect(controller, state.isCapturing, onPhotoCaptured, onCaptureFailed)

    var shotTicket by rememberSaveable { mutableIntStateOf(0) }

    val scrim = AppDesign.colors.scrim
    val onPhoto = AppDesign.colors.onPhoto
    Box(Modifier.fillMaxSize().background(scrim)) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { ctx ->
                PreviewView(ctx).apply {
                    scaleType = PreviewView.ScaleType.FILL_CENTER
                    this.controller = controller
                }
            },
        )
        ShotFlash(ticket = shotTicket)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(Brush.verticalGradient(listOf(scrim.copy(alpha = SCRIM_ALPHA), Color.Transparent)))
                .statusBarsPadding()
                .padding(start = 20.dp, end = 12.dp, top = 8.dp, bottom = 24.dp)
                .align(Alignment.TopCenter),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(
                text = stringResource(R.string.tab_scan),
                style = MaterialTheme.typography.titleLarge,
                color = onPhoto,
            )
        }
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .background(Brush.verticalGradient(listOf(Color.Transparent, scrim.copy(alpha = SCRIM_ALPHA))))
                .navigationBarsPadding()
                .padding(top = 32.dp, bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            StatusHintCapsule(
                hint = state.statusHint,
                mood = state.shutterMood,
                queueAhead = state.queueAhead,
                isShown = state.isHintShown,
                refusedTicket = state.refusedShotTicket,
                onClick = onStatusHintClicked,
            )
            CameraControls(
                isFlashOn = state.isFlashOn,
                isBusy = state.isBusy,
                shutterMood = state.shutterMood,
                queueAhead = state.queueAhead,
                isShotRefused = state.isShotRefused,
                shotTicket = shotTicket,
                refusedShotTicket = state.refusedShotTicket,
                onShutterClicked = {
                    // Only a shot the component will take pours the bottle and flashes.
                    if (!state.isShotRefused) shotTicket++
                    onShutterClicked()
                },
                onFlashClicked = onFlashClicked,
                onPickPhotoClicked = onPickPhotoClicked,
            )
        }
    }
}

/** A brief white flash over the viewfinder on every shot. */
@Composable
private fun ShotFlash(ticket: Int) {
    val flash = remember { Animatable(0f) }
    LaunchedOnTicket(ticket) {
        flash.snapTo(FLASH_PEAK_ALPHA)
        flash.animateTo(0f, tween(FLASH_MS, easing = EaseOut))
    }
    Box(
        Modifier
            .fillMaxSize()
            .graphicsLayer { alpha = flash.value }
            .background(AppDesign.colors.onPhoto),
    )
}

/** Takes the picture the moment the component says a capture is in flight. */
@Composable
private fun CaptureEffect(
    controller: LifecycleCameraController,
    isCapturing: Boolean,
    onCaptured: (String) -> Unit,
    onFailed: () -> Unit,
) {
    val context = LocalContext.current
    val preparer = rememberPhotoPreparer()
    val scope = rememberCoroutineScope()
    val captured by rememberUpdatedState(onCaptured)
    val failed by rememberUpdatedState(onFailed)

    LaunchedEffect(isCapturing) {
        if (!isCapturing) return@LaunchedEffect
        val file = File.createTempFile(CAPTURE_PREFIX, CAPTURE_SUFFIX, context.cacheDir)
        val options = ImageCapture.OutputFileOptions.Builder(file).build()
        controller.takePicture(
            options,
            ContextCompat.getMainExecutor(context),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    scope.launch {
                        val path = preparer.prepare(android.net.Uri.fromFile(file))
                        file.delete()
                        if (path != null) captured(path) else failed()
                    }
                }

                override fun onError(exception: ImageCaptureException) {
                    Log.w(CAPTURE_LOG_TAG, "Capture failed", exception)
                    file.delete()
                    failed()
                }
            },
        )
    }
}
