package com.aiweapps.winescan.compare

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.aiweapps.core.components.model.ScreenState
import androidx.compose.ui.unit.dp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.compare.components.CompareBody
import com.aiweapps.winescan.compare.components.CompareAddMenu
import com.aiweapps.winescan.compare.components.CompareEmpty
import com.aiweapps.winescan.compare.components.HistoryPickerSheet
import com.aiweapps.winescan.components.AppModalBottomSheet
import com.aiweapps.winescan.components.ErrorState
import com.aiweapps.winescan.components.LoadingState
import com.aiweapps.winescan.components.ToastEffect
import com.aiweapps.winescan.components.compare.WineCompareComponent
import com.aiweapps.winescan.components.compare.model.WineCompareToast
import com.arkivanov.decompose.extensions.compose.subscribeAsState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WineCompareContent(component: WineCompareComponent) {
    val state by component.state.subscribeAsState()
    val modalSlot by component.modalSlot.subscribeAsState()
    val snackbarHost = remember { SnackbarHostState() }

    ToastEffect(
        message = when (state.toast) {
            WineCompareToast.ADDED -> stringResource(R.string.compare_toast_added)
            WineCompareToast.ALREADY_THERE -> stringResource(R.string.compare_toast_already_there)
            WineCompareToast.FULL -> stringResource(R.string.compare_toast_full)
            WineCompareToast.ADD_FAILED -> stringResource(R.string.compare_toast_add_failed)
            WineCompareToast.REMOVE_FAILED -> stringResource(R.string.compare_remove_failed)
            null -> null
        },
        host = snackbarHost,
        onConsumed = component::onToastConsumed,
    )

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(stringResource(R.string.compare_title)) },
                actions = {
                    CompareAddMenu(
                        enabled = state.screenState is ScreenState.Content && state.canAddMore,
                        onPickFromHistoryClicked = component::onPickFromHistoryClicked,
                        onNewScanClicked = component::onScanClicked,
                    )
                },
            )
        },
        snackbarHost = { SnackbarHost(snackbarHost) },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (val screenState = state.screenState) {
                is ScreenState.Loading -> LoadingState()
                is ScreenState.Error -> ErrorState(error = screenState.error)
                is ScreenState.Content ->
                    if (state.entries.isEmpty()) {
                        CompareEmpty(
                            onPickFromHistoryClicked = component::onPickFromHistoryClicked,
                            onScanClicked = component::onScanClicked,
                        )
                    } else {
                        CompareBody(state = state, component = component)
                    }
            }
        }
    }

    AppModalBottomSheet(
        modal = modalSlot.child?.instance,
        onDismissRequest = component::onModalDismissed,
    ) { modal ->
        when (modal) {
            is WineCompareComponent.Modal.HistoryPicker -> HistoryPickerSheet(modal.component)
        }
    }
}
