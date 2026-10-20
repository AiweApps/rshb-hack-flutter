package com.aiweapps.winescan.components.history

import com.aiweapps.winescan.components.common.DefaultConfirmClearHistoryComponent
import com.aiweapps.winescan.components.common.ConfirmClearHistoryComponent
import com.aiweapps.winescan.components.history.model.HistoryToast
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.RecognizedBottle
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.testutil.FakeAppLanguageRepository
import com.aiweapps.winescan.testutil.FakeAssistantLocalRepository
import com.aiweapps.winescan.testutil.FakeCompareSetRepository
import com.aiweapps.winescan.testutil.FakeSavedPairingRepository
import com.aiweapps.winescan.testutil.FakeScanHistoryRepository
import com.aiweapps.winescan.testutil.TestComponentContext
import com.aiweapps.winescan.testutil.savedWine
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class DefaultHistoryComponentTest {

    private val historyRepository = FakeScanHistoryRepository()
    private val compareRepository = FakeCompareSetRepository()
    private val favorites = FakeAssistantLocalRepository()
    private val openedScans = mutableListOf<Long>()

    @Test
    fun theCompareButtonAddsTheScansWineAndATapMoreTakesItOut() = runTest {
        val id = historyRepository.seed("photo.jpg", viewWith(WineCard(slug = "tamara", title = "Tamara")))
        val component = createComponent()

        component.onCompareClicked(id)

        assertEquals(listOf("tamara"), compareRepository.current.map { it.slug })
        assertEquals(id, compareRepository.current.single().scanId)
        assertTrue(component.state.value.isInCompare(component.state.value.items.single()))
        assertEquals(HistoryToast.ADDED_TO_COMPARE, component.state.value.toast)

        component.onCompareClicked(id)

        assertTrue(compareRepository.current.isEmpty())
        assertFalse(component.state.value.isInCompare(component.state.value.items.single()))
        assertEquals(HistoryToast.REMOVED_FROM_COMPARE, component.state.value.toast)
        assertTrue(openedScans.isEmpty(), "the buttons do not open the scan")
    }

    @Test
    fun aFullComparisonSaysSoAndAFailedWriteIsAToast() = runTest {
        listOf("a", "b", "c").forEach { compareRepository.seed(WineCard(slug = it, title = it)) }
        val id = historyRepository.seed("photo.jpg", viewWith(WineCard(slug = "tamara", title = "Tamara")))
        val component = createComponent()

        component.onCompareClicked(id)
        assertEquals(HistoryToast.COMPARE_FULL, component.state.value.toast)

        compareRepository.failOnWrite = true
        component.onCompareClicked(historyRepository.seed("p2.jpg", viewWith(WineCard(slug = "a", title = "a"))))
        assertEquals(HistoryToast.REMOVE_FROM_COMPARE_FAILED, component.state.value.toast)
    }

    @Test
    fun theHeartSavesTheScansWineToMyWinesAndATapMoreTakesEveryCopyOut() = runTest {
        val id = historyRepository.seed("photo.jpg", viewWith(WineCard(slug = "tamara", title = "Tamara")))
        val component = createComponent()

        component.onFavoriteClicked(id)

        val saved = favorites.savedWines.single()
        assertEquals("tamara", saved.slug)
        assertEquals(id, saved.sourceScanId, "the saved wine shows its scan's photo")
        assertTrue(component.state.value.isFavorite(component.state.value.items.single()))
        assertEquals(HistoryToast.ADDED_TO_FAVORITES, component.state.value.toast)

        // The same wine saved from a chat card is the same heart.
        favorites.seed(savedWine("tamara"))
        component.onFavoriteClicked(id)

        assertTrue(favorites.savedWines.isEmpty())
        assertFalse(component.state.value.isFavorite(component.state.value.items.single()))
        assertEquals(HistoryToast.REMOVED_FROM_FAVORITES, component.state.value.toast)
    }

    @Test
    fun aHeartSavedInTheAssistantShowsOnTheRow() = runTest {
        historyRepository.seed("photo.jpg", viewWith(WineCard(slug = "tamara", title = "Tamara")))
        val component = createComponent()

        favorites.seed(savedWine("tamara"))

        assertTrue(component.state.value.isFavorite(component.state.value.items.single()))
    }

    @Test
    fun aFailedHeartWriteIsAToast() = runTest {
        val id = historyRepository.seed("photo.jpg", viewWith(WineCard(slug = "tamara", title = "Tamara")))
        val component = createComponent()
        favorites.failOnWrite = true

        component.onFavoriteClicked(id)

        assertTrue(favorites.savedWines.isEmpty())
        assertEquals(HistoryToast.FAVORITES_FAILED, component.state.value.toast)
    }

    private fun TestScope.createComponent() = DefaultHistoryComponent(
        componentContext = TestComponentContext().componentContext,
        repository = historyRepository,
        savedPairingRepository = FakeSavedPairingRepository(),
        compareRepository = compareRepository,
        favorites = favorites,
        appLanguage = FakeAppLanguageRepository(),
        confirmClearFactory = ConfirmClearHistoryComponent.Factory { ctx, onConfirm, onCancel ->
            DefaultConfirmClearHistoryComponent(ctx, onConfirm, onCancel)
        },
        onOpenScan = { openedScans += it },
        onOpenScanner = {},
        onOpenPairing = {},
        mainContext = UnconfinedTestDispatcher(testScheduler),
    )

    private fun viewWith(card: WineCard) = RecognitionView(
        decision = "uncertain",
        bottleCount = 1,
        frameSize = listOf(1000, 1000),
        bottles = listOf(RecognizedBottle(number = 1, instanceId = "b1", best = card)),
    )
}
