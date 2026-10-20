package com.aiweapps.winescan.main

import com.aiweapps.winescan.components.AppIcons

import android.os.Build
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.isImeVisible
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import com.aiweapps.winescan.R
import com.aiweapps.winescan.compare.WineCompareContent
import com.aiweapps.winescan.assistant.AssistantContent
import com.aiweapps.winescan.components.main.MainComponent
import com.aiweapps.winescan.history.HistoryContent
import com.aiweapps.winescan.scan.home.ScanHomeContent
import com.aiweapps.winescan.settings.SettingsContent
import com.arkivanov.decompose.extensions.compose.subscribeAsState
import dev.chrisbanes.haze.HazeStyle
import dev.chrisbanes.haze.HazeTint
import dev.chrisbanes.haze.hazeEffect
import dev.chrisbanes.haze.hazeSource
import dev.chrisbanes.haze.rememberHazeState

private class TabSpec(
    val label: Int,
    val selectedIcon: ImageVector,
    val icon: ImageVector,
    val description: Int = label,
    val destination: Int,
)

private val Tabs = listOf(
    TabSpec(R.string.tab_assistant, AppIcons.Chat, AppIcons.Chat, destination = MainComponent.ASSISTANT_TAB),
    TabSpec(R.string.tab_scan, AppIcons.Camera, AppIcons.Camera, destination = MainComponent.SCAN_TAB),
    TabSpec(R.string.tab_compare_short, AppIcons.Compare, AppIcons.Compare, R.string.tab_compare, MainComponent.COMPARE_TAB),
)

@OptIn(ExperimentalMaterial3Api::class, androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
@Composable
fun MainContent(component: MainComponent) {
    val pages by component.pages.subscribeAsState()
    val compareCount by component.compareCount.subscribeAsState()

    val secondaryDestination = pages.selectedIndex in listOf(MainComponent.HISTORY_TAB, MainComponent.SETTINGS_TAB)
    val keyboardVisible = WindowInsets.isImeVisible
    val savedPages = rememberSaveableStateHolder()
    val glass = rememberHazeState(blurEnabled = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
    BackHandler(enabled = pages.selectedIndex != MainComponent.ASSISTANT_TAB) { component.selectTab(MainComponent.ASSISTANT_TAB) }

    Scaffold(
        bottomBar = {
            if (!keyboardVisible && !secondaryDestination) {
                val colors = MaterialTheme.colorScheme
                val shape = RoundedCornerShape(50)
                Surface(
                    modifier = Modifier
                        .navigationBarsPadding()
                        .padding(horizontal = 12.dp, vertical = 8.dp)
                        .fillMaxWidth()
                        .shadow(3.dp, shape)
                        .clip(shape)
                        .hazeEffect(
                            state = glass,
                            style = HazeStyle(
                                backgroundColor = colors.background,
                                tint = HazeTint(colors.surface.copy(alpha = 0.58f)),
                                blurRadius = 22.dp,
                                noiseFactor = 0.025f,
                                fallbackTint = HazeTint(colors.surface.copy(alpha = 0.94f)),
                            ),
                        )
                        .background(Brush.verticalGradient(listOf(
                            colors.surface.copy(alpha = 0.3f),
                            colors.surface.copy(alpha = 0.04f),
                            colors.surface.copy(alpha = 0.14f),
                        ))),
                    shape = shape,
                    color = colors.surface.copy(alpha = 0f),
                    tonalElevation = 0.dp,
                    shadowElevation = 0.dp,
                    border = BorderStroke(
                        1.dp,
                        Brush.verticalGradient(listOf(colors.surface.copy(alpha = 0.98f), colors.outlineVariant.copy(alpha = 0.45f))),
                    ),
                ) {
                    Row(Modifier.fillMaxWidth().height(68.dp).selectableGroup()) {
                        Tabs.forEach { tab ->
                            val selected = tab.destination == pages.selectedIndex
                            NavigationBarItem(
                                selected = selected,
                                onClick = { component.selectTab(tab.destination) },
                                colors = NavigationBarItemDefaults.colors(
                                    selectedIconColor = MaterialTheme.colorScheme.primary,
                                    selectedTextColor = MaterialTheme.colorScheme.primary,
                                    indicatorColor = MaterialTheme.colorScheme.surface.copy(alpha = 0f),
                                ),
                                icon = {
                                    val icon = if (selected) tab.selectedIcon else tab.icon
                                    if (tab.destination == MainComponent.COMPARE_TAB && compareCount > 0) {
                                        BadgedBox(badge = { Badge { Text(compareCount.toString()) } }) {
                                            Icon(imageVector = icon, contentDescription = stringResource(tab.description))
                                        }
                                    } else {
                                        Icon(imageVector = icon, contentDescription = stringResource(tab.description))
                                    }
                                },
                                label = {
                                    Text(
                                        stringResource(tab.label),
                                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp, letterSpacing = 0.sp),
                                        maxLines = 1,
                                        softWrap = false,
                                        overflow = TextOverflow.Ellipsis,
                                    )
                                },
                            )
                        }
                    }
                }
            }
        },
    ) { padding ->
        Box(
            Modifier.fillMaxSize()
                .hazeSource(state = glass)
                .background(MaterialTheme.colorScheme.background)
                .padding(bottom = padding.calculateBottomPadding())
                .consumeWindowInsets(PaddingValues(bottom = padding.calculateBottomPadding())),
        ) {
            savedPages.SaveableStateProvider(pages.selectedIndex) {
                when (val instance = pages.items.getOrNull(pages.selectedIndex)?.instance) {
                is MainComponent.TabChild.Scan -> ScanHomeContent(instance.component)
                is MainComponent.TabChild.History -> HistoryContent(
                    instance.component, onBack = { component.selectTab(MainComponent.ASSISTANT_TAB) },
                )
                is MainComponent.TabChild.Compare -> WineCompareContent(instance.component)
                is MainComponent.TabChild.Settings -> SettingsContent(
                    instance.component, onBack = { component.selectTab(MainComponent.ASSISTANT_TAB) },
                )
                is MainComponent.TabChild.Assistant -> AssistantContent(
                    instance.component,
                    onOpenScanHistory = { component.selectTab(MainComponent.HISTORY_TAB) },
                    onOpenSettings = { component.selectTab(MainComponent.SETTINGS_TAB) },
                )
                null -> Unit
                }
            }
        }
    }
}
