package com.aiweapps.winescan.components.scan.result

import com.aiweapps.winescan.components.common.model.WineFacts
import com.aiweapps.winescan.components.scan.result.model.ResultPhase
import com.aiweapps.winescan.components.scan.result.sheets.CompareComponent
import com.aiweapps.winescan.components.scan.result.sheets.DefaultCompareComponent
import com.aiweapps.winescan.components.scan.result.sheets.DefaultDrawFrameComponent
import com.aiweapps.winescan.components.scan.result.sheets.DefaultMoreComponent
import com.aiweapps.winescan.components.scan.result.sheets.DefaultTechDetailsComponent
import com.aiweapps.winescan.components.scan.result.sheets.DrawFrameComponent
import com.aiweapps.winescan.components.scan.result.sheets.MoreComponent
import com.aiweapps.winescan.components.scan.result.sheets.TechDetailsComponent
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.config.AnalyticsValues
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.RecognizedBottle
import com.aiweapps.winescan.domain.scan.model.ScanFailure
import com.aiweapps.winescan.domain.scan.model.ScanFailureKind
import com.aiweapps.winescan.domain.scan.model.ScanMode
import com.aiweapps.winescan.domain.scan.model.ScanOutcome
import com.aiweapps.winescan.domain.scan.model.ScanTarget
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.domain.scan.model.WineDetailTarget
import com.aiweapps.winescan.components.scan.result.model.ScanResultToast
import com.aiweapps.winescan.testutil.FakeAppLanguageRepository
import com.aiweapps.winescan.testutil.FakeGastronomyRepository
import com.aiweapps.winescan.testutil.FakeCompareSetRepository
import com.aiweapps.winescan.testutil.FakeAnalyticsTracker
import com.aiweapps.winescan.testutil.FakePlatformLinks
import com.aiweapps.winescan.testutil.FakePlatformShare
import com.aiweapps.winescan.testutil.FakeScanHistoryRepository
import com.aiweapps.winescan.testutil.FakeScanRepository
import com.aiweapps.winescan.testutil.TestComponentContext
import com.aiweapps.winescan.testutil.TestDishes
import com.aiweapps.winescan.testutil.gastronomy
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement

@OptIn(ExperimentalCoroutinesApi::class)
class DefaultScanResultComponentTest {

    private val scanRepository = FakeScanRepository()
    private val historyRepository = FakeScanHistoryRepository()
    private val compareRepository = FakeCompareSetRepository()
    private val gastronomyRepository = FakeGastronomyRepository()
    private val platformShare = FakePlatformShare()
    private val analytics = FakeAnalyticsTracker()
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true; explicitNulls = false }

    @Test
    fun everyCardOnScreenGetsItsFactsAndAMissingOneIsNoData() = runTest {
        gastronomyRepository.seed(gastronomy("slug-0", pairings = listOf(TestDishes.FISH)))
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2))

        val state = createComponent(ScanTarget.NewScan("photo.jpg")).state.value

        assertEquals(listOf("Белая рыба"), state.facts["slug-0"]?.pairings?.map { it.label })
        assertEquals(WineFacts.NO_DATA, state.facts["slug-1"])
        assertFalse(state.isFactsLoading)
        assertEquals(listOf(listOf("slug-0", "slug-1")), gastronomyRepository.requestedSlugs, "one request per answer")
    }

    @Test
    fun aRecognisedPhotoIsLoggedWithItsRequestAndBottleCount() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2))

        createComponent(ScanTarget.NewScan("photo.jpg"))

        val params = analytics.eventsNamed(AnalyticsEvents.RECOGNITION_SUCCEEDED).single()
        assertEquals(AnalyticsValues.REQUEST_PHOTO, params[AnalyticsParams.REQUEST])
        assertEquals("2", params[AnalyticsParams.BOTTLES])
    }

    @Test
    fun onlyTheFinalFailureIsLoggedNotTheAutomaticRetries() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Failed(
            ScanFailure(ScanFailureKind.TOO_MANY, statusCode = 429, retryable = true, retryAfterSeconds = 1)
        )
        val component = createComponent(ScanTarget.NewScan("photo.jpg"))
        assertEquals(ResultPhase.WAITING_RETRY, component.state.value.phase)
        assertTrue(analytics.eventsNamed(AnalyticsEvents.RECOGNITION_FAILED).isEmpty())

        scanRepository.nextOutcome = ScanOutcome.Failed(
            ScanFailure(ScanFailureKind.OFFLINE, statusCode = null, retryable = true, retryAfterSeconds = null)
        )
        advanceTimeBy(2_000)

        val params = analytics.eventsNamed(AnalyticsEvents.RECOGNITION_FAILED).single()
        assertEquals("offline", params[AnalyticsParams.REASON])
    }

    @Test
    fun aDrawnFrameIsLoggedAsAFrameRequestOnRetryToo() = runTest {
        val roi = BottleBox(10.0, 10.0, 200.0, 400.0)
        scanRepository.nextOutcome = ScanOutcome.Failed(
            ScanFailure(ScanFailureKind.OFFLINE, statusCode = null, retryable = true, retryAfterSeconds = null)
        )
        val component = createComponent(ScanTarget.Framed(photoPath = "photo.jpg", roi = roi))
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1, mode = ScanMode.EXPLICIT_ROI))

        component.onRetryClicked()

        assertEquals(
            AnalyticsValues.REQUEST_FRAME,
            analytics.eventsNamed(AnalyticsEvents.RECOGNITION_FAILED).single()[AnalyticsParams.REQUEST],
        )
        assertEquals(
            AnalyticsValues.REQUEST_FRAME,
            analytics.eventsNamed(AnalyticsEvents.RECOGNITION_SUCCEEDED).single()[AnalyticsParams.REQUEST],
        )
    }

    @Test
    fun aResultForABottlesOwnBoxIsLoggedAsABottleRequest() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1, mode = ScanMode.EXPLICIT_ROI))

        createComponent(
            ScanTarget.Framed(photoPath = "photo.jpg", roi = BottleBox(0.0, 0.0, 100.0, 100.0), isBottle = true)
        )

        assertEquals(
            AnalyticsValues.REQUEST_BOTTLE,
            analytics.eventsNamed(AnalyticsEvents.RECOGNITION_SUCCEEDED).single()[AnalyticsParams.REQUEST],
            "the screen is the same as for a drawn frame; only analytics tells the bottle apart",
        )
    }

    @Test
    fun aFreshPhotoIsRecognisedAndStoredOnce() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1))

        val component = createComponent(ScanTarget.NewScan("photo.jpg"))

        val state = component.state.value
        assertEquals(ResultPhase.ANSWER, state.phase)
        assertEquals("b1", state.selectedInstanceId, "a single bottle is selected by itself")
        assertEquals(1, historyRepository.saved.size)
        assertEquals(historyRepository.saved.single().id, state.historyId)
    }

    @Test
    fun recogniseOnlyThisBottleInMoreOpensANewFramedResultForItsClampedBox() = runTest {
        val outOfFrame = Json.parseToJsonElement("[-20,500,1100,900]")
        scanRepository.nextOutcome =
            ScanOutcome.Recognized(viewWith(bottles = 2, selectRois = listOf(null, outOfFrame)))
        val opened = mutableListOf<ScanTarget.Framed>()
        val component = createComponent(ScanTarget.NewScan("photo.jpg"), onOpenFramedResult = { opened += it })
        component.onBottleSelected("b2")

        component.onMoreClicked()
        val more = assertIs<ScanResultComponent.Modal.More>(component.modalSlot.value.child?.instance).component
        assertTrue(more.canRescanBottle)
        assertEquals(2, more.bottleNumber, "the row reads «Recognise only bottle 2»")

        more.onRescanBottleClicked()

        val target = opened.single()
        assertEquals(component.state.value.photoPath, target.photoPath)
        assertEquals(BottleBox(x1 = 0.0, y1 = 500.0, x2 = 1000.0, y2 = 900.0), target.roi)
        assertTrue(target.isBottle)
        assertNull(component.modalSlot.value.child, "«More» closes on the way")
        assertEquals(1, scanRepository.recognizeCalls, "the bottle is recognised on the new screen, not here")
        assertEquals(1, historyRepository.saved.size, "only the automatic answer goes to the history")
        assertEquals("b2", component.state.value.selectedInstanceId, "this answer stays as it was")
    }

    @Test
    fun recogniseOnlyThisBottleIsOfferedOnlyForASelectedBottleOfASeveralBottleAnswer() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2, selectRois = listOf(null, null)))
        val opened = mutableListOf<ScanTarget.Framed>()
        val withoutBox = createComponent(ScanTarget.NewScan("photo.jpg"), onOpenFramedResult = { opened += it })
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1))
        val single = createComponent(ScanTarget.NewScan("single.jpg"))
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2))
        val overview = createComponent(ScanTarget.NewScan("overview.jpg"))
        overview.onBottleSelected(null)

        assertFalse(withoutBox.state.value.canRescanBottle, "the service gave the bottle no box to ask for")
        assertFalse(single.state.value.canRescanBottle, "a single bottle is already the whole answer")
        assertFalse(overview.state.value.canRescanBottle, "no bottle is selected on «All»")

        withoutBox.onMoreClicked()
        val more = assertIs<ScanResultComponent.Modal.More>(withoutBox.modalSlot.value.child?.instance).component
        more.onRescanBottleClicked()

        assertFalse(more.canRescanBottle)
        assertTrue(opened.isEmpty())
    }

    @Test
    fun aSeveralBottleAnswerOpensOnTheUniqueMatchedBottleAndCrownsIt() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(
            viewWith(bottles = 3, decisions = listOf("uncertain", "matched", "unknown"))
        )

        val state = createComponent(ScanTarget.NewScan("photo.jpg")).state.value

        assertEquals("b2", state.selectedInstanceId)
        assertEquals("b2", state.winnerInstanceId)
    }

    @Test
    fun aTieOpensOnTheFirstBottleWithoutACrown() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2))

        val component = createComponent(ScanTarget.NewScan("photo.jpg"))

        assertEquals("b1", component.state.value.selectedInstanceId)
        assertNull(component.state.value.winnerInstanceId)

        component.onBottleSelected("b1")

        assertNull(component.state.value.selectedInstanceId, "«All» is still a tap away")
    }

    @Test
    fun aStoredSeveralBottleAnswerOpensOnTheServicesPrimaryBottle() = runTest {
        val id = historyRepository.seed(
            photoPath = "stored.jpg",
            view = viewWith(bottles = 2, primaryInstanceId = "b2"),
        )

        val state = createComponent(ScanTarget.Stored(id)).state.value

        assertEquals("b2", state.selectedInstanceId)
        assertEquals("b2", state.winnerInstanceId)
    }

    @Test
    fun aFrameAnswerWithSeveralBottlesKeepsNoSelectionWithoutAPrimary() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(
            viewWith(bottles = 2, mode = ScanMode.EXPLICIT_ROI, decisions = listOf("uncertain", "matched"))
        )

        val target = ScanTarget.Framed(photoPath = "photo.jpg", roi = BottleBox(0.0, 0.0, 10.0, 10.0))
        val state = createComponent(target).state.value

        assertNull(state.selectedInstanceId, "a frame answer is single-target: no best-bottle pick")
        assertNull(state.winnerInstanceId)
    }

    @Test
    fun aThrottledAnswerRetriesByItselfAfterTheCountdown() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Failed(
            ScanFailure(ScanFailureKind.TOO_MANY, statusCode = 429, retryable = true, retryAfterSeconds = 2)
        )

        val component = createComponent(ScanTarget.NewScan("photo.jpg"))

        assertEquals(ResultPhase.WAITING_RETRY, component.state.value.phase)
        assertEquals(2, component.state.value.retrySecondsLeft)

        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1))
        advanceTimeBy(2_100)

        assertEquals(ResultPhase.ANSWER, component.state.value.phase)
        assertEquals(2, scanRepository.recognizeCalls, "the second call is the automatic retry")
    }

    @Test
    fun aRejectedFrameIsAFailureWithoutRetry() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Failed(
            ScanFailure(ScanFailureKind.BAD_ROI, statusCode = 422, retryable = false, retryAfterSeconds = null)
        )

        val component = createComponent(ScanTarget.NewScan("photo.jpg"))

        assertEquals(ResultPhase.FAILED, component.state.value.phase)
        assertEquals(ScanFailureKind.BAD_ROI, component.state.value.failure?.kind)
        assertNull(component.state.value.historyId)
    }

    @Test
    fun aStoredScanIsShownWithoutARequest() = runTest {
        val id = historyRepository.seed(photoPath = "stored.jpg", view = viewWith(bottles = 1))

        val component = createComponent(ScanTarget.Stored(id))

        assertEquals(ResultPhase.ANSWER, component.state.value.phase)
        assertTrue(component.state.value.isStored)
        assertEquals(0, scanRepository.recognizeCalls)
    }

    @Test
    fun aBottleJoinsTheComparisonOnceAndTheSetFillsUpAtTheCap() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1))
        val component = createComponent(ScanTarget.NewScan("photo.jpg"))

        component.onAddToCompareClicked("b1")
        assertEquals(ScanResultToast.AddedToCompare, component.state.value.toast)
        assertTrue(component.state.value.isInCompare(WineCard(slug = "slug-0", title = "Wine 0")))
        assertEquals(historyRepository.saved.single().id, compareRepository.current.single().scanId)

        component.onAddToCompareClicked("b1")
        assertEquals(ScanResultToast.AlreadyInCompare, component.state.value.toast)

        compareRepository.seed(WineCard(slug = "x", title = "X"))
        compareRepository.seed(WineCard(slug = "y", title = "Y"))
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2))
        val another = createComponent(ScanTarget.NewScan("other.jpg"))
        another.onAddToCompareClicked("b2")
        assertEquals(ScanResultToast.CompareFull, another.state.value.toast)
        assertEquals(3, another.state.value.compareCount)
    }

    @Test
    fun pickForADishAddsTheWineSilentlyAndOpensTheDishScreen() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1))
        var opened = 0
        val component = createComponent(ScanTarget.NewScan("photo.jpg"), onOpenPairing = { opened++ })

        component.onPairDishClicked("b1")
        component.onPairDishClicked("b1")

        assertEquals(listOf("slug-0"), compareRepository.current.map { it.slug })
        assertEquals(2, opened)
        assertNull(component.state.value.toast, "no «added» nor «already in the comparison» waits on the way back")
    }

    @Test
    fun pickForADishOverAFullSetStillOpensTheDishScreenWithoutAToast() = runTest {
        listOf("x", "y", "z").forEach { compareRepository.seed(WineCard(slug = it, title = it)) }
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1))
        var opened = 0
        val component = createComponent(ScanTarget.NewScan("photo.jpg"), onOpenPairing = { opened++ })

        component.onPairDishClicked("b1")

        assertEquals(1, opened, "a full set is still a set to choose from")
        assertNull(component.state.value.toast)
    }

    @Test
    fun pickForADishTellsAFailedWriteAndStaysHere() = runTest {
        compareRepository.failOnWrite = true
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1))
        var opened = 0
        val component = createComponent(ScanTarget.NewScan("photo.jpg"), onOpenPairing = { opened++ })

        component.onPairDishClicked("b1")

        assertEquals(ScanResultToast.AddToCompareFailed, component.state.value.toast)
        assertEquals(0, opened)
    }

    @Test
    fun theSameButtonRemovesTheWineAgain() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1))
        val component = createComponent(ScanTarget.NewScan("photo.jpg"))
        component.onAddToCompareClicked("b1")

        component.onRemoveFromCompareClicked("b1")

        assertTrue(compareRepository.current.isEmpty())
        assertEquals(ScanResultToast.RemovedFromCompare, component.state.value.toast)
    }

    @Test
    fun thePillAddsTheWineOnScreenWhenThereIsSomethingToCompareItWith() = runTest {
        compareRepository.seed(WineCard(slug = "other", title = "Other"))
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1))
        var opened = 0
        val component = createComponent(ScanTarget.NewScan("photo.jpg"), onOpenCompare = { opened++ })

        component.onCompareWinesClicked()

        assertEquals(listOf("other", "slug-0"), compareRepository.current.map { it.slug })
        assertEquals(1, opened)
    }

    @Test
    fun thePillDoesNotAddOverTheCap() = runTest {
        compareRepository.seed(WineCard(slug = "x", title = "X"))
        compareRepository.seed(WineCard(slug = "y", title = "Y"))
        compareRepository.seed(WineCard(slug = "z", title = "Z"))
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1))
        val component = createComponent(ScanTarget.NewScan("photo.jpg"))

        component.onCompareWinesClicked()

        assertEquals(3, compareRepository.current.size)
    }

    @Test
    fun anAlternativeOpensTheWineScreenWithThatBottlesPhoto() = runTest {
        val alternative = WineCard(slug = "alt", title = "Alternative")
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2))
        val opened = mutableListOf<WineDetailTarget>()
        val component = createComponent(ScanTarget.NewScan("photo.jpg"), onOpenWineDetail = { opened += it })

        component.onAlternativeClicked("b2", alternative)

        val target = opened.single()
        assertEquals(alternative, target.card)
        assertEquals(2, target.bottle?.bottleNumber)
        assertEquals(component.state.value.photoPath, target.bottle?.photoPath)
        assertEquals(historyRepository.saved.single().id, target.bottle?.scanId)
        assertEquals(listOf(1000, 1000), target.bottle?.frame)
        assertNull(component.modalSlot.value.child, "an alternative no longer opens the photo comparison")
    }

    @Test
    fun moreOffersAFrameThatOpensTheFrameScreen() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2))
        val component = createComponent(ScanTarget.NewScan("photo.jpg"))

        component.onMoreClicked()
        val more = assertIs<ScanResultComponent.Modal.More>(component.modalSlot.value.child?.instance).component
        assertTrue(more.canDrawFrame)

        more.onDrawFrameClicked()

        val drawFrame = assertIs<ScanResultComponent.Modal.DrawFrame>(
            component.modalSlot.value.child?.instance,
            "the frame screen takes the place of «More»",
        ).component
        assertEquals(component.state.value.photoPath, drawFrame.photoPath)
        assertEquals(listOf(1000, 1000), drawFrame.frame)
        assertEquals(2, drawFrame.view?.bottles?.size, "the answer's boxes are there for orientation")
    }

    @Test
    fun moreHidesTheFrameWhileThePhotoFrameIsUnknown() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1, frameSize = null))
        val component = createComponent(ScanTarget.NewScan("photo.jpg"))

        component.onMoreClicked()
        val more = assertIs<ScanResultComponent.Modal.More>(component.modalSlot.value.child?.instance).component
        more.onDrawFrameClicked()

        assertFalse(more.canDrawFrame)
        assertIs<ScanResultComponent.Modal.More>(
            component.modalSlot.value.child?.instance,
            "without the frame size a drawn box could not be clamped, so the frame screen stays shut",
        )
    }

    @Test
    fun scanOnTheFrameScreenOpensANewResultForTheClampedFrame() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2))
        val opened = mutableListOf<ScanTarget.Framed>()
        val component = createComponent(ScanTarget.NewScan("photo.jpg"), onOpenFramedResult = { opened += it })
        component.onMoreClicked()
        assertIs<ScanResultComponent.Modal.More>(component.modalSlot.value.child?.instance).component
            .onDrawFrameClicked()
        val drawFrame = assertIs<ScanResultComponent.Modal.DrawFrame>(component.modalSlot.value.child?.instance)
            .component

        drawFrame.onScanClicked()
        assertTrue(opened.isEmpty(), "nothing is drawn yet, so there is nothing to scan")

        drawFrame.onDraftChanged(BottleBox(x1 = -50.0, y1 = 100.0, x2 = 1200.0, y2 = 900.0))
        drawFrame.onScanClicked()

        val target = opened.single()
        assertEquals(component.state.value.photoPath, target.photoPath)
        assertEquals(BottleBox(x1 = 0.0, y1 = 100.0, x2 = 1000.0, y2 = 900.0), target.roi)
        assertNull(component.modalSlot.value.child)
        assertEquals(1, scanRepository.recognizeCalls, "the frame is recognised on the new screen, not here")
        assertEquals(2, component.state.value.view?.bottles?.size)
    }

    @Test
    fun theOutgoingMoreSheetDoesNotCloseTheFrameScreenThatReplacedIt() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2))
        val component = createComponent(ScanTarget.NewScan("photo.jpg"))
        component.onMoreClicked()
        assertIs<ScanResultComponent.Modal.More>(component.modalSlot.value.child?.instance).component
            .onDrawFrameClicked()

        component.onModalDismissed()

        val drawFrame = assertIs<ScanResultComponent.Modal.DrawFrame>(component.modalSlot.value.child?.instance)
        drawFrame.component.onCancelClicked()
        assertNull(component.modalSlot.value.child, "the frame screen closes with its own ✕")
    }

    @Test
    fun aSecondScanTapOnTheFrameScreenOpensOneResult() = runTest {
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 2))
        val opened = mutableListOf<ScanTarget.Framed>()
        val component = createComponent(ScanTarget.NewScan("photo.jpg"), onOpenFramedResult = { opened += it })
        component.onMoreClicked()
        assertIs<ScanResultComponent.Modal.More>(component.modalSlot.value.child?.instance).component
            .onDrawFrameClicked()
        val drawFrame = assertIs<ScanResultComponent.Modal.DrawFrame>(component.modalSlot.value.child?.instance)
            .component

        drawFrame.onDraftChanged(BottleBox(x1 = 2000.0, y1 = 100.0, x2 = 3000.0, y2 = 900.0))
        assertNull(drawFrame.state.value.draft, "a frame with nothing left inside the photo is not a draft")
        drawFrame.onDraftChanged(BottleBox(x1 = 100.0, y1 = 100.0, x2 = 400.0, y2 = 900.0))
        drawFrame.onScanClicked()
        drawFrame.onScanClicked()

        assertEquals(1, opened.size)
    }

    @Test
    fun aFramedResultAsksForItsFrameAndIsNeverStored() = runTest {
        val roi = BottleBox(x1 = 10.0, y1 = 20.0, x2 = 300.0, y2 = 900.0)
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1, mode = ScanMode.EXPLICIT_ROI))

        val component = createComponent(ScanTarget.Framed(photoPath = "photo.jpg", roi = roi))

        val state = component.state.value
        assertEquals(roi, scanRepository.lastRoi)
        assertEquals("photo.jpg", scanRepository.lastPhotoPath)
        assertEquals(ResultPhase.ANSWER, state.phase)
        assertTrue(state.isFramed)
        assertTrue(historyRepository.saved.isEmpty(), "a drawn frame's answer stays out of the history")
        assertNull(state.historyId)
    }

    @Test
    fun aFramedResultRetriesWithItsFrameAndStillStoresNothing() = runTest {
        val roi = BottleBox(x1 = 10.0, y1 = 20.0, x2 = 300.0, y2 = 900.0)
        scanRepository.nextOutcome = ScanOutcome.Failed(
            ScanFailure(ScanFailureKind.OFFLINE, statusCode = null, retryable = true, retryAfterSeconds = null)
        )
        val component = createComponent(ScanTarget.Framed(photoPath = "photo.jpg", roi = roi))
        assertEquals(ResultPhase.FAILED, component.state.value.phase)
        scanRepository.nextOutcome = ScanOutcome.Recognized(viewWith(bottles = 1, mode = ScanMode.EXPLICIT_ROI))

        component.onRetryClicked()

        assertEquals(2, scanRepository.recognizeCalls)
        assertEquals(roi, scanRepository.lastRoi, "a retry asks for the same frame, not for all bottles")
        assertTrue(historyRepository.saved.isEmpty())
    }

    private fun kotlinx.coroutines.test.TestScope.createComponent(
        target: ScanTarget,
        onOpenCompare: () -> Unit = {},
        onOpenPairing: () -> Unit = {},
        onOpenWineDetail: (WineDetailTarget) -> Unit = {},
        onOpenFramedResult: (ScanTarget.Framed) -> Unit = {},
    ): DefaultScanResultComponent =
        DefaultScanResultComponent(
            componentContext = TestComponentContext().componentContext,
            target = target,
            scanRepository = scanRepository,
            historyRepository = historyRepository,
            compareRepository = compareRepository,
            gastronomyRepository = gastronomyRepository,
            appLanguage = FakeAppLanguageRepository(),
            platformShare = platformShare,
            platformLinks = FakePlatformLinks(),
            analytics = analytics,
            sheetFactories = sheetFactories,
            json = json,
            onClose = {},
            onNewScan = {},
            onOpenCompare = onOpenCompare,
            onOpenPairing = onOpenPairing,
            onOpenWineDetail = onOpenWineDetail,
            onOpenFramedResult = onOpenFramedResult,
            mainContext = UnconfinedTestDispatcher(testScheduler),
        )

    private val sheetFactories = ScanResultSheetFactories(
        drawFrame = DrawFrameComponent.Factory { ctx, photoPath, frame, view, onFrameDrawn, onCancel ->
            DefaultDrawFrameComponent(ctx, photoPath, frame, view, onFrameDrawn, onCancel)
        },
        compare = CompareComponent.Factory { ctx, photoPath, crop, frame, number, title, reference, access, onClose ->
            DefaultCompareComponent(ctx, photoPath, crop, frame, number, title, reference, access, onClose)
        },
        more = MoreComponent.Factory {
                ctx, isRoi, number, canRescan, canDraw, onRescan, onDraw, onShareFull, onShareBottle, onTech ->
            DefaultMoreComponent(
                ctx, isRoi, number, canRescan, canDraw, onRescan, onDraw, onShareFull, onShareBottle, onTech,
            )
        },
        techDetails = TechDetailsComponent.Factory { ctx, rows, onClose -> DefaultTechDetailsComponent(ctx, rows, onClose) },
    )

    private fun viewWith(
        bottles: Int,
        mode: ScanMode = ScanMode.AUTOMATIC,
        frameSize: List<Int>? = listOf(1000, 1000),
        decisions: List<String> = List(bottles) { "uncertain" },
        selectRois: List<JsonElement?> = List(bottles) { Json.parseToJsonElement("[0,0,100,100]") },
        primaryInstanceId: String? = null,
    ) = RecognitionView(
        decision = "uncertain",
        mode = mode.apiName,
        bottleCount = bottles,
        primaryInstanceId = primaryInstanceId,
        frameSize = frameSize,
        bottles = List(bottles) { index ->
            RecognizedBottle(
                number = index + 1,
                instanceId = "b${index + 1}",
                selectRoi = selectRois[index],
                decision = decisions[index],
                best = WineCard(slug = "slug-$index", title = "Wine $index"),
            )
        },
    )
}
