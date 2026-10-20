package com.aiweapps.winescan.pairing

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.components.ErrorState
import com.aiweapps.winescan.components.LoadingState
import com.aiweapps.winescan.components.ToastEffect
import com.aiweapps.winescan.components.pairing.DishPairingComponent
import com.aiweapps.winescan.components.pairing.model.DishPairingState
import com.aiweapps.winescan.components.pairing.model.DishPairingToast
import com.aiweapps.winescan.pairing.components.DishChips
import com.aiweapps.winescan.pairing.components.PairingBottomActions
import com.aiweapps.winescan.pairing.components.PairingEmptyNotice
import com.aiweapps.winescan.pairing.components.PairingResults
import com.aiweapps.winescan.pairing.components.PairingWineRow
import com.aiweapps.winescan.uikit.theme.AppDesign
import com.arkivanov.decompose.extensions.compose.subscribeAsState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DishPairingContent(component: DishPairingComponent) {
    val state by component.state.subscribeAsState()
    val snackbarHost = remember { SnackbarHostState() }
    var customDishShown by rememberSaveable { mutableStateOf(false) }
    var customDish by rememberSaveable { mutableStateOf("") }

    ToastEffect(
        message = when (state.toast) {
            DishPairingToast.SAVED -> stringResource(R.string.pairing_saved)
            DishPairingToast.SAVE_FAILED -> stringResource(R.string.pairing_save_failed)
            null -> null
        },
        host = snackbarHost,
        onConsumed = component::onToastConsumed,
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(stringResource(R.string.pairing_title))
                        if (state.wineCount > 0) {
                            Text(
                                text = pluralStringResource(
                                    R.plurals.pairing_among_wines,
                                    state.wineCount,
                                    state.wineCount,
                                ),
                                style = MaterialTheme.typography.bodySmall,
                                color = AppDesign.colors.muted,
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = component::onBackClicked) {
                        Icon(AppIcons.Back, stringResource(R.string.common_back))
                    }
                },
            )
        },
        bottomBar = {
            // Without a chosen dish (or a saved one) there is nothing to save or change yet.
            val hasAnswer = state.selectedDish != null || state.savedId != null
            if (state.screenState is ScreenState.Content && !state.hasNoDishes && hasAnswer) {
                PairingBottomActions(state = state, component = component)
            }
        },
        snackbarHost = { SnackbarHost(snackbarHost) },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (val screenState = state.screenState) {
                is ScreenState.Loading -> LoadingState()
                is ScreenState.Error -> ErrorState(error = screenState.error)
                is ScreenState.Content -> PairingBody(state, component, onOtherDish = { customDishShown = true })
            }
        }
    }
    if (customDishShown && state.wines.isNotEmpty()) {
        val prompt = stringResource(R.string.pairing_custom_dish_prompt, customDish.trim())
        AlertDialog(
            onDismissRequest = { customDishShown = false },
            title = { Text(stringResource(R.string.pairing_other_dish)) },
            text = {
                OutlinedTextField(
                    value = customDish,
                    onValueChange = { customDish = it },
                    label = { Text(stringResource(R.string.pairing_custom_dish_label)) },
                    singleLine = true,
                )
            },
            confirmButton = {
                TextButton(
                    enabled = customDish.isNotBlank() && !state.isSaving,
                    onClick = {
                        customDishShown = false
                        component.onCustomDishRequested(dish = customDish.trim(), prompt = prompt)
                    },
                    modifier = Modifier.heightIn(min = 48.dp),
                ) {
                    Text(stringResource(R.string.pairing_custom_dish_action))
                }
            },
            dismissButton = {
                TextButton(onClick = { customDishShown = false }, modifier = Modifier.heightIn(min = 48.dp)) {
                    Text(stringResource(R.string.common_cancel))
                }
            },
        )
    }
}

@Composable
private fun PairingBody(state: DishPairingState, component: DishPairingComponent, onOtherDish: () -> Unit) {
    val dish = state.selectedDish
    Column(
        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        if (state.wines.isEmpty()) {
            PairingEmptyNotice(title = null, text = stringResource(R.string.pairing_no_wines))
            AddWineButton(component)
            return@Column
        }
        if (dish == null) {
            Text(
                text = stringResource(R.string.pairing_intro),
                style = MaterialTheme.typography.bodyMedium,
                color = AppDesign.colors.muted,
            )
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = stringResource(R.string.pairing_wines_title),
                    style = MaterialTheme.typography.titleSmall,
                )
                state.wines.forEach { wine ->
                    PairingWineRow(
                        card = wine.card,
                        photoPath = wine.photoPath,
                        crop = wine.crop,
                        frame = wine.frame,
                        referenceAccess = state.referenceAccess,
                    )
                }
            }
            if (state.hasNoDishes) {
                Text(
                    text = stringResource(R.string.pairing_no_dishes),
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppDesign.colors.muted,
                )
                AddWineButton(component)
            } else {
                Text(stringResource(R.string.pairing_question), style = MaterialTheme.typography.titleLarge)
            }
            DishChips(
                dishes = state.dishes,
                enabled = !state.isSaving,
                onSelected = component::onDishTapped,
                onOtherDish = onOtherDish,
            )
            if (state.isLoadingDishes) {
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
            }
        } else {
            Text(dish.label, style = MaterialTheme.typography.titleLarge)
            if (state.hasNoMatches) {
                Text(
                    text = stringResource(R.string.pairing_no_matches_text),
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppDesign.colors.muted,
                )
            }
            PairingResults(dish = dish, state = state, referenceAccess = state.referenceAccess)
        }
        Text(
            text = stringResource(R.string.pairing_categories_caption),
            style = MaterialTheme.typography.bodySmall,
            color = AppDesign.colors.muted,
        )
    }
}

@Composable
private fun AddWineButton(component: DishPairingComponent) {
    OutlinedButton(onClick = component::onAddWineClicked, modifier = Modifier.heightIn(min = 48.dp)) {
        Icon(AppIcons.Add, contentDescription = null)
        Text(stringResource(R.string.pairing_add_more), modifier = Modifier.padding(start = 8.dp))
    }
}
