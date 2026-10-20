package com.aiweapps.winescan.scan.result

import com.aiweapps.winescan.components.AppIcons

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.ui.Alignment
import androidx.compose.ui.unit.dp
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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.ErrorState
import com.aiweapps.winescan.components.LoadingState
import com.aiweapps.winescan.components.ToastEffect
import com.aiweapps.winescan.components.scan.result.ScanResultComponent
import com.aiweapps.winescan.components.scan.result.model.ResultPhase
import com.aiweapps.winescan.components.scan.result.model.ScanResultToast
import com.aiweapps.winescan.scan.result.components.ResultAnswerList
import com.aiweapps.winescan.scan.result.components.ResultSheets
import com.aiweapps.winescan.components.ComparePill
import com.arkivanov.decompose.extensions.compose.subscribeAsState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScanResultContent(component: ScanResultComponent) {
    val state by component.state.subscribeAsState()
    val modalSlot by component.modalSlot.subscribeAsState()
    val snackbarHost = remember { SnackbarHostState() }
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()
    val haptics = LocalHapticFeedback.current

    // A new answer is worth a tick: the user is looking at the screen, not the spinner.
    LaunchedEffect(state.phase) {
        if (state.phase == ResultPhase.ANSWER) haptics.performHapticFeedback(HapticFeedbackType.Confirm)
    }
    ToastEffect(
        message = when (val toast = state.toast) {
            null -> null
            ScanResultToast.RoiFound -> stringResource(R.string.notice_roi_found)
            ScanResultToast.RoiEmpty -> stringResource(R.string.notice_roi_empty)
            is ScanResultToast.ManyBottles -> stringResource(R.string.notice_many_bottles, toast.count)
            ScanResultToast.AddedToCompare -> stringResource(R.string.notice_added_to_compare)
            ScanResultToast.AlreadyInCompare -> stringResource(R.string.notice_already_in_compare)
            ScanResultToast.CompareFull -> stringResource(R.string.notice_compare_full)
            ScanResultToast.AddToCompareFailed -> stringResource(R.string.notice_add_to_compare_failed)
            ScanResultToast.RemovedFromCompare -> stringResource(R.string.notice_removed_from_compare)
            ScanResultToast.RemoveFromCompareFailed -> stringResource(R.string.notice_remove_from_compare_failed)
        },
        host = snackbarHost,
        onConsumed = component::onToastConsumed,
    )

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(stringResource(R.string.result_title)) },
                navigationIcon = {
                    IconButton(onClick = component::onBackClicked) {
                        Icon(AppIcons.Back, stringResource(R.string.common_back))
                    }
                },
                actions = {
                    if (state.hasAnswer) {
                        IconButton(onClick = component::onMoreClicked) {
                            Icon(AppIcons.More, stringResource(R.string.result_more))
                        }
                    }
                },
                scrollBehavior = scrollBehavior,
            )
        },
        // The reference viewer opens from the photo block, so the only bottom action left
        // is the way into the comparison.
        bottomBar = {
            if (state.screenState is ScreenState.Content && state.canOpenCompare) {
                Box(Modifier.fillMaxWidth().navigationBarsPadding().padding(horizontal = 16.dp, vertical = 8.dp),
                    contentAlignment = Alignment.Center) {
                    ComparePill(count = state.compareCount, onClick = component::onCompareWinesClicked)
                }
            }
        },
        snackbarHost = { SnackbarHost(snackbarHost) },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (val screenState = state.screenState) {
                is ScreenState.Loading -> LoadingState()
                is ScreenState.Error -> ErrorState(error = screenState.error)
                is ScreenState.Content -> ResultAnswerList(state = state, component = component)
            }
        }
    }

    ResultSheets(modal = modalSlot.child?.instance, onDismissRequest = component::onModalDismissed)
}
