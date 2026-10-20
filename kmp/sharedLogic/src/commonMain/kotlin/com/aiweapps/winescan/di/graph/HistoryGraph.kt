package com.aiweapps.winescan.di.graph

import com.aiweapps.winescan.components.history.DefaultHistoryComponent
import com.aiweapps.winescan.components.history.HistoryComponent
import com.aiweapps.winescan.di.dependencies.HistoryDependencies

class HistoryGraph(
    historyDeps: HistoryDependencies,
    shared: SharedGraph,
) {

    val historyFactory = HistoryComponent.Factory { componentContext, onOpenScan, onOpenScanner, onOpenPairing ->
        DefaultHistoryComponent(
            componentContext = componentContext,
            repository = historyDeps.historyRepository,
            savedPairingRepository = historyDeps.savedPairingRepository,
            compareRepository = historyDeps.compareRepository,
            favorites = historyDeps.favorites,
            appLanguage = historyDeps.appLanguage,
            confirmClearFactory = shared.confirmClearHistoryFactory,
            onOpenScan = onOpenScan,
            onOpenScanner = onOpenScanner,
            onOpenPairing = onOpenPairing,
        )
    }
}
