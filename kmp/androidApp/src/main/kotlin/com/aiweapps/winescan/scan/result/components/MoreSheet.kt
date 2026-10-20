package com.aiweapps.winescan.scan.result.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.components.scan.result.sheets.MoreComponent

/** «More»: recognise only the selected bottle, choose a frame, share the answer as JSON, or look at the technical details. */
@Composable
fun MoreSheet(component: MoreComponent) {
    Column(Modifier.navigationBarsPadding()) {
        if (component.canRescanBottle) {
            component.bottleNumber?.let { number ->
                MoreRow(
                    icon = AppIcons.Camera,
                    title = stringResource(R.string.result_rescan_bottle, number),
                    onClick = component::onRescanBottleClicked,
                )
            }
        }
        if (component.canDrawFrame) {
            MoreRow(AppIcons.Expand, stringResource(R.string.result_choose_frame), component::onDrawFrameClicked)
        }
        MoreRow(AppIcons.Share, stringResource(R.string.result_share_json), component::onShareFullClicked)
        component.bottleNumber?.let { number ->
            MoreRow(
                icon = AppIcons.Share,
                title = if (component.isRoi) {
                    stringResource(R.string.result_share_frame_json)
                } else {
                    stringResource(R.string.result_share_bottle_json, number)
                },
                onClick = component::onShareBottleClicked,
            )
        }
        MoreRow(AppIcons.Info, stringResource(R.string.result_tech_details), component::onTechDetailsClicked)
    }
}

@Composable
private fun MoreRow(icon: ImageVector, title: String, onClick: () -> Unit) {
    ListItem(
        modifier = Modifier.clickable(onClick = onClick),
        colors = ListItemDefaults.colors(containerColor = Color.Transparent),
        leadingContent = { Icon(icon, contentDescription = null) },
        headlineContent = { Text(title) },
    )
}
