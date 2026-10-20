package com.aiweapps.winescan.di.graph

import com.aiweapps.winescan.components.compare.DefaultWineCompareComponent
import com.aiweapps.winescan.components.compare.WineCompareComponent
import com.aiweapps.winescan.components.compare.picker.DefaultHistoryPickerComponent
import com.aiweapps.winescan.components.compare.picker.HistoryPickerComponent
import com.aiweapps.winescan.components.pairing.DefaultDishPairingComponent
import com.aiweapps.winescan.components.pairing.DishPairingComponent
import com.aiweapps.winescan.di.dependencies.CompareDependencies
import com.aiweapps.winescan.di.dependencies.GastronomyDependencies

class CompareGraph(
    compareDeps: CompareDependencies,
    gastronomy: GastronomyDependencies,
) {

    /** The repository the tab badge counts from. */
    val compareRepository = compareDeps.compareRepository

    /** Private: only the compare tab opens the picker. */
    private val pickerFactory = HistoryPickerComponent.Factory { componentContext, onPick, onClose ->
        DefaultHistoryPickerComponent(
            componentContext = componentContext,
            historyRepository = compareDeps.historyRepository,
            compareRepository = compareDeps.compareRepository,
            onPick = onPick,
            onClose = onClose,
        )
    }

    val compareFactory = WineCompareComponent.Factory { componentContext, onOpenScanner, onOpenPairing, onPlanDinner ->
        DefaultWineCompareComponent(
            componentContext = componentContext,
            compareRepository = compareDeps.compareRepository,
            catalog = compareDeps.catalog,
            historyRepository = compareDeps.historyRepository,
            scanRepository = compareDeps.scanRepository,
            gastronomyRepository = gastronomy.repository,
            appLanguage = gastronomy.appLanguage,
            platformLinks = compareDeps.platformLinks,
            analytics = compareDeps.analytics,
            pickerFactory = pickerFactory,
            onOpenScanner = onOpenScanner,
            onOpenPairing = onOpenPairing,
            onPlanDinner = onPlanDinner,
        )
    }

    val pairingFactory = DishPairingComponent.Factory { componentContext, source, onClose, onOpenScanner, onPlanDinner ->
        DefaultDishPairingComponent(
            componentContext = componentContext,
            source = source,
            compareRepository = compareDeps.compareRepository,
            savedPairingRepository = compareDeps.savedPairingRepository,
            scanRepository = compareDeps.scanRepository,
            gastronomyRepository = gastronomy.repository,
            appLanguage = gastronomy.appLanguage,
            platformLinks = compareDeps.platformLinks,
            analytics = compareDeps.analytics,
            onClose = onClose,
            onOpenScanner = onOpenScanner,
            onPlanDinner = onPlanDinner,
        )
    }
}
