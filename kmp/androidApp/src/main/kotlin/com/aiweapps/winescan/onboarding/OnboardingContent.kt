package com.aiweapps.winescan.onboarding

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.dp
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.R
import com.aiweapps.winescan.components.ErrorState
import com.aiweapps.winescan.components.LoadingState
import com.aiweapps.winescan.components.PagerDots
import com.aiweapps.winescan.components.onboarding.OnboardingComponent
import com.aiweapps.winescan.components.onboarding.model.OnboardingState
import com.aiweapps.winescan.onboarding.components.OnboardingPage
import com.arkivanov.decompose.extensions.compose.subscribeAsState
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.distinctUntilChanged

@Composable
fun OnboardingContent(component: OnboardingComponent) {
    val state by component.state.subscribeAsState()
    when (val screenState = state.screenState) {
        is ScreenState.Loading -> LoadingState()
        is ScreenState.Error -> ErrorState(error = screenState.error)
        is ScreenState.Content -> OnboardingPages(state, component)
    }
}

@Composable
private fun OnboardingPages(state: OnboardingState, component: OnboardingComponent) {
    val pager = rememberPagerState(initialPage = state.pageIndex) { state.pageCount }
    val currentPage by rememberUpdatedState(state.pageIndex)
    // Presentation acknowledgement, not another page owner. Only shared state chooses a page.
    var pendingTarget by remember { mutableStateOf<Int?>(null) }
    val entrance = remember { Animatable(0f) }
    // Built-in Compose animation uses the platform motion-duration scale, including zero.
    LaunchedEffect(Unit) { entrance.animateTo(1f, tween(durationMillis = 220)) }
    LaunchedEffect(state.targetPage) {
        if (pager.settledPage == state.targetPage && !pager.isScrollInProgress) {
            pendingTarget = null
        } else {
            pendingTarget = state.targetPage
            // The request cancels a gesture and lands on the next remeasure; unlike
            // scrollToPage's default-priority mutation it cannot lose to UserInput.
            pager.requestScrollToPage(state.targetPage)
        }
    }
    LaunchedEffect(pager) {
        var observedUserScroll = false
        snapshotFlow { Triple(pager.isScrollInProgress, pager.settledPage, pendingTarget) }
            .distinctUntilChanged().collect { (scrolling, page, target) ->
                when {
                    target != null -> {
                        observedUserScroll = false
                        if (!scrolling && page == target) pendingTarget = null
                    }
                    scrolling -> observedUserScroll = true
                    observedUserScroll -> {
                        observedUserScroll = false
                        if (page != currentPage) component.onPageChanged(page)
                    }
                }
            }
    }
    fun canNavigate() = !pager.isScrollInProgress && pendingTarget == null && pager.settledPage == currentPage
    val navigationReady = canNavigate()
    val goBack: () -> Unit = {
        if (canNavigate() && currentPage > 0) {
            val target = currentPage - 1
            pendingTarget = target
            component.onPageChanged(target)
        }
    }
    val goNext: () -> Unit = {
        if (canNavigate()) {
            if (!state.isLastPage) pendingTarget = currentPage + 1
            component.onNextClicked()
        }
    }
    BackHandler(enabled = state.pageIndex > 0, onBack = goBack)

    Column(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)
        .safeDrawingPadding().graphicsLayer { alpha = entrance.value }) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 24.dp),
            horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Text(stringResource(R.string.app_name), style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.primary)
            TextButton(onClick = component::onSkipClicked, modifier = Modifier.heightIn(min = 48.dp)) {
                Text(stringResource(R.string.onboarding_skip))
            }
        }
        HorizontalPager(state = pager, userScrollEnabled = pendingTarget == null, modifier = Modifier.weight(1f).fillMaxWidth()) { page ->
            OnboardingPage(pageIndex = page)
        }
        Column(Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                PagerDots(count = state.pageCount, current = state.pageIndex,
                    modifier = Modifier.clearAndSetSemantics {})
                Text(stringResource(R.string.onboarding_progress, state.pageIndex + 1, state.pageCount),
                    style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically) {
                if (state.pageIndex > 0) {
                    TextButton(onClick = goBack, enabled = navigationReady,
                        modifier = Modifier.heightIn(min = 48.dp)) {
                        Text(stringResource(R.string.common_back))
                    }
                }
                Button(onClick = goNext, enabled = navigationReady,
                    modifier = Modifier.weight(1f).heightIn(min = 48.dp)) {
                    Text(stringResource(if (state.isLastPage) R.string.onboarding_open_assistant else R.string.onboarding_next))
                }
            }
            Text(stringResource(R.string.disclaimer), style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
