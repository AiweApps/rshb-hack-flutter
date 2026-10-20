package com.aiweapps.winescan.scan.result.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.SheetHeader
import com.aiweapps.winescan.components.scan.result.sheets.CompareComponent
import com.aiweapps.winescan.uikit.theme.AppDesign
import kotlin.math.abs

private const val FULL_MAX_SIDE = 4000
private const val SHEET_HEIGHT_SHARE = 0.55f
private const val STOP_TOLERANCE = 0.01f

/**
 * The bottle from the photo against the catalogue reference in one reveal viewer: drag the
 * divider, or jump to «My photo / Both / Reference» with the segmented control.
 */
@Composable
fun CompareSheet(component: CompareComponent) {
    val reveal = rememberRevealState()
    val haptics = rememberRevealHaptics()
    val scope = rememberCoroutineScope()
    val viewerHeight = LocalConfiguration.current.screenHeightDp.dp * SHEET_HEIGHT_SHARE
    val activeStop by remember {
        derivedStateOf { RevealStop.entries.firstOrNull { abs(reveal.position.value - it.share) < STOP_TOLERANCE } }
    }

    Column(
        modifier = Modifier.fillMaxWidth().navigationBarsPadding().padding(horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        SheetHeader(
            title = stringResource(R.string.result_compare_title),
            onClose = component::onCloseClicked,
            modifier = Modifier.padding(bottom = 12.dp),
        )
        RevealViewer(
            photoPath = component.photoPath,
            crop = component.crop,
            frame = component.frame,
            referenceUrl = component.referenceUrl,
            reveal = reveal,
            maxSide = FULL_MAX_SIDE,
            modifier = Modifier.fillMaxWidth().height(viewerHeight),
        )
        Text(
            text = stringResource(R.string.reveal_hint),
            style = MaterialTheme.typography.bodySmall,
            color = AppDesign.colors.muted,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 12.dp, bottom = 12.dp),
        )
        SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(bottom = 16.dp)) {
            val labels = listOf(R.string.reveal_mine, R.string.reveal_both, R.string.reveal_reference)
            RevealStop.entries.forEachIndexed { index, stop ->
                SegmentedButton(
                    selected = activeStop == stop,
                    onClick = { reveal.animateTo(stop, scope, haptics) },
                    shape = SegmentedButtonDefaults.itemShape(index = index, count = RevealStop.entries.size),
                ) { Text(stringResource(labels[index])) }
            }
        }
    }
}
