package com.aiweapps.winescan.components.onboarding

import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.config.AnalyticsParams
import com.aiweapps.winescan.config.AnalyticsValues
import com.aiweapps.winescan.testutil.FakeAnalyticsTracker
import com.aiweapps.winescan.testutil.FakeAppPreferencesRepository
import com.aiweapps.winescan.testutil.TestComponentContext
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain

@OptIn(ExperimentalCoroutinesApi::class)
class DefaultOnboardingComponentTest {

    private val preferences = FakeAppPreferencesRepository()
    private val analytics = FakeAnalyticsTracker()
    private var finishedCount = 0

    // The component takes the default main dispatcher, which the JVM test host does not have.
    @BeforeTest
    fun setUp() {
        Dispatchers.setMain(UnconfinedTestDispatcher())
    }

    @AfterTest
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun nextWalksEveryPageEvenWhenThePagerNeverReportsBack() {
        val component = createComponent()

        repeat(component.state.value.pageCount - 1) { component.onNextClicked() }

        val state = component.state.value
        assertEquals(state.pageCount - 1, state.pageIndex)
        assertEquals(state.pageIndex, state.targetPage)
        assertEquals(0, finishedCount, "the last page is shown before the app starts")
    }

    @Test
    fun nextOnTheLastPageFinishesOnceAndLogsCompleted() {
        val component = createComponent()
        repeat(component.state.value.pageCount - 1) { component.onNextClicked() }

        component.onNextClicked()
        component.onNextClicked()

        assertEquals(1, finishedCount)
        assertTrue(preferences.isOnboardingDone)
        val event = analytics.eventsNamed(AnalyticsEvents.ONBOARDING_FINISHED).single()
        assertEquals(AnalyticsValues.RESULT_COMPLETED, event[AnalyticsParams.RESULT])
        assertFalse(AnalyticsParams.SKIPPED_FROM in event)
    }

    @Test
    fun skipFinishesAndLogsThePageItWasTappedOn() {
        val component = createComponent()
        component.onPageChanged(1)

        component.onSkipClicked()

        assertEquals(1, finishedCount)
        val event = analytics.eventsNamed(AnalyticsEvents.ONBOARDING_FINISHED).single()
        assertEquals(AnalyticsValues.RESULT_SKIPPED, event[AnalyticsParams.RESULT])
        assertEquals("1", event[AnalyticsParams.SKIPPED_FROM])
    }

    @Test
    fun aSwipeOutOfRangeIsClamped() {
        val component = createComponent()

        component.onPageChanged(99)

        assertEquals(component.state.value.pageCount - 1, component.state.value.pageIndex)
    }

    private fun createComponent() = DefaultOnboardingComponent(
        componentContext = TestComponentContext().componentContext,
        preferences = preferences,
        analytics = analytics,
        onFinished = { finishedCount++ },
    )
}
