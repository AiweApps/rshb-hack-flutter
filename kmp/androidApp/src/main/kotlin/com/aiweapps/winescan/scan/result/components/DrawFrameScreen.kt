package com.aiweapps.winescan.scan.result.components

import android.graphics.BitmapFactory
import android.graphics.Color as AndroidColor
import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.ui.window.DialogWindowProvider
import androidx.core.view.WindowCompat
import androidx.exifinterface.media.ExifInterface
import coil3.compose.AsyncImage
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.scan.result.sheets.DrawFrameComponent
import com.aiweapps.winescan.components.scan.result.sheets.DrawFrameState
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.uikit.theme.AppDesign
import com.aiweapps.winescan.uikit.theme.DarkAppColors
import com.aiweapps.winescan.uikit.theme.AppTheme
import com.arkivanov.decompose.extensions.compose.subscribeAsState
import com.arkivanov.decompose.value.MutableValue
import com.arkivanov.decompose.value.Value
import java.io.File
import java.io.IOException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private const val CONTROL_ALPHA = 0.6f
private const val DISABLED_CONTAINER_ALPHA = 0.12f
private const val DISABLED_CONTENT_ALPHA = 0.38f

// The photo keeps clear of the controls: the top row is a 48dp button between two 8dp
// gaps, the bottom is a 56dp button between two 16dp gaps.
private val TopControlsHeight = 64.dp
private val BottomControlsHeight = 88.dp

/**
 * The frame screen in a full-screen dialog: its own window, so the system bars and the
 * back gesture belong to it and not to the result screen under it. The window is edge to
 * edge on the dark backdrop with light bar icons; back is the same as the close button.
 */
@Composable
fun DrawFrameDialog(component: DrawFrameComponent) {
    Dialog(
        onDismissRequest = component::onCancelClicked,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        DialogWindowEdgeToEdge()
        DrawFrameScreen(component)
    }
}

/** «Choose a frame»: draw on the photo, adjust the frame, and hand it back with «Scan». */
@Composable
fun DrawFrameScreen(component: DrawFrameComponent) {
    val state by component.state.subscribeAsState()
    var photoFailed by remember(component.photoPath) { mutableStateOf(false) }
    val frameSize by produceState(component.frame?.toFrameSize(), component.photoPath, component.frame) {
        if (value == null) value = withContext(Dispatchers.IO) { decodedSize(component.photoPath) }
    }
    val haptics = rememberFrameHaptics()
    LaunchedEffect(frameSize) {
        frameSize?.let { component.onImageSizeResolved(it.first.toInt(), it.second.toInt()) }
    }

    Box(Modifier.fillMaxSize().background(AppDesign.colors.scrim)) {
        Box(
            Modifier
                .fillMaxSize()
                .windowInsetsPadding(WindowInsets.safeDrawing)
                .padding(top = TopControlsHeight, bottom = BottomControlsHeight),
        ) {
            AsyncImage(
                model = File(component.photoPath),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Fit,
                onError = { photoFailed = true },
                onSuccess = { photoFailed = false },
            )
            if (photoFailed) {
                Text(stringResource(R.string.scan_error_photo_open), color = AppDesign.colors.onPhoto,
                    modifier = Modifier.align(Alignment.Center))
            }
            frameSize?.takeUnless { photoFailed }?.let { (width, height) ->
                FrameCanvas(
                    frameWidth = width,
                    frameHeight = height,
                    view = component.view,
                    draft = state.draft,
                    onDraftChanged = component::onDraftChanged,
                    modifier = Modifier.fillMaxSize(),
                )
            }
        }
        TopControls(
            onCloseClicked = component::onCancelClicked,
            modifier = Modifier.align(Alignment.TopCenter),
        )
        ScanButton(
            enabled = state.draft != null && !photoFailed,
            onClick = {
                haptics.scanConfirmed()
                component.onScanClicked()
            },
            modifier = Modifier.align(Alignment.BottomCenter),
        )
    }
}

@Composable
private fun TopControls(onCloseClicked: () -> Unit, modifier: Modifier = Modifier) {
    val colors = AppDesign.colors
    Row(
        modifier = modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal))
            .padding(horizontal = 8.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconButton(
            onClick = onCloseClicked,
            colors = IconButtonDefaults.iconButtonColors(
                containerColor = colors.scrim.copy(alpha = CONTROL_ALPHA),
                contentColor = colors.onPhoto,
            ),
        ) {
            Icon(AppIcons.Close, contentDescription = stringResource(R.string.common_close))
        }
        Box(Modifier.weight(1f).padding(horizontal = 8.dp), contentAlignment = Alignment.Center) {
            Surface(shape = CircleShape, color = colors.scrim.copy(alpha = CONTROL_ALPHA), contentColor = colors.onPhoto) {
                Text(
                    text = stringResource(R.string.frame_hint),
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                )
            }
        }
        // Mirrors the close button so the hint is centred on the screen, not on what is left.
        Spacer(Modifier.size(48.dp))
    }
}

@Composable
private fun ScanButton(enabled: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val colors = AppDesign.colors
    Button(
        onClick = onClick,
        enabled = enabled,
        // The screen is always dark, so the action takes the dark palette's wine whatever the
        // app theme (the light one would disappear on the backdrop), as on iOS. The disabled
        // colours are explicit because Material derives them from the surface, which here is
        // the wrong end of the lightness scale.
        colors = ButtonDefaults.buttonColors(
            containerColor = DarkAppColors.wine,
            contentColor = DarkAppColors.onWine,
            disabledContainerColor = colors.onPhoto.copy(alpha = DISABLED_CONTAINER_ALPHA),
            disabledContentColor = colors.onPhoto.copy(alpha = DISABLED_CONTENT_ALPHA),
        ),
        modifier = modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Bottom + WindowInsetsSides.Horizontal))
            .padding(16.dp)
            .heightIn(min = 56.dp),
    ) {
        Icon(AppIcons.Camera, contentDescription = null, modifier = Modifier.size(20.dp))
        Spacer(Modifier.size(8.dp))
        Text(stringResource(R.string.frame_scan), style = MaterialTheme.typography.labelLarge)
    }
}

/**
 * A dialog window gets neither the activity's edge-to-edge setup nor its bar icons: the bars
 * are made transparent over the dark backdrop and their icons light.
 */
@Composable
private fun DialogWindowEdgeToEdge() {
    val view = LocalView.current
    SideEffect {
        // Only the dialog's own window: the activity's bars belong to the rest of the app.
        val window = (view.parent as? DialogWindowProvider)?.window ?: return@SideEffect
        @Suppress("DEPRECATION")
        window.statusBarColor = AndroidColor.TRANSPARENT
        @Suppress("DEPRECATION")
        window.navigationBarColor = AndroidColor.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) window.isNavigationBarContrastEnforced = false
        WindowCompat.getInsetsController(window, view).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = false
        }
    }
}

private fun List<Int>.toFrameSize(): Pair<Float, Float>? =
    if (size >= 2 && this[0] > 0 && this[1] > 0) this[0].toFloat() to this[1].toFloat() else null

private fun decodedSize(path: String): Pair<Float, Float>? {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(path, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
    val orientation = try {
        ExifInterface(path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
    } catch (_: IOException) { return null }
    val rotated = orientation in setOf(ExifInterface.ORIENTATION_ROTATE_90, ExifInterface.ORIENTATION_ROTATE_270,
        ExifInterface.ORIENTATION_TRANSPOSE, ExifInterface.ORIENTATION_TRANSVERSE)
    return if (rotated) bounds.outHeight.toFloat() to bounds.outWidth.toFloat()
        else bounds.outWidth.toFloat() to bounds.outHeight.toFloat()
}

private class PreviewDrawFrameComponent(draft: BottleBox?) : DrawFrameComponent {
    override val photoPath: String = ""
    override val frame: List<Int>? = listOf(3000, 4000)
    override val view: RecognitionView? = null
    override val state: Value<DrawFrameState> = MutableValue(DrawFrameState(draft = draft))

    override fun onDraftChanged(box: BottleBox) = Unit
    override fun onImageSizeResolved(width: Int, height: Int) = Unit
    override fun onCancelClicked() = Unit
    override fun onScanClicked() = Unit
}

private val PreviewDraft = BottleBox(x1 = 900.0, y1 = 700.0, x2 = 2100.0, y2 = 3300.0)

@Preview(name = "Nothing drawn", showBackground = true, widthDp = 412, heightDp = 892)
@Composable
private fun DrawFrameEmptyPreview() =
    AppTheme(isDark = false) { DrawFrameScreen(PreviewDrawFrameComponent(draft = null)) }

@Preview(name = "Frame drawn", showBackground = true, widthDp = 412, heightDp = 892)
@Composable
private fun DrawFrameDrawnPreview() =
    AppTheme(isDark = false) { DrawFrameScreen(PreviewDrawFrameComponent(draft = PreviewDraft)) }

@Preview(name = "Frame drawn, dark", showBackground = true, widthDp = 412, heightDp = 892)
@Composable
private fun DrawFrameDrawnDarkPreview() =
    AppTheme(isDark = true) { DrawFrameScreen(PreviewDrawFrameComponent(draft = PreviewDraft)) }
