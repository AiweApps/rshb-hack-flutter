package com.aiweapps.winescan.components.pairing

import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.components.common.model.WineFacts
import com.aiweapps.winescan.components.pairing.model.DishPairingToast
import com.aiweapps.winescan.config.AnalyticsEvents
import com.aiweapps.winescan.data.gastronomy.remote.CatalogGastronomyDataSource
import com.aiweapps.winescan.data.gastronomy.repository.GastronomyRepositoryImpl
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.repository.GastronomyRepository
import com.aiweapps.winescan.domain.pairing.model.PairingSource
import com.aiweapps.winescan.domain.pairing.model.PairingVerdict
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.testutil.FakeAnalyticsTracker
import com.aiweapps.winescan.testutil.FakeAppLanguageRepository
import com.aiweapps.winescan.testutil.FakeCompareSetRepository
import com.aiweapps.winescan.testutil.FakeGastronomyRepository
import com.aiweapps.winescan.testutil.FakePlatformLinks
import com.aiweapps.winescan.testutil.FakeSavedPairingRepository
import com.aiweapps.winescan.testutil.FakeWineCatalogRepository
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
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class DefaultDishPairingComponentTest {

    private val compareRepository = FakeCompareSetRepository()
    private val savedPairingRepository = FakeSavedPairingRepository()
    private val gastronomyRepository = FakeGastronomyRepository()
    private val appLanguage = FakeAppLanguageRepository()
    private val analytics = FakeAnalyticsTracker()

    @Test
    fun aChosenDishIsMatchedByIdAndSavedOnce() = runTest {
        seedWine("a", TestDishes.CHEESE)
        seedWine("b", TestDishes.MEAT)
        val component = createComponent(PairingSource.FromCompareSet)

        assertEquals(listOf("Красное мясо", "Выдержанные сыры"), component.state.value.dishes.map { it.label })
        component.onDishTapped(TestDishes.CHEESE.id)
        assertEquals(listOf("a"), component.state.value.matched.map { it.card.slug })
        assertEquals(listOf("b"), component.state.value.unmatched.map { it.card.slug }, "a non-match is shown too")
        assertTrue(component.state.value.canSave)

        component.onSaveClicked()

        val saved = savedPairingRepository.all.single()
        assertEquals(TestDishes.CHEESE, saved.dish)
        assertEquals(setOf("a"), saved.gastronomy.keys, "the snapshot keeps the saved wines' gastronomy only")
        assertEquals(DishPairingToast.SAVED, component.state.value.toast)
        assertFalse(component.state.value.canSave, "a saved choice is not saved twice")

        component.onDishTapped(TestDishes.MEAT.id)

        assertEquals(listOf("b"), component.state.value.matched.map { it.card.slug })
        assertTrue(component.state.value.canSave, "a new dish after a save is a new choice")
    }

    @Test
    fun tappingTheChosenDishAgainClearsTheChoice() = runTest {
        seedWine("a", TestDishes.CHEESE)
        seedWine("b", TestDishes.MEAT)
        val component = createComponent(PairingSource.FromCompareSet)
        component.onDishTapped(TestDishes.CHEESE.id)
        component.onSaveClicked()

        component.onDishTapped(TestDishes.CHEESE.id)

        val state = component.state.value
        assertNull(state.selectedDish)
        assertTrue(state.matches.isEmpty())
        assertNull(state.savedId, "with no dish there is no saved choice on screen")
        assertEquals(2, state.dishes.size, "every dish is there to choose from again")
    }

    @Test
    fun changingTheDishGoesBackToEveryDishWithNoneChosen() = runTest {
        seedWine("a", TestDishes.CHEESE)
        seedWine("b", TestDishes.MEAT)
        val component = createComponent(PairingSource.FromCompareSet)
        component.onDishTapped(TestDishes.CHEESE.id)
        component.onSaveClicked()

        component.onChangeDishClicked()

        val state = component.state.value
        assertNull(state.selectedDish)
        assertTrue(state.matches.isEmpty())
        assertNull(state.savedId)
        assertEquals(2, state.dishes.size)
    }

    @Test
    fun changingTheDishOfASavedChoiceLeavesItForTheCurrentSet() = runTest {
        val id = savedPairingRepository.save(
            dish = TestDishes.CHEESE,
            wines = listOf(WineCard(slug = "old", title = "Old")),
            gastronomy = mapOf("old" to gastronomy("old", pairings = listOf(TestDishes.CHEESE))),
            dishes = listOf(TestDishes.CHEESE),
            compareSetSize = 1,
        )
        seedWine("new", TestDishes.FISH)
        val component = createComponent(PairingSource.Saved(id))

        component.onChangeDishClicked()

        val state = component.state.value
        assertNull(state.savedId)
        assertNull(state.selectedDish)
        assertEquals(listOf("new"), state.wines.map { it.card.slug })
    }

    @Test
    fun aSavedChoiceCountsTheWinesItWasMadeAmongNotOnlyTheMatchingOnes() = runTest {
        seedWine("a", TestDishes.CHEESE)
        seedWine("b", TestDishes.MEAT)
        val live = createComponent(PairingSource.FromCompareSet)
        live.onDishTapped(TestDishes.CHEESE.id)
        live.onSaveClicked()
        assertEquals(2, live.state.value.wineCount)

        val saved = createComponent(PairingSource.Saved(savedPairingRepository.all.single().id))

        assertEquals(listOf("a"), saved.state.value.matched.map { it.card.slug })
        assertEquals(2, saved.state.value.wineCount, "«among 2 wines from the comparison», as when it was kept")
    }

    @Test
    fun aWineWithoutGastronomyIsNoDataNotNoMatch() = runTest {
        seedWine("a", TestDishes.CHEESE)
        compareRepository.seed(WineCard(slug = "unknown", title = "Unknown"))
        val component = createComponent(PairingSource.FromCompareSet)

        component.onDishTapped(TestDishes.CHEESE.id)

        assertEquals(listOf("unknown"), component.state.value.withoutData.map { it.card.slug })
        assertEquals(WineFacts.NO_DATA, component.state.value.facts["unknown"])
    }

    @Test
    fun aFailedLoadIsNoDishesAndAnEventNotAnErrorScreen() = runTest {
        seedWine("a", TestDishes.CHEESE)
        gastronomyRepository.failGastronomy = true
        val component = createComponent(PairingSource.FromCompareSet)

        assertIs<ScreenState.Content>(component.state.value.screenState)
        assertTrue(component.state.value.hasNoDishes)
        assertEquals(1, analytics.eventsNamed(AnalyticsEvents.GASTRONOMY_FAILED).size)
    }

    @Test
    fun theDishesFollowTheAppLanguage() = runTest {
        seedWine("a", TestDishes.CHEESE)
        val component = createComponent(PairingSource.FromCompareSet)
        component.onDishTapped(TestDishes.CHEESE.id)

        appLanguage.switchTo("en")

        assertEquals("Aged cheeses", component.state.value.selectedDish?.label)
        assertEquals(listOf("Aged cheeses"), component.state.value.facts["a"]?.pairings?.map { it.label })
    }

    @Test
    fun aSavedChoiceOpensFromItsSnapshotAndCanBeRedoneOverTheCurrentSet() = runTest {
        val oldCard = WineCard(slug = "old", title = "Old")
        val id = savedPairingRepository.save(
            dish = TestDishes.CHEESE,
            wines = listOf(oldCard),
            gastronomy = mapOf("old" to gastronomy("old", pairings = listOf(TestDishes.CHEESE))),
            dishes = listOf(TestDishes.CHEESE),
            compareSetSize = 1,
        )
        seedWine("new", TestDishes.FISH)
        // The snapshot must be enough: the network has nothing about the saved wine.
        gastronomyRepository.failDishes = true
        val component = createComponent(PairingSource.Saved(id))

        assertEquals(id, component.state.value.savedId)
        assertEquals("Выдержанные сыры", component.state.value.selectedDish?.label)
        assertEquals(listOf("old"), component.state.value.matched.map { it.card.slug })
        assertEquals(listOf("Выдержанные сыры"), component.state.value.facts["old"]?.pairings?.map { it.label })

        gastronomyRepository.failDishes = false
        component.onDishTapped(TestDishes.CHEESE.id)

        assertNull(component.state.value.savedId)
        assertEquals(listOf(TestDishes.FISH.id), component.state.value.dishes.map { it.id })
    }

    @Test
    fun aMissingSavedChoiceIsAnError() = runTest {
        val component = createComponent(PairingSource.Saved(42))

        assertIs<ScreenState.Error>(component.state.value.screenState)
    }

    @Test
    fun theCatalogueDishesBecomeChipsAndEveryWineGetsAVerdict() = runTest {
        val catalog = FakeWineCatalogRepository(
            WineCard(slug = "red", title = "Red", category = "Красное сухое", foodPairings = listOf("Мясо и стейки", "Сыры")),
            WineCard(slug = "white", title = "White", category = "Белое сухое", foodPairings = listOf("Сыры", "Лёгкие закуски")),
            WineCard(slug = "silent", title = "Silent", category = "Белое сухое"),
        )
        val repository = GastronomyRepositoryImpl(CatalogGastronomyDataSource(catalog))
        listOf("red", "white", "silent", "unknown").forEach { compareRepository.seed(WineCard(slug = it, title = it)) }
        val component = createComponent(PairingSource.FromCompareSet, repository)

        assertEquals(listOf("Мясо и стейки", "Сыры", "Лёгкие закуски"), component.state.value.dishes.map { it.label })
        component.onDishTapped("сыры")

        val verdicts = component.state.value.matches.associate { it.card.slug to it.verdict }
        assertEquals(PairingVerdict.MATCH, verdicts["red"])
        assertEquals(PairingVerdict.MATCH, verdicts["white"])
        assertEquals(PairingVerdict.NO_DATA, verdicts["silent"], "no pairings in the catalogue is «no data»")
        assertEquals(PairingVerdict.NO_DATA, verdicts["unknown"], "a slug the catalogue does not know is «no data»")
    }

    @Test
    fun aDishTheCatalogueDoesNotListGoesToTheAssistantWithTheWines() = runTest {
        seedWine("a", TestDishes.CHEESE)
        seedWine("b", TestDishes.MEAT)
        var handedOver: Pair<List<String>, String>? = null
        val component = createComponent(PairingSource.FromCompareSet, onPlanDinner = { wines, prompt ->
            handedOver = wines.map { it.slug } to prompt
        })

        component.onCustomDishRequested(dish = "Утка", prompt = "  Что подать к утке?  ")

        assertEquals(listOf("a", "b") to "Что подать к утке?", handedOver)
        assertEquals(listOf("a", "b"), component.state.value.wines.map { it.card.slug })
    }

    private fun seedWine(slug: String, vararg dishes: Dish) {
        compareRepository.seed(WineCard(slug = slug, title = slug.uppercase()))
        gastronomyRepository.seed(gastronomy(slug, pairings = dishes.toList()))
    }

    private fun TestScope.createComponent(
        source: PairingSource,
        repository: GastronomyRepository = gastronomyRepository,
        onPlanDinner: (List<WineCard>, String) -> Unit = { _, _ -> },
    ) = DefaultDishPairingComponent(
        componentContext = TestComponentContext().componentContext,
        source = source,
        compareRepository = compareRepository,
        savedPairingRepository = savedPairingRepository,
        scanRepository = FakeScanRepository(),
        gastronomyRepository = repository,
        appLanguage = appLanguage,
        platformLinks = FakePlatformLinks(),
        analytics = analytics,
        onClose = {},
        onOpenScanner = {},
        onPlanDinner = onPlanDinner,
        mainContext = UnconfinedTestDispatcher(testScheduler),
    )
}
