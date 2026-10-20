package com.aiweapps.winescan.scan.result.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.clickable
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess
import com.aiweapps.winescan.domain.scan.model.WineCard

/** «All»: one card per bottle with its best match; tapping a card selects the bottle. */
@Composable
fun BottlesOverview(
    view: RecognitionView,
    referenceAccess: ReferenceAccess?,
    isInCompare: (WineCard) -> Boolean,
    onBottleClicked: (String) -> Unit,
    onAddToCompareClicked: (String) -> Unit,
    onRemoveFromCompareClicked: (String) -> Unit,
    onLinkClicked: (String) -> Unit,
) {
    Column(
        modifier = Modifier.padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        view.bottles.forEach { bottle ->
            val best = bottle.best
            if (best == null) {
                ResultEmptyCard(
                    title = null,
                    text = stringResource(R.string.result_bottle_no_match, bottle.number),
                    modifier = Modifier.clickable { onBottleClicked(bottle.instanceId) },
                )
            } else {
                WineCardTile(
                    card = best,
                    tag = if (view.isNearCenter(bottle)) {
                        stringResource(R.string.result_bottle_near_center_tag, bottle.number)
                    } else {
                        stringResource(R.string.result_bottle_n, bottle.number)
                    },
                    referenceUrl = referenceAccess?.resolve(best.reference),
                    isBest = false,
                    onLinkClicked = onLinkClicked,
                    onClick = { onBottleClicked(bottle.instanceId) },
                    footer = {
                        AddToCompareTextButton(
                            isInCompare = isInCompare(best),
                            onAddClicked = { onAddToCompareClicked(bottle.instanceId) },
                            onRemoveClicked = { onRemoveFromCompareClicked(bottle.instanceId) },
                            modifier = Modifier.padding(start = 8.dp, bottom = 4.dp),
                        )
                    },
                )
            }
        }
    }
}
