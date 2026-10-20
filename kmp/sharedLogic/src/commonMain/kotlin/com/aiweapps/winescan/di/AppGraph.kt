package com.aiweapps.winescan.di

import com.aiweapps.winescan.di.dependencies.AppDependencies
import com.aiweapps.winescan.di.graph.CompareGraph
import com.aiweapps.winescan.di.graph.AssistantGraph
import com.aiweapps.winescan.di.graph.HistoryGraph
import com.aiweapps.winescan.di.graph.RootGraph
import com.aiweapps.winescan.di.graph.ScanGraph
import com.aiweapps.winescan.di.graph.SettingsGraph
import com.aiweapps.winescan.di.graph.SharedGraph

class AppGraph(deps: AppDependencies) {

    val shared = SharedGraph()
    val scan = ScanGraph(scanDeps = deps.scan, gastronomy = deps.gastronomy, shared = shared)
    val history = HistoryGraph(historyDeps = deps.history, shared = shared)
    val compare = CompareGraph(compareDeps = deps.compare, gastronomy = deps.gastronomy)
    val settings = SettingsGraph(settingsDeps = deps.settings, shared = shared)
    val assistant = AssistantGraph(
        deps.scan.scanRepository, deps.scan.historyRepository,
        deps.assistantService, deps.retailGateway, deps.assistantAccount,
        deps.assistantLocalRepository,
        deps.scan.platformLinks,
        deps.scan.catalog,
        deps.compare.compareRepository,
    )
    val root = RootGraph(
        scan = scan,
        history = history,
        compare = compare,
        settings = settings,
        assistant = assistant,
        preferences = deps.preferences,
        themeRepository = deps.settings.themeRepository,
        analytics = deps.analytics,
    )
}
