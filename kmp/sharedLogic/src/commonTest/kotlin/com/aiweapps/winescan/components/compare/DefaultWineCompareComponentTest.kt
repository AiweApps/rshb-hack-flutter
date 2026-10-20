package com.aiweapps.winescan.components.compare

import com.aiweapps.winescan.components.compare.model.WineCompareToast
import com.aiweapps.winescan.components.compare.picker.DefaultHistoryPickerComponent
import com.aiweapps.winescan.components.compare.picker.HistoryPickerComponent
import com.aiweapps.winescan.domain.compare.model.CompareAttribute
import com.aiweapps.winescan.domain.compare.model.CompareValue
import com.aiweapps.winescan.domain.gastronomy.model.WineColor
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.RecognizedBottle
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.testutil.FakeAppLanguageRepository
import com.aiweapps.winescan.testutil.FakeGastronomyRepository
import com.aiweapps.winescan.testutil.FakeCompareSetRepository
import com.aiweapps.winescan.testutil.FakeAnalyticsTracker
import com.aiweapps.winescan.testutil.FakePlatformLinks
import com.aiweapps.winescan.testutil.FakeScanHistoryRepository
import com.aiweapps.winescan.testutil.FakeScanRepository
import com.aiweapps.winescan.testutil.FakeWineCatalogRepository
import com.aiweapps.winescan.testutil.TestComponentContext
import com.aiweapps.winescan.testutil.gastronomy
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class DefaultWineCompareComponentTest {

    private val compareRepository = FakeCompareSetRepository()
    private val gastronomyRepository = FakeGastronomyRepository()
    private val historyRepository = FakeScanHistoryRepository()
    private val catalog = FakeWineCatalogRepository()
    private val plannedDinners = mutableListOf<Pair<List<String>, String>>()
    private var pairingOpened = 0

    @Test
    fun aPickFromTheHistoryAddsTheScansBestCardAndClosesThePicker() = runTest {
        val id = historyRepository.seed("photo.jpg", viewWith(WineCard(slug = "tamara", title = "Tamara", category = "Белое")))
        val component = createComponent()

        component.onPickFromHistoryClicked()
        val picker = assertIs<WineCompareComponent.Modal.HistoryPicker>(component.modalSlot.value.child?.instance)
        assertEquals(listOf(id), picker.component.state.value.items.map { it.id })

        picker.component.onScanClicked(id)

        assertNull(component.modalSlot.value.child, "the sheet closes on a pick")
        assertEquals(listOf("tamara"), component.state.value.entries.map { it.slug })
        assertEquals(WineCompareToast.ADDED, component.state.value.toast)
        assertTrue(component.state.value.needsSecondWine)
    }

    @Test
    fun aFailedGastronomyLoadLeavesNoDataCellsNotAnError() = runTest {
        gastronomyRepository.failGastronomy = true
        compareRepository.seed(WineCard(slug = "a", title = "A", region = "Кубань"))

        val rows = createComponent().state.value.allRows.associateBy { it.attribute }

        assertEquals(CompareValue.None, rows.getValue(CompareAttribute.COLOR).values.single())
        assertEquals(CompareValue.Text("Кубань"), rows.getValue(CompareAttribute.REGION).values.single())
    }

    @Test
    fun theTableFollowsTheSetAndSplitsRowsByDifference() = runTest {
        compareRepository.seed(WineCard(slug = "a", title = "A", category = "Белое сухое", region = "Кубань", grapes = "Купаж"))
        compareRepository.seed(WineCard(slug = "b", title = "B", category = "Красное сухое", region = "Кубань", grapes = "Купаж"))
        gastronomyRepository.seed(gastronomy("a", color = WineColor.WHITE), gastronomy("b", color = WineColor.RED))
        catalog.seed(WineCard(slug = "a", title = "A", alcohol = 12.5), WineCard(slug = "b", title = "B", alcohol = 12.5))
        val component = createComponent()

        assertEquals(listOf(CompareAttribute.COLOR), component.state.value.differentRows.map { it.attribute })
        assertEquals(CompareAttribute.entries, component.state.value.allRows.map { it.attribute }, "«All» keeps table order")
        assertTrue(component.state.value.sameRows.any { it.attribute == CompareAttribute.REGION })

        component.onRemoveClicked("b")

        assertTrue(component.state.value.differentRows.isEmpty(), "one wine disagrees with nobody")
        assertTrue(component.state.value.canAddMore)
    }

    @Test
    fun theCatalogueFillsTheDescriptionWithoutTouchingTheStoredCard() = runTest {
        compareRepository.seed(WineCard(slug = "a", title = "A"))
        catalog.seed(WineCard(slug = "a", title = "A", description = "Яркий аромат черных ягод"))

        val component = createComponent()

        assertEquals("Яркий аромат черных ягод", component.state.value.entries.single().card.description)
        assertNull(compareRepository.watch().first().single().card.description, "the set keeps the card as it was added")
    }

    @Test
    fun planDinnerHandsTheSetToTheAssistant() = runTest {
        compareRepository.seed(WineCard(slug = "a", title = "A"))
        compareRepository.seed(WineCard(slug = "b", title = "B"))
        val component = createComponent()

        component.onPlanDinnerClicked("Ужин на четверых")

        assertEquals(listOf(listOf("a", "b") to "Ужин на четверых"), plannedDinners)
    }

    @Test
    fun compareForADishOpensTheDishScreenOnlyWithWinesInTheSet() = runTest {
        val empty = createComponent()
        empty.onPairDishClicked()
        assertEquals(0, pairingOpened)

        compareRepository.seed(WineCard(slug = "a", title = "A"))
        val component = createComponent()
        component.onPairDishClicked()

        assertEquals(1, pairingOpened)
    }

    private fun TestScope.createComponent() = DefaultWineCompareComponent(
        componentContext = TestComponentContext().componentContext,
        compareRepository = compareRepository,
        catalog = catalog,
        historyRepository = historyRepository,
        scanRepository = FakeScanRepository(),
        gastronomyRepository = gastronomyRepository,
        appLanguage = FakeAppLanguageRepository(),
        platformLinks = FakePlatformLinks(),
        analytics = FakeAnalyticsTracker(),
        pickerFactory = HistoryPickerComponent.Factory { ctx, onPick, onClose ->
            DefaultHistoryPickerComponent(
                componentContext = ctx,
                historyRepository = historyRepository,
                compareRepository = compareRepository,
                onPick = onPick,
                onClose = onClose,
                mainContext = UnconfinedTestDispatcher(testScheduler),
            )
        },
        onOpenScanner = {},
        onOpenPairing = { pairingOpened++ },
        onPlanDinner = { wines, prompt -> plannedDinners += wines.map { it.slug } to prompt },
        mainContext = UnconfinedTestDispatcher(testScheduler),
    )

    private fun viewWith(card: WineCard) = RecognitionView(
        decision = "uncertain",
        bottleCount = 1,
        frameSize = listOf(1000, 1000),
        bottles = listOf(RecognizedBottle(number = 1, instanceId = "b1", best = card)),
    )
}
