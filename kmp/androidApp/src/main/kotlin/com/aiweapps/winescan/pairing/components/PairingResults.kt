package com.aiweapps.winescan.pairing.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.pairing.model.DishPairingState
import com.aiweapps.winescan.domain.gastronomy.model.DishLabel
import com.aiweapps.winescan.domain.pairing.model.PairingVerdict
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess

/** Every wine stays visible: an unlisted dish is not a recommendation against it. */
@Composable
fun PairingResults(dish: DishLabel, state: DishPairingState, referenceAccess: ReferenceAccess?) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(
            text = stringResource(R.string.pairing_matched_count, state.matched.size, state.matches.size),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        state.matches.forEachIndexed { index, match ->
            if (index > 0) HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
            PairingMatchRow(
                match = match,
                referenceAccess = referenceAccess,
                explanation = when (match.verdict) {
                    PairingVerdict.MATCH -> stringResource(R.string.pairing_match_explanation, dish.label)
                    PairingVerdict.NO_MATCH -> stringResource(R.string.pairing_not_listed)
                    PairingVerdict.NO_DATA -> stringResource(R.string.pairing_no_data_text)
                },
                isMatch = match.verdict == PairingVerdict.MATCH,
            )
        }
    }
}
