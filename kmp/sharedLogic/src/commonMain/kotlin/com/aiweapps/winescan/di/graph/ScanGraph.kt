package com.aiweapps.winescan.di.graph

import com.aiweapps.winescan.components.scan.home.DefaultScanHomeComponent
import com.aiweapps.winescan.components.scan.home.ScanHomeComponent
import com.aiweapps.winescan.components.scan.result.DefaultScanResultComponent
import com.aiweapps.winescan.components.scan.result.ScanResultComponent
import com.aiweapps.winescan.components.scan.result.ScanResultSheetFactories
import com.aiweapps.winescan.components.scan.result.sheets.CompareComponent
import com.aiweapps.winescan.components.scan.result.sheets.DefaultCompareComponent
import com.aiweapps.winescan.components.scan.result.sheets.DefaultDrawFrameComponent
import com.aiweapps.winescan.components.scan.result.sheets.DefaultMoreComponent
import com.aiweapps.winescan.components.scan.result.sheets.DefaultTechDetailsComponent
import com.aiweapps.winescan.components.scan.result.sheets.DrawFrameComponent
import com.aiweapps.winescan.components.scan.result.sheets.MoreComponent
import com.aiweapps.winescan.components.scan.result.sheets.TechDetailsComponent
import com.aiweapps.winescan.components.wine.detail.DefaultWineDetailComponent
import com.aiweapps.winescan.components.wine.detail.WineDetailComponent
import com.aiweapps.winescan.di.dependencies.GastronomyDependencies
import com.aiweapps.winescan.di.dependencies.ScanDependencies

class ScanGraph(
    scanDeps: ScanDependencies,
    gastronomy: GastronomyDependencies,
    shared: SharedGraph,
) {

    /** Private: only the result and the wine screens open the photo-against-reference sheet. */
    private val compareSheetFactory = CompareComponent.Factory {
            componentContext, photoPath, crop, frame, bottleNumber, cardTitle, reference, referenceAccess, onClose ->
        DefaultCompareComponent(
            componentContext, photoPath, crop, frame, bottleNumber, cardTitle, reference, referenceAccess, onClose,
        )
    }

    /** Private: only the result screen opens these sheets. */
    private val sheetFactories = ScanResultSheetFactories(
        drawFrame = DrawFrameComponent.Factory { componentContext, photoPath, frame, view, onFrameDrawn, onCancel ->
            DefaultDrawFrameComponent(componentContext, photoPath, frame, view, onFrameDrawn, onCancel)
        },
        compare = compareSheetFactory,
        more = MoreComponent.Factory {
                componentContext, isRoi, bottleNumber, canRescanBottle, canDrawFrame, onRescanBottle, onDrawFrame,
                onShareFull, onShareBottle, onTechDetails ->
            DefaultMoreComponent(
                componentContext, isRoi, bottleNumber, canRescanBottle, canDrawFrame,
                onRescanBottle, onDrawFrame, onShareFull, onShareBottle, onTechDetails,
            )
        },
        techDetails = TechDetailsComponent.Factory { componentContext, rows, onClose ->
            DefaultTechDetailsComponent(componentContext, rows, onClose)
        },
    )

    val homeFactory = ScanHomeComponent.Factory { componentContext, onOpenResult, onOpenHistory ->
        DefaultScanHomeComponent(
            componentContext = componentContext,
            statusMonitor = scanDeps.statusMonitor,
            historyRepository = scanDeps.historyRepository,
            platformLinks = scanDeps.platformLinks,
            analytics = scanDeps.analytics,
            serviceDetailFactory = shared.serviceDetailFactory,
            onOpenResult = onOpenResult,
            onOpenHistory = onOpenHistory,
        )
    }

    val resultFactory = ScanResultComponent.Factory {
            componentContext, target, onClose, onNewScan, onOpenCompare, onOpenPairing, onOpenWineDetail,
            onOpenFramedResult ->
        DefaultScanResultComponent(
            componentContext = componentContext,
            target = target,
            scanRepository = scanDeps.scanRepository,
            historyRepository = scanDeps.historyRepository,
            compareRepository = scanDeps.compareRepository,
            gastronomyRepository = gastronomy.repository,
            appLanguage = gastronomy.appLanguage,
            platformShare = scanDeps.platformShare,
            platformLinks = scanDeps.platformLinks,
            analytics = scanDeps.analytics,
            sheetFactories = sheetFactories,
            json = scanDeps.json,
            onClose = onClose,
            onNewScan = onNewScan,
            onOpenCompare = onOpenCompare,
            onOpenPairing = onOpenPairing,
            onOpenWineDetail = onOpenWineDetail,
            onOpenFramedResult = onOpenFramedResult,
        )
    }

    val wineDetailFactory = WineDetailComponent.Factory { componentContext, target, onClose ->
        DefaultWineDetailComponent(
            componentContext = componentContext,
            target = target,
            scanRepository = scanDeps.scanRepository,
            compareRepository = scanDeps.compareRepository,
            catalog = scanDeps.catalog,
            gastronomyRepository = gastronomy.repository,
            appLanguage = gastronomy.appLanguage,
            platformLinks = scanDeps.platformLinks,
            analytics = scanDeps.analytics,
            compareFactory = compareSheetFactory,
            onClose = onClose,
        )
    }
}
