package com.aiweapps.winescan.pairing.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.pairing.DishPairingComponent
import com.aiweapps.winescan.components.pairing.model.DishPairingState

/** One compact primary action; secondary actions wrap only when space is insufficient. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun PairingBottomActions(state: DishPairingState, component: DishPairingComponent) {
    Surface(color = MaterialTheme.colorScheme.background) {
        FlowRow(
            modifier = Modifier.navigationBarsPadding().padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            if (state.hasNoMatches) {
                Button(onClick = component::onChangeDishClicked, modifier = actionModifier) {
                    Text(stringResource(R.string.pairing_change_dish))
                }
                TextButton(onClick = component::onAddWineClicked, modifier = actionModifier) {
                    Text(stringResource(R.string.pairing_add_more))
                }
            } else {
                Button(
                    onClick = component::onSaveClicked,
                    enabled = state.canSave,
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    modifier = actionModifier,
                ) {
                    if (state.isSaving) {
                        CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
                    } else {
                        Text(
                            stringResource(if (state.savedId != null) R.string.pairing_saved else R.string.pairing_save),
                        )
                    }
                }
                TextButton(
                    onClick = component::onChangeDishClicked,
                    enabled = !state.isSaving,
                    modifier = actionModifier,
                ) {
                    Text(stringResource(R.string.pairing_change_dish))
                }
            }
        }
    }
}

private val actionModifier = Modifier.heightIn(min = 48.dp)
