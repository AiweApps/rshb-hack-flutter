package com.aiweapps.winescan.components.scan.home

import com.aiweapps.winescan.components.common.DefaultServiceDetailComponent
import com.aiweapps.winescan.components.common.ServiceDetailComponent
import com.aiweapps.winescan.components.scan.home.model.ShutterMood
import com.aiweapps.winescan.components.scan.home.model.StatusHint
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.config.AnalyticsValues
import com.aiweapps.winescan.config.TimingConstants
import com.aiweapps.winescan.domain.scan.model.CameraAvailability
import com.aiweapps.winescan.domain.scan.model.ServiceAvailability
import com.aiweapps.winescan.testutil.FakeAnalyticsTracker
import com.aiweapps.winescan.testutil.FakePlatformLinks
import com.aiweapps.winescan.testutil.FakeScanHistoryRepository
import com.aiweapps.winescan.testutil.FakeServiceStatusMonitor
import com.aiweapps.winescan.testutil.TestComponentContext
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class DefaultScanHomeComponentTest {

    private val monitor = FakeServiceStatusMonitor()
    private val analytics = FakeAnalyticsTracker()

    @Test
    fun photosAreLoggedBySourceAndADismissedPickerIsNot() = runTest {
        val component = createComponent()

        component.onPhotoCaptured("shot.jpg")
        component.onPickPhotoClicked()
        component.onPhotoPicked(null)
        component.onPickPhotoClicked()
        component.onPhotoPicked("picked.jpg")

        assertEquals(
            listOf(AnalyticsValues.SOURCE_CAMERA, AnalyticsValues.SOURCE_GALLERY),
            analytics.eventsNamed(AnalyticsEvents.PHOTO_TAKEN).map { it[AnalyticsParams.SOURCE] },
            "a closed picker is not a photo, so it must not inflate the funnel",
        )
    }

    @Test
    fun aReadyServiceKeepsTheAimHintAndAFullBottle() = runTest {
        val component = createComponent()

        assertEquals(ShutterMood.READY, component.state.value.shutterMood)
        assertEquals(StatusHint.AIM, component.state.value.statusHint)
        assertTrue(component.state.value.isHintShown)
    }

    @Test
    fun aProblemShowsItselfAndFoldsAwayAfterAWhile() = runTest {
        val component = createComponent()

        monitor.emit(ServiceAvailability.DOWN)
        assertEquals(StatusHint.STATUS, component.state.value.statusHint)
        assertEquals(ShutterMood.BLOCKED, component.state.value.shutterMood)

        advanceTimeBy(TimingConstants.STATUS_HINT_VISIBLE_MS + 1)
        assertEquals(StatusHint.AIM, component.state.value.statusHint)
        assertEquals(ShutterMood.BLOCKED, component.state.value.shutterMood, "the shutter keeps telling")
        assertFalse(component.state.value.isHintShown, "«point at the label» is only for a ready service")
    }

    @Test
    fun aShotWhileConnectingIsTakenAndBringsTheStatusBack() = runTest {
        val component = createComponent()
        monitor.emit(ServiceAvailability.CHECKING)
        advanceTimeBy(TimingConstants.STATUS_HINT_VISIBLE_MS + 1)

        component.onShutterClicked()

        assertTrue(component.state.value.isCapturing)
        assertEquals(StatusHint.STATUS, component.state.value.statusHint)
    }

    @Test
    fun theGalleryOpensWhileTheServiceCanAnswer() = runTest {
        val component = createComponent(CameraAvailability.UNAVAILABLE)

        component.onPickPhotoClicked()

        assertTrue(component.state.value.isPicking)
    }

    @Test
    fun theGalleryWithoutACameraShowsTheStatusDetailsInstead() = runTest {
        val component = createComponent(CameraAvailability.UNAVAILABLE)
        monitor.emit(ServiceAvailability.DOWN)

        component.onPickPhotoClicked()

        assertFalse(component.state.value.isPicking)
        assertNotNull(component.modalSlot.value.child)
    }

    @Test
    fun theGalleryUnderTheViewfinderIsRefusedLikeTheShutter() = runTest {
        val component = createComponent()
        monitor.emit(ServiceAvailability.OFFLINE)
        advanceTimeBy(TimingConstants.STATUS_HINT_VISIBLE_MS + 1)

        component.onPickPhotoClicked()

        assertFalse(component.state.value.isPicking)
        assertEquals(1, component.state.value.refusedShotTicket)
        assertEquals(StatusHint.STATUS, component.state.value.statusHint)
    }

    @Test
    fun aRefusedShotShakesAndBringsTheStatusBackWithoutShooting() = runTest {
        val component = createComponent()
        monitor.emit(ServiceAvailability.OFFLINE)
        advanceTimeBy(TimingConstants.STATUS_HINT_VISIBLE_MS + 1)

        component.onShutterClicked()

        assertFalse(component.state.value.isCapturing)
        assertEquals(1, component.state.value.refusedShotTicket)
        assertEquals(StatusHint.STATUS, component.state.value.statusHint)
    }

    @Test
    fun aBusyServiceShootsAndSaysThePhotoIsQueued() = runTest {
        val component = createComponent()
        monitor.emit(ServiceAvailability.BUSY, waiting = 2)
        advanceTimeBy(TimingConstants.STATUS_HINT_VISIBLE_MS + 1)

        component.onShutterClicked()

        assertTrue(component.state.value.isCapturing)
        assertEquals(StatusHint.QUEUED, component.state.value.statusHint)
        assertEquals(2, component.state.value.queueAhead)
    }

    @Test
    fun theHintOpensTheDetailsWhileItShowsTheStatus() = runTest {
        val component = createComponent()
        monitor.emit(ServiceAvailability.DOWN)

        component.onStatusHintClicked()

        assertNotNull(component.modalSlot.value.child)
        assertEquals(1, monitor.refreshCalls)
    }

    @Test
    fun theServiceComingBackFoldsTheStatusAtOnce() = runTest {
        val component = createComponent()
        monitor.emit(ServiceAvailability.DOWN)

        monitor.emit(ServiceAvailability.READY)

        assertEquals(StatusHint.AIM, component.state.value.statusHint)
    }

    private fun TestScope.createComponent(
        camera: CameraAvailability = CameraAvailability.READY,
    ): DefaultScanHomeComponent {
        val component = DefaultScanHomeComponent(
            componentContext = TestComponentContext().componentContext,
            statusMonitor = monitor,
            historyRepository = FakeScanHistoryRepository(),
            platformLinks = FakePlatformLinks(),
            analytics = analytics,
            serviceDetailFactory = ServiceDetailComponent.Factory { ctx, availability, onClose ->
                DefaultServiceDetailComponent(ctx, availability, onClose)
            },
            onOpenResult = {},
            onOpenHistory = {},
            mainContext = UnconfinedTestDispatcher(testScheduler),
        )
        component.onCameraAvailabilityReported(camera)
        return component
    }
}
