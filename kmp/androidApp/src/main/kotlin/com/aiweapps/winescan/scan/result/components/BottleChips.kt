package com.aiweapps.winescan.scan.result.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.uikit.theme.AppDesign

/**
 * «All · Bottle 1 · Bottle 2 …», shown when the photo holds more than one bottle. The chip of
 * [winnerInstanceId] wears a gold crown.
 */
@Composable
fun BottleChips(
    view: RecognitionView,
    selectedInstanceId: String?,
    winnerInstanceId: String?,
    onSelected: (String?) -> Unit,
    modifier: Modifier = Modifier,
) {
    val haptics = LocalHapticFeedback.current
    fun select(id: String?) {
        haptics.performHapticFeedback(HapticFeedbackType.SegmentTick)
        onSelected(id)
    }

    LazyRow(
        modifier = modifier,
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        item(key = "all") {
            FilterChip(
                selected = selectedInstanceId == null,
                onClick = { select(null) },
                label = { Text(stringResource(R.string.result_tab_all)) },
            )
        }
        items(view.bottles, key = { it.instanceId }) { bottle ->
            FilterChip(
                selected = selectedInstanceId == bottle.instanceId,
                onClick = { select(bottle.instanceId) },
                leadingIcon = if (bottle.instanceId == winnerInstanceId) {
                    {
                        Icon(
                            imageVector = AppIcons.Crown,
                            contentDescription = stringResource(R.string.result_best_match),
                            tint = AppDesign.colors.gold,
                            modifier = Modifier.size(FilterChipDefaults.IconSize),
                        )
                    }
                } else {
                    null
                },
                label = {
                    Text(
                        if (view.isNearCenter(bottle)) {
                            stringResource(R.string.result_bottle_near_center_tag, bottle.number)
                        } else {
                            stringResource(R.string.result_bottle_n, bottle.number)
                        },
                    )
                },
            )
        }
    }
}
