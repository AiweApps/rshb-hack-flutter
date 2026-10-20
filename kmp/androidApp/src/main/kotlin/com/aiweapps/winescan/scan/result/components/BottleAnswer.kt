package com.aiweapps.winescan.scan.result.components

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.scan.result.model.ScanResultState
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.RecognizedBottle
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.uikit.theme.AppDesign

private const val VERDICT_ALPHA = 0.16f

/** What the answer for one bottle needs to tell the component. */
class BottleAnswerActions(
    val onCompareCardClicked: (WineCard) -> Unit,
    val onAlternativeClicked: (WineCard) -> Unit,
    val onAddToCompareClicked: () -> Unit,
    val onRemoveFromCompareClicked: () -> Unit,
    val onPairDishClicked: () -> Unit,
    val onLinkClicked: (String) -> Unit,
    val onFactsRetryClicked: () -> Unit,
)

/**
 * The answer for one bottle: the photo beside the reference, then the wine's name first and
 * largest, the verdict, the compare / dish actions, the card's facts, and the alternatives.
 */
@Composable
fun BottleAnswer(
    state: ScanResultState,
    view: RecognitionView,
    bottle: RecognizedBottle,
    actions: BottleAnswerActions,
) {
    val best = bottle.best
    val verdict = bottle.decisionKind.label()
    val referenceAccess = state.referenceAccess

    Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        if (best != null) {
            ComparePanes(
                photoPath = state.photoPath,
                crop = view.cropOf(bottle),
                frame = view.frame,
                referenceUrl = referenceAccess?.resolve(best.reference),
                onExpandClicked = { actions.onCompareCardClicked(best) },
            )
            WineHeading(card = best, tag = stringResource(R.string.result_best_match))
        }
        if (verdict != null) VerdictChip(verdict)

        if (best == null) {
            ResultEmptyCard(title = null, text = stringResource(R.string.result_no_match_for_bottle))
        } else {
            BestCardActions(
                isInCompare = state.isInCompare(best),
                onAddToCompareClicked = actions.onAddToCompareClicked,
                onRemoveFromCompareClicked = actions.onRemoveFromCompareClicked,
                onPairDishClicked = actions.onPairDishClicked,
            )
            val facts = state.facts[best.slug]
            val factsError = state.factsErrors[best.slug]
            factsError?.let { WineFactsError(it, state.isFactsLoading, actions.onFactsRetryClicked) }
            WineAboutCard(best, facts = facts, isLoading = state.isFactsLoading, loadError = factsError)
            WinePairingsCard(facts = facts, isLoading = state.isFactsLoading, loadError = factsError)
            CatalogueLinkRow(card = best, onLinkClicked = actions.onLinkClicked)
        }
        if (bottle.alternatives.isNotEmpty()) {
            Text(
                text = stringResource(R.string.result_alternatives),
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(top = 12.dp),
            )
            bottle.alternatives.forEach { alternative ->
                WineCardTile(
                    card = alternative,
                    tag = null,
                    referenceUrl = referenceAccess?.resolve(alternative.reference),
                    isBest = false,
                    onLinkClicked = actions.onLinkClicked,
                    onClick = { actions.onAlternativeClicked(alternative) },
                )
            }
        }
    }
}

@Composable
private fun VerdictChip(text: String) {
    val warn = AppDesign.colors.warn
    Surface(shape = RoundedCornerShape(8.dp), color = warn.copy(alpha = VERDICT_ALPHA)) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge,
            color = warn,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
        )
    }
}
