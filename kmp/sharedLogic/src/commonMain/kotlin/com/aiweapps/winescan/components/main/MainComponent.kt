package com.aiweapps.winescan.components.main

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.router.pages.ChildPages
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.compare.WineCompareComponent
import com.aiweapps.winescan.components.assistant.AssistantComponent
import com.aiweapps.winescan.components.history.HistoryComponent
import com.aiweapps.winescan.components.scan.home.ScanHomeComponent
import com.aiweapps.winescan.components.settings.SettingsComponent
import com.aiweapps.winescan.domain.pairing.model.PairingSource
import com.aiweapps.winescan.domain.scan.model.ScanTarget

/**
 * The three primary destinations, plus secondary history and settings routes. The result and the dish screens are not here: they cover the tabs and
 * live on the root stack.
 */
interface MainComponent {

    val pages: Value<ChildPages<*, TabChild>>

    /** How many wines are in the comparison: the badge on the «Compare» tab. */
    val compareCount: Value<Int>

    fun selectTab(index: Int)

    fun onComparisonRequested(wines: List<com.aiweapps.winescan.domain.scan.model.WineCard>, prompt: String)

    sealed class TabChild {
        class Scan(val component: ScanHomeComponent) : TabChild()
        class History(val component: HistoryComponent) : TabChild()
        class Compare(val component: WineCompareComponent) : TabChild()
        class Settings(val component: SettingsComponent) : TabChild()
        class Assistant(val component: AssistantComponent) : TabChild()
    }

    fun interface Factory {
        fun create(
            componentContext: ComponentContext,
            onOpenResult: (ScanTarget) -> Unit,
            onOpenOnboarding: () -> Unit,
            onOpenPairing: (PairingSource) -> Unit,
        ): MainComponent
    }

    companion object {
        const val SCAN_TAB = 0
        const val HISTORY_TAB = 1
        const val COMPARE_TAB = 2
        const val SETTINGS_TAB = 3
        const val ASSISTANT_TAB = 4
    }
}
