package com.aiweapps.winescan.components.wine.detail

import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.components.common.model.WineFacts
import com.aiweapps.winescan.components.scan.result.sheets.CompareComponent
import com.aiweapps.winescan.components.scan.result.sheets.DefaultCompareComponent
import com.aiweapps.winescan.components.wine.detail.model.WineDetailToast
import com.aiweapps.winescan.domain.gastronomy.model.ServingTemperature
import com.aiweapps.winescan.domain.gastronomy.model.WineColor
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.BottlePhoto
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.domain.scan.model.WineDetailTarget
import com.aiweapps.winescan.testutil.FakeAppLanguageRepository
import com.aiweapps.winescan.testutil.FakeGastronomyRepository
import com.aiweapps.winescan.testutil.FakeCompareSetRepository
import com.aiweapps.winescan.testutil.FakeAnalyticsTracker
import com.aiweapps.winescan.testutil.FakePlatformLinks
import com.aiweapps.winescan.testutil.FakeScanRepository
import com.aiweapps.winescan.testutil.TestComponentContext
import com.aiweapps.winescan.testutil.TestDishes
import com.aiweapps.winescan.testutil.gastronomy
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class DefaultWineDetailComponentTest {

    private val compareRepository = FakeCompareSetRepository()
    private val gastronomyRepository = FakeGastronomyRepository()
    private val platformLinks = FakePlatformLinks()
    private val card = WineCard(slug = "alt", title = "Alternative", reference = "/api/reference/alt.jpg")
    private val bottle = BottlePhoto(
        photoPath = "photo.jpg",
        crop = BottleBox(10.0, 20.0, 110.0, 420.0),
        frame = listOf(1000, 1000),
        bottleNumber = 2,
        scanId = 7L,
    )

    @Test
    fun theReferenceResolvesOnceTheSessionIsOpen() = runTest {
        val component = createComponent()

        assertEquals("https://example.test/api/reference/alt.jpg", component.state.value.referenceUrl)
    }

    @Test
    fun compareWithPhotoOpensTheUsersBottleAgainstThisWine() = runTest {
        val component = createComponent()

        component.onCompareWithPhotoClicked()

        val compare = assertIs<WineDetailComponent.Modal.Compare>(component.modalSlot.value.child?.instance).component
        assertEquals("photo.jpg", compare.photoPath)
        assertEquals(bottle.crop, compare.crop)
        assertEquals(2, compare.bottleNumber)
        assertEquals("Alternative", compare.cardTitle)
        assertEquals("https://example.test/api/reference/alt.jpg", compare.referenceUrl)

        compare.onCloseClicked()

        assertNull(component.modalSlot.value.child)
    }

    @Test
    fun withoutABottlePhotoThereIsNothingToCompareOrAdd() = runTest {
        val component = createComponent(bottle = null)

        component.onCompareWithPhotoClicked()
        component.onAddToCompareClicked()

        assertFalse(component.state.value.canCompareWithPhoto)
        assertNull(component.modalSlot.value.child)
        assertTrue(compareRepository.current.isEmpty())
    }

    @Test
    fun addingPutsThisWineInTheSetWithTheUsersPhoto() = runTest {
        val component = createComponent()

        component.onAddToCompareClicked()

        val entry = compareRepository.current.single()
        assertEquals("alt", entry.slug)
        assertEquals("photo.jpg", entry.photoPath)
        assertEquals(bottle.crop, entry.crop)
        assertEquals(7L, entry.scanId)
        assertTrue(component.state.value.isInCompare)
        assertEquals(WineDetailToast.AddedToCompare, component.state.value.toast)
    }

    @Test
    fun removingTakesTheWineOutAgain() = runTest {
        val component = createComponent()
        component.onAddToCompareClicked()

        component.onRemoveFromCompareClicked()

        assertTrue(compareRepository.current.isEmpty())
        assertFalse(component.state.value.isInCompare)
        assertEquals(WineDetailToast.RemovedFromCompare, component.state.value.toast)
    }

    @Test
    fun aFullSetIsReportedAndNotOverfilled() = runTest {
        compareRepository.seed(WineCard(slug = "x", title = "X"))
        compareRepository.seed(WineCard(slug = "y", title = "Y"))
        compareRepository.seed(WineCard(slug = "z", title = "Z"))
        val component = createComponent()

        assertTrue(component.state.value.isCompareFull)

        component.onAddToCompareClicked()

        assertEquals(3, compareRepository.current.size)
        assertEquals(WineDetailToast.CompareFull, component.state.value.toast)
    }

    @Test
    fun aFailedWriteIsReportedAndLeavesTheSetAsItWas() = runTest {
        compareRepository.failOnWrite = true
        val component = createComponent()

        component.onAddToCompareClicked()

        assertTrue(compareRepository.current.isEmpty())
        assertEquals(WineDetailToast.AddToCompareFailed, component.state.value.toast)
    }

    @Test
    fun backClosesTheScreen() = runTest {
        var closed = 0
        val component = createComponent(onClose = { closed++ })

        component.onBackClicked()

        assertEquals(1, closed)
    }

    @Test
    fun theFactsLoadBesideTheCardAndAMissingWineIsNoData() = runTest {
        gastronomyRepository.seed(gastronomy("alt", pairings = listOf(TestDishes.MEAT)))

        val facts = assertNotNull(createComponent().state.value.facts)

        assertEquals(WineColor.RED, facts.color)
        assertEquals(listOf("Красное мясо"), facts.pairings?.map { it.label })
        assertEquals(ServingTemperature(16, 18), facts.servingTemperature)
    }

    @Test
    fun aWineTheCatalogueDoesNotKnowIsNoDataNotAnError() = runTest {
        gastronomyRepository.failGastronomy = true

        val state = createComponent().state.value

        assertEquals(WineFacts.NO_DATA, state.facts)
        assertIs<ScreenState.Content>(state.screenState)
    }

    @Test
    fun theCatalogueLinkOpensOnThePlatform() = runTest {
        val component = createComponent()

        component.onCatalogueLinkClicked("https://vinosvoe.ru/wines/alt")

        assertEquals(listOf("https://vinosvoe.ru/wines/alt"), platformLinks.openedUrls)
    }

    private fun TestScope.createComponent(
        bottle: BottlePhoto? = this@DefaultWineDetailComponentTest.bottle,
        onClose: () -> Unit = {},
    ): DefaultWineDetailComponent =
        DefaultWineDetailComponent(
            componentContext = TestComponentContext().componentContext,
            target = WineDetailTarget(card = card, bottle = bottle),
            scanRepository = FakeScanRepository(),
            compareRepository = compareRepository,
            gastronomyRepository = gastronomyRepository,
            appLanguage = FakeAppLanguageRepository(),
            platformLinks = platformLinks,
            analytics = FakeAnalyticsTracker(),
            compareFactory = CompareComponent.Factory {
                    ctx, photoPath, crop, frame, number, title, reference, access, close ->
                DefaultCompareComponent(ctx, photoPath, crop, frame, number, title, reference, access, close)
            },
            onClose = onClose,
            mainContext = UnconfinedTestDispatcher(testScheduler),
        )
}
