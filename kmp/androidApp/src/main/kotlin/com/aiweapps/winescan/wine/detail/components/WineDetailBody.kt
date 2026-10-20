package com.aiweapps.winescan.wine.detail.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
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
import com.aiweapps.winescan.components.wine.detail.WineDetailComponent
import com.aiweapps.winescan.components.wine.detail.model.WineDetailState
import com.aiweapps.winescan.scan.result.components.CatalogueLinkRow
import com.aiweapps.winescan.scan.result.components.WineAboutCard
import com.aiweapps.winescan.scan.result.components.WineHeading
import com.aiweapps.winescan.scan.result.components.WinePairingsCard
import com.aiweapps.winescan.scan.result.components.WineDescription
import com.aiweapps.winescan.scan.result.components.WineFactsError

/** One wine in full: reference, name, actions, the card's facts, the catalogue link, the disclaimer. */
@Composable
fun WineDetailBody(state: WineDetailState, component: WineDetailComponent) {
    val card = state.card
    Column(
        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(vertical = 8.dp),
    ) {
        Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            ReferencePhoto(referenceUrl = state.referenceUrl)
            WineHeading(card = card, tag = null)
            WineDetailActions(
                canCompareWithPhoto = state.canCompareWithPhoto,
                showsCompareToggle = state.canAddToCompare || state.isInCompare,
                isInCompare = state.isInCompare,
                onCompareWithPhotoClicked = component::onCompareWithPhotoClicked,
                onAddToCompareClicked = component::onAddToCompareClicked,
                onRemoveFromCompareClicked = component::onRemoveFromCompareClicked,
            )
            state.factsError?.let { WineFactsError(it, state.isFactsLoading, component::onFactsRetryClicked) }
            WineDescription(card)
            WineAboutCard(card, facts = state.facts, isLoading = state.isFactsLoading, loadError = state.factsError)
            WinePairingsCard(facts = state.facts, isLoading = state.isFactsLoading, loadError = state.factsError)
            CatalogueLinkRow(card = card, onLinkClicked = component::onCatalogueLinkClicked)
        }
        Text(
            text = stringResource(R.string.disclaimer),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(start = 24.dp, end = 24.dp, top = 24.dp),
        )
    }
}
