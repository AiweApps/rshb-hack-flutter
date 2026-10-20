package com.aiweapps.winescan.compare.components

import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.compare.WineCompareComponent
import com.aiweapps.winescan.components.compare.model.WineCompareState
import com.aiweapps.winescan.uikit.theme.AppDesign

/** The comparison itself: the wines one under another, then the mode switch and the rows it selects. */
@Composable
fun CompareBody(
    state: WineCompareState,
    component: WineCompareComponent,
    modifier: Modifier = Modifier,
) {
    val dinnerPrompt = stringResource(R.string.compare_plan_dinner_prompt)
    val tableScroll = rememberScrollState()

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CompareBottomActions(
            canPairDish = state.canPairDish,
            onPlanDinnerClicked = { component.onPlanDinnerClicked(dinnerPrompt) },
            onPairDishClicked = component::onPairDishClicked,
        )
        Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            state.entries.forEachIndexed { index, entry ->
                CompareEntryCard(
                    entry = entry,
                    ordinal = index + 1,
                    referenceUrl = state.referenceAccess?.resolve(entry.card.reference),
                    onRemoveClicked = { component.onRemoveClicked(entry.slug) },
                    onLinkClicked = component::onCardLinkClicked,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
        if (state.needsSecondWine) {
            CompareNeedSecondCard(
                onPickFromHistoryClicked = component::onPickFromHistoryClicked,
                onScanClicked = component::onScanClicked,
            )
        } else {
            CompareModeSwitch(showAll = state.showAll, onShowAllChanged = component::onShowAllChanged)
            if (state.scrollsSideways) SidewaysHint(tableScroll)
            CompareColumnTitles(state = state, scrollState = tableScroll)
            if (state.showAll) {
                CompareTableCard(
                    title = stringResource(R.string.compare_mode_all),
                    rows = state.allRows,
                    scrollsSideways = state.scrollsSideways,
                    scrollState = tableScroll,
                )
            } else if (state.differentRows.isNotEmpty()) {
                CompareTableCard(
                    title = stringResource(R.string.compare_section_different),
                    rows = state.differentRows,
                    scrollsSideways = state.scrollsSideways,
                    scrollState = tableScroll,
                )
            } else {
                Text(
                    text = stringResource(R.string.compare_no_differences),
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppDesign.colors.muted,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                )
            }
            Text(
                text = stringResource(R.string.compare_footer),
                style = MaterialTheme.typography.bodySmall,
                color = AppDesign.colors.muted,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
            )
        }
    }
}

/** The wines' numbers and names over the table columns, scrolling with them when sideways. */
@Composable
private fun CompareColumnTitles(state: WineCompareState, scrollState: ScrollState) {
    if (state.scrollsSideways) {
        Row(Modifier.fillMaxWidth()) {
            Spacer(Modifier.width(LabelColumnWidth))
            Row(
                modifier = Modifier.weight(1f).horizontalScroll(scrollState),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                state.entries.forEachIndexed { index, entry ->
                    CompareColumnTitle(index + 1, entry.card.presentationTitle, Modifier.width(SidewaysCellWidth))
                }
                Spacer(Modifier.width(4.dp))
            }
        }
    } else {
        // Lines up with the cells inside the table card.
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            state.entries.forEachIndexed { index, entry ->
                CompareColumnTitle(index + 1, entry.card.presentationTitle, Modifier.weight(1f))
            }
        }
    }
}
