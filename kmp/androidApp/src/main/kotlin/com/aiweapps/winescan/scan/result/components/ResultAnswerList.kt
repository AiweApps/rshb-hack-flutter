package com.aiweapps.winescan.scan.result.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.scan.result.ScanResultComponent
import com.aiweapps.winescan.components.scan.result.model.ResultPhase
import com.aiweapps.winescan.components.scan.result.model.ScanResultState
import com.aiweapps.winescan.domain.scan.model.EmptyAnswer
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.ScanDecision

/** The answer for the current phase and the disclaimer under it. */
@Composable
fun ResultAnswerList(state: ScanResultState, component: ScanResultComponent) {
    Column(
        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(vertical = 8.dp),
    ) {
        when (state.phase) {
            ResultPhase.RECOGNIZING, ResultPhase.WAITING_RETRY -> ResultLoadingPanel(state)
            ResultPhase.FAILED -> state.failure?.let {
                ResultErrorPanel(
                    failure = it,
                    onRetryClicked = component::onRetryClicked,
                    onNewScanClicked = component::onNewScanClicked,
                )
            }
            ResultPhase.ANSWER -> state.view?.let { AnswerBody(state, it, component) }
        }
        Spacer(Modifier.height(24.dp))
        Text(
            text = stringResource(R.string.disclaimer),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp),
        )
    }
}

@Composable
private fun AnswerBody(state: ScanResultState, view: RecognitionView, component: ScanResultComponent) {
    if (view.bottles.isEmpty()) {
        val title = view.decisionKind.label() ?: ScanDecision.INSUFFICIENT_EVIDENCE.label()
        val text = when (view.emptyAnswer) {
            EmptyAnswer.ROI_NO_TARGET ->
                if (state.isFramed) R.string.result_no_bottle_advice_framed else R.string.result_no_bottle_advice_roi
            EmptyAnswer.ROI ->
                if (state.isFramed) R.string.result_no_bottle_framed else R.string.result_no_bottle_roi
            EmptyAnswer.AUTO_NO_TARGET -> R.string.result_no_bottle_advice_auto
            EmptyAnswer.AUTO -> R.string.result_no_bottle_auto
        }
        ResultEmptyCard(
            title = title,
            text = stringResource(text),
            modifier = Modifier.padding(horizontal = 16.dp),
        )
        return
    }

    Column(horizontalAlignment = Alignment.Start) {
        if (view.bottles.size > 1) {
            BottleChips(
                view = view,
                selectedInstanceId = state.selectedInstanceId,
                winnerInstanceId = state.winnerInstanceId,
                onSelected = component::onBottleSelected,
            )
            Spacer(Modifier.height(16.dp))
        }
        val selected = state.selectedBottle
        if (selected == null) {
            BottlesOverview(
                view = view,
                referenceAccess = state.referenceAccess,
                isInCompare = state::isInCompare,
                onBottleClicked = component::onBottleSelected,
                onAddToCompareClicked = component::onAddToCompareClicked,
                onRemoveFromCompareClicked = component::onRemoveFromCompareClicked,
                onLinkClicked = component::onCardLinkClicked,
            )
        } else {
            BottleAnswer(
                state = state,
                view = view,
                bottle = selected,
                actions = BottleAnswerActions(
                    onCompareCardClicked = { component.onCompareCardClicked(selected.instanceId, it) },
                    onAlternativeClicked = { component.onAlternativeClicked(selected.instanceId, it) },
                    onAddToCompareClicked = { component.onAddToCompareClicked(selected.instanceId) },
                    onRemoveFromCompareClicked = { component.onRemoveFromCompareClicked(selected.instanceId) },
                    onPairDishClicked = { component.onPairDishClicked(selected.instanceId) },
                    onLinkClicked = component::onCardLinkClicked,
                    onFactsRetryClicked = component::onFactsRetryClicked,
                ),
            )
        }
    }
}
