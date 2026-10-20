package com.aiweapps.winescan.wine.detail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import com.aiweapps.winescan.components.AppIcons
import com.aiweapps.winescan.components.ErrorState
import com.aiweapps.winescan.components.LoadingState
import com.aiweapps.winescan.components.ToastEffect
import com.aiweapps.winescan.components.wine.detail.WineDetailComponent
import com.aiweapps.winescan.components.wine.detail.model.WineDetailToast
import com.aiweapps.winescan.wine.detail.components.WineDetailBody
import com.aiweapps.winescan.wine.detail.components.WineDetailSheets
import com.arkivanov.decompose.extensions.compose.subscribeAsState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WineDetailContent(component: WineDetailComponent) {
    val state by component.state.subscribeAsState()
    val modalSlot by component.modalSlot.subscribeAsState()
    val snackbarHost = remember { SnackbarHostState() }
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()

    ToastEffect(
        message = when (state.toast) {
            null -> null
            WineDetailToast.AddedToCompare -> stringResource(R.string.notice_added_to_compare)
            WineDetailToast.AlreadyInCompare -> stringResource(R.string.notice_already_in_compare)
            WineDetailToast.CompareFull -> stringResource(R.string.notice_compare_full)
            WineDetailToast.AddToCompareFailed -> stringResource(R.string.notice_add_to_compare_failed)
            WineDetailToast.RemovedFromCompare -> stringResource(R.string.notice_removed_from_compare)
            WineDetailToast.RemoveFromCompareFailed -> stringResource(R.string.notice_remove_from_compare_failed)
        },
        host = snackbarHost,
        onConsumed = component::onToastConsumed,
    )

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(stringResource(R.string.wine_detail_title)) },
                navigationIcon = {
                    IconButton(onClick = component::onBackClicked) {
                        Icon(AppIcons.Back, stringResource(R.string.common_back))
                    }
                },
                scrollBehavior = scrollBehavior,
            )
        },
        snackbarHost = { SnackbarHost(snackbarHost) },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (val screenState = state.screenState) {
                is ScreenState.Loading -> LoadingState()
                is ScreenState.Error -> ErrorState(error = screenState.error)
                is ScreenState.Content -> WineDetailBody(state = state, component = component)
            }
        }
    }

    WineDetailSheets(modal = modalSlot.child?.instance, onDismissRequest = component::onModalDismissed)
}
