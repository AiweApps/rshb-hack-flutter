package com.aiweapps.winescan.scan.home.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.components.scan.home.model.ScanHomeState
import com.aiweapps.winescan.domain.history.model.ScanHistoryItem
import com.aiweapps.winescan.domain.scan.model.CameraStatus
import com.aiweapps.winescan.uikit.theme.AppTheme

private val ButtonMinHeight = 48.dp
private val IconTileSize = 72.dp

/**
 * The tab when the viewfinder cannot run: one card with an icon, why, what to do about it and
 * the gallery as the way forward (a filled «Choose a photo»). The recent scans sit in a panel
 * docked to the bottom, as in the sibling tabs.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CameraUnavailableView(
    state: ScanHomeState,
    onAllowCameraClicked: () -> Unit,
    onOpenSettingsClicked: () -> Unit,
    onPickPhotoClicked: () -> Unit,
    onRecentScanClicked: (Long) -> Unit,
    onAllScansClicked: () -> Unit,
) {
    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = { CenterAlignedTopAppBar(title = { Text(stringResource(R.string.tab_scan)) }) },
        bottomBar = {
            if (state.recent.isNotEmpty()) {
                RecentScansPanel(
                    items = state.recent,
                    onItemClicked = onRecentScanClicked,
                    onAllClicked = onAllScansClicked,
                )
            }
        },
    ) { padding ->
        // The bottom padding is the panel's height, so the card never runs under it.
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
        ) {
            CameraUnavailableCard(
                status = state.cameraStatus,
                isPickEnabled = !state.isBusy,
                onAllowCameraClicked = onAllowCameraClicked,
                onOpenSettingsClicked = onOpenSettingsClicked,
                onPickPhotoClicked = onPickPhotoClicked,
            )
        }
    }
}

/** Icon, title, text and the buttons: the gallery first, the camera fix under it. */
@Composable
private fun CameraUnavailableCard(
    status: CameraStatus,
    isPickEnabled: Boolean,
    onAllowCameraClicked: () -> Unit,
    onOpenSettingsClicked: () -> Unit,
    onPickPhotoClicked: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val titleRes = when (status) {
        CameraStatus.UNAVAILABLE -> R.string.scan_camera_unavailable_title
        else -> R.string.scan_camera_denied_title
    }
    val bodyRes = when (status) {
        CameraStatus.UNAVAILABLE -> R.string.scan_camera_unavailable_body
        CameraStatus.PERMANENTLY_DENIED -> R.string.scan_camera_settings_body
        else -> R.string.scan_camera_denied_body
    }

    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceContainerLow,
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Surface(
                modifier = Modifier.size(IconTileSize),
                shape = RoundedCornerShape(20.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
            ) {
                Icon(
                    imageVector = AppIcons.Camera,
                    contentDescription = null,
                    modifier = Modifier.padding(20.dp),
                    tint = MaterialTheme.colorScheme.primary,
                )
            }
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(text = stringResource(titleRes), style = MaterialTheme.typography.headlineSmall)
                Text(
                    text = stringResource(bodyRes),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                ActionButton(
                    label = R.string.scan_pick_photo,
                    icon = AppIcons.Photos,
                    isTonal = false,
                    isEnabled = isPickEnabled,
                    onClick = onPickPhotoClicked,
                )
                when (status) {
                    CameraStatus.DENIED -> ActionButton(
                        label = R.string.scan_allow_camera,
                        icon = AppIcons.Camera,
                        isTonal = true,
                        onClick = onAllowCameraClicked,
                    )
                    CameraStatus.PERMANENTLY_DENIED -> ActionButton(
                        label = R.string.scan_open_settings,
                        icon = AppIcons.Settings,
                        isTonal = true,
                        onClick = onOpenSettingsClicked,
                    )
                    CameraStatus.STARTING, CameraStatus.READY, CameraStatus.UNAVAILABLE -> Unit
                }
            }
        }
    }
}

@Composable
private fun ActionButton(
    label: Int,
    icon: ImageVector,
    isTonal: Boolean,
    onClick: () -> Unit,
    isEnabled: Boolean = true,
) {
    val modifier = Modifier.fillMaxWidth().heightIn(min = ButtonMinHeight)
    val padding = ButtonDefaults.ButtonWithIconContentPadding
    val content: @Composable () -> Unit = {
        Icon(icon, contentDescription = null, modifier = Modifier.size(ButtonDefaults.IconSize))
        Spacer(Modifier.width(ButtonDefaults.IconSpacing))
        Text(stringResource(label))
    }
    if (isTonal) {
        FilledTonalButton(onClick = onClick, enabled = isEnabled, modifier = modifier, contentPadding = padding) {
            content()
        }
    } else {
        Button(onClick = onClick, enabled = isEnabled, modifier = modifier, contentPadding = padding) { content() }
    }
}

private val PreviewRecent = listOf(
    ScanHistoryItem(1, 0L, "", "Tamara, 2023", null, null, null, 2),
    ScanHistoryItem(2, 0L, "", null, null, null, null, 0),
    ScanHistoryItem(3, 0L, "", "Кубань · Саперави, 2021", null, null, null, 1),
)

@Composable
private fun CameraUnavailablePreview(status: CameraStatus, recent: List<ScanHistoryItem> = PreviewRecent) {
    AppTheme(isDark = false) {
        CameraUnavailableView(
            state = ScanHomeState(cameraStatus = status, recent = recent),
            onAllowCameraClicked = {},
            onOpenSettingsClicked = {},
            onPickPhotoClicked = {},
            onRecentScanClicked = {},
            onAllScansClicked = {},
        )
    }
}

@Preview(name = "No camera", showBackground = true, widthDp = 412, heightDp = 835)
@Composable
private fun CameraUnavailableNonePreview() = CameraUnavailablePreview(CameraStatus.UNAVAILABLE)

@Preview(name = "Denied, can ask again", showBackground = true, widthDp = 412, heightDp = 835)
@Composable
private fun CameraUnavailableDeniedPreview() = CameraUnavailablePreview(CameraStatus.DENIED)

@Preview(name = "Denied for good, no recent", showBackground = true, widthDp = 412, heightDp = 835)
@Composable
private fun CameraUnavailableSettingsPreview() =
    CameraUnavailablePreview(CameraStatus.PERMANENTLY_DENIED, recent = emptyList())
