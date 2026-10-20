package com.aiweapps.winescan.components.main

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.pages.ChildPages
import com.arkivanov.decompose.router.pages.Pages
import com.arkivanov.decompose.router.pages.PagesNavigation
import com.arkivanov.decompose.router.pages.childPages
import com.arkivanov.decompose.router.pages.select
import com.arkivanov.decompose.value.MutableValue
import com.arkivanov.decompose.value.Value
import com.aiweapps.core.analytics.AnalyticsTracker
import com.aiweapps.core.components.base.BaseComponent
import com.aiweapps.winescan.components.common.trackScreen
import com.aiweapps.winescan.components.compare.WineCompareComponent
import com.aiweapps.winescan.components.assistant.AssistantComponent
import com.aiweapps.winescan.components.history.HistoryComponent
import com.aiweapps.winescan.components.main.config.TabConfig
import com.aiweapps.winescan.components.scan.home.ScanHomeComponent
import com.aiweapps.winescan.components.settings.SettingsComponent
import com.aiweapps.winescan.config.AnalyticsScreens
import com.aiweapps.winescan.domain.compare.model.AddToCompareResult
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.pairing.model.PairingSource
import com.aiweapps.winescan.domain.scan.model.ScanTarget
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlin.coroutines.CoroutineContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

internal class DefaultMainComponent(
    componentContext: ComponentContext,
    private val scanHomeFactory: ScanHomeComponent.Factory,
    private val historyFactory: HistoryComponent.Factory,
    private val compareFactory: WineCompareComponent.Factory,
    private val settingsFactory: SettingsComponent.Factory,
    private val assistantFactory: AssistantComponent.Factory,
    compareRepository: CompareSetRepository,
    private val analytics: AnalyticsTracker,
    private val onOpenResult: (ScanTarget) -> Unit,
    private val onOpenOnboarding: () -> Unit,
    private val onOpenPairing: (PairingSource) -> Unit,
    mainContext: CoroutineContext = Dispatchers.Main.immediate,
) : MainComponent, BaseComponent(componentContext, mainContext) {

    private val navigation = PagesNavigation<TabConfig>()

    // childPages can dispose an off-screen page. The conversation belongs to the main
    // session, so its owner survives Scan → History → Assistant tab changes.
    private val assistant = assistantFactory.create(componentContext, ::openComparisonFromAssistant)

    override val pages: Value<ChildPages<*, MainComponent.TabChild>> =
        childPages(
            source = navigation,
            serializer = TabConfig.serializer(),
            initialPages = {
                Pages(
                    items = listOf(TabConfig.Scan, TabConfig.History, TabConfig.Compare, TabConfig.Settings, TabConfig.Assistant),
                    selectedIndex = MainComponent.ASSISTANT_TAB,
                )
            },
            childFactory = ::createTab,
        )

    // A single number rather than a screen state, so it stays a plain MutableValue instead
    // of going through BaseStatefulComponent.
    private val _compareCount = MutableValue(0)
    override val compareCount: Value<Int> = _compareCount

    init {
        compareRepository.watch()
            .onEach { entries -> _compareCount.value = entries.size }
            // The badge is a convenience; a failing read leaves the tabs alone.
            .catch { }
            .launchIn(scope)
    }

    override fun selectTab(index: Int) {
        navigation.select(index)
    }

    override fun onComparisonRequested(wines: List<WineCard>, prompt: String) {
        assistant.onComparisonRequested(wines, prompt)
        navigation.select(MainComponent.ASSISTANT_TAB)
    }

    private fun openComparisonFromAssistant(result: AddToCompareResult) {
        navigation.select(MainComponent.COMPARE_TAB)
        if (result == AddToCompareResult.FULL) {
            val compare = pages.value.items.getOrNull(MainComponent.COMPARE_TAB)?.instance as? MainComponent.TabChild.Compare
            compare?.component?.onCapacityReached()
        }
    }

    private fun createTab(config: TabConfig, context: ComponentContext): MainComponent.TabChild {
        context.trackScreen(analytics, screenOf(config))
        return when (config) {
            TabConfig.Scan -> MainComponent.TabChild.Scan(
                scanHomeFactory.create(
                    componentContext = context,
                    onOpenResult = onOpenResult,
                    onOpenHistory = { navigation.select(MainComponent.HISTORY_TAB) },
                )
            )
            TabConfig.History -> MainComponent.TabChild.History(
                historyFactory.create(
                    componentContext = context,
                    onOpenScan = { id -> onOpenResult(ScanTarget.Stored(id)) },
                    onOpenScanner = { navigation.select(MainComponent.SCAN_TAB) },
                    onOpenPairing = onOpenPairing,
                )
            )
            TabConfig.Compare -> MainComponent.TabChild.Compare(
                compareFactory.create(
                    componentContext = context,
                    onOpenScanner = { navigation.select(MainComponent.SCAN_TAB) },
                    onOpenPairing = { onOpenPairing(PairingSource.FromCompareSet) },
                    onPlanDinner = ::onComparisonRequested,
                )
            )
            TabConfig.Settings -> MainComponent.TabChild.Settings(
                settingsFactory.create(componentContext = context, onOpenOnboarding = onOpenOnboarding)
            )
            TabConfig.Assistant -> MainComponent.TabChild.Assistant(
                assistant
            )
        }
    }

    private fun screenOf(config: TabConfig): String = when (config) {
        TabConfig.Scan -> AnalyticsScreens.SCAN
        TabConfig.History -> AnalyticsScreens.HISTORY
        TabConfig.Compare -> AnalyticsScreens.COMPARE
        TabConfig.Settings -> AnalyticsScreens.SETTINGS
        TabConfig.Assistant -> AnalyticsScreens.ASSISTANT
    }
}
