package com.aiweapps.winescan.history

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.IconButton
import androidx.compose.material3.Icon
import com.aiweapps.winescan.components.AppIcons
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.res.stringResource
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.ConfirmClearDialog
import com.aiweapps.winescan.components.ErrorState
import com.aiweapps.winescan.components.LoadingState
import com.aiweapps.winescan.components.ToastEffect
import com.aiweapps.winescan.components.history.HistoryComponent
import com.aiweapps.winescan.components.history.model.HistoryToast
import com.aiweapps.winescan.history.components.HistoryEmpty
import com.aiweapps.winescan.history.components.HistoryList
import com.aiweapps.winescan.history.components.HistoryMenu
import com.arkivanov.decompose.extensions.compose.subscribeAsState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryContent(component: HistoryComponent, onBack: (() -> Unit)? = null) {
    val state by component.state.subscribeAsState()
    val modalSlot by component.modalSlot.subscribeAsState()
    val snackbarHost = remember { SnackbarHostState() }
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()

    ToastEffect(
        message = when (state.toast) {
            HistoryToast.DELETED -> stringResource(R.string.history_deleted)
            HistoryToast.DELETE_FAILED -> stringResource(R.string.history_delete_failed)
            HistoryToast.CLEARED -> stringResource(R.string.history_cleared)
            HistoryToast.CLEAR_FAILED -> stringResource(R.string.history_clear_failed)
            HistoryToast.PAIRING_DELETED -> stringResource(R.string.history_pairing_deleted)
            HistoryToast.PAIRING_DELETE_FAILED -> stringResource(R.string.history_pairing_delete_failed)
            HistoryToast.ADDED_TO_COMPARE -> stringResource(R.string.notice_added_to_compare)
            HistoryToast.ALREADY_IN_COMPARE -> stringResource(R.string.notice_already_in_compare)
            HistoryToast.COMPARE_FULL -> stringResource(R.string.notice_compare_full)
            HistoryToast.ADD_TO_COMPARE_FAILED -> stringResource(R.string.notice_add_to_compare_failed)
            HistoryToast.REMOVED_FROM_COMPARE -> stringResource(R.string.notice_removed_from_compare)
            HistoryToast.REMOVE_FROM_COMPARE_FAILED -> stringResource(R.string.notice_remove_from_compare_failed)
            HistoryToast.ADDED_TO_FAVORITES -> stringResource(R.string.history_favorite_added)
            HistoryToast.REMOVED_FROM_FAVORITES -> stringResource(R.string.history_favorite_removed)
            HistoryToast.FAVORITES_FAILED -> stringResource(R.string.history_favorite_failed)
            null -> null
        },
        host = snackbarHost,
        onConsumed = component::onToastConsumed,
    )

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(stringResource(R.string.history_title)) },
                navigationIcon = {
                    onBack?.let { back ->
                        IconButton(onClick = back) {
                            Icon(AppIcons.Back, contentDescription = stringResource(R.string.common_back))
                        }
                    }
                },
                actions = {
                    if (state.canClear) HistoryMenu(onClearClicked = component::onClearClicked)
                },
                scrollBehavior = scrollBehavior,
            )
        },
        snackbarHost = { SnackbarHost(snackbarHost) },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (val screenState = state.screenState) {
                is ScreenState.Loading -> LoadingState()
                is ScreenState.Error -> ErrorState(error = screenState.error, onRetry = component::onRetry)
                is ScreenState.Content ->
                    if (state.isEmpty) {
                        HistoryEmpty(onScanNowClicked = component::onScanNowClicked)
                    } else {
                        HistoryList(state, component)
                    }
            }
        }
    }

    val modal = modalSlot.child?.instance
    if (modal is HistoryComponent.Modal.ConfirmClear) {
        ConfirmClearDialog(component = modal.component, onDismissRequest = component::onModalDismissed)
    }
}
