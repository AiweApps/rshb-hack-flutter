package com.aiweapps.winescan.data.gastronomy

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.data.gastronomy.model.dishIdOf
import com.aiweapps.winescan.data.gastronomy.model.parseServingTemperature
import com.aiweapps.winescan.data.gastronomy.remote.CatalogGastronomyDataSource
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.ServingTemperature
import com.aiweapps.winescan.domain.gastronomy.model.WineColor
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.gastronomy.model.WineSugar
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.domain.scan.model.WineDish
import com.aiweapps.winescan.testutil.FakeWineCatalogRepository
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlinx.coroutines.test.runTest

/** The catalogue's free-text fields, as `v1/wines/<slug>` publishes them, read into gastronomy. */
class CatalogGastronomyDataSourceTest {

    private val catalog = FakeWineCatalogRepository(
        WineCard(
            slug = "135",
            title = "135",
            category = "Красное сухое",
            color = "Рубиновый",
            sugar = "сухое",
            servingTemperature = "16-18",
            foodPairings = listOf("Мясо и стейки", "Сыры"),
            pageUrl = "https://vino-svoe.ru/wines/135",
        ),
        WineCard(
            slug = "brut",
            title = "Brut",
            category = "Белое экстра брют",
            sugar = "экстра брют",
            servingTemperature = "6–8 °C",
            foodPairings = listOf("Устрицы", "Лёгкие закуски"),
        ),
        WineCard(slug = "none", title = "None", foodPairings = emptyList()),
        WineCard(slug = "silent", title = "Silent", category = "Розовое"),
        WineCard(
            slug = "dishes-only",
            title = "Dishes only",
            dishes = listOf(WineDish(name = "Легкие закуски", imageUrl = null)),
        ),
    )
    private val source = CatalogGastronomyDataSource(catalog)

    @Test
    fun aFullCardMapsToTheDomain() = runTest {
        val wine = load("135").getValue("135")

        assertEquals(WineColor.RED, wine.color)
        assertEquals(false, wine.isSparkling)
        assertEquals(WineSugar.DRY, wine.sugar)
        assertEquals(ServingTemperature(16, 18), wine.servingTemperature)
        assertEquals(listOf("мясо и стейки", "сыры"), wine.pairingIds)
        assertEquals("https://vino-svoe.ru/wines/135", wine.sourceUrl)
    }

    @Test
    fun sparklingSugarAndAnEnDashRangeAreRead() = runTest {
        val wine = load("brut").getValue("brut")

        assertEquals(WineColor.WHITE, wine.color)
        assertEquals(true, wine.isSparkling)
        assertEquals(WineSugar.EXTRA_BRUT, wine.sugar)
        assertEquals(ServingTemperature(6, 8), wine.servingTemperature)
    }

    @Test
    fun noPairingsIsNoDataAndAnEmptyListListsNone() = runTest {
        val loaded = load("none", "silent")

        assertEquals(emptyList(), loaded.getValue("none").pairingIds, "[] is «lists none»")
        assertNull(loaded.getValue("silent").pairingIds, "a missing list is «no data»")
        assertEquals(WineColor.ROSE, loaded.getValue("silent").color)
    }

    @Test
    fun anUnknownSlugIsLeftOutNotAFailure() = runTest {
        assertEquals(setOf("135"), load("135", "unknown").keys)
    }

    @Test
    fun anyOtherFailureFailsTheRequest() = runTest {
        catalog.fail = true

        assertIs<ApiResponse.Error>(source.gastronomy(listOf(card("135"))))
    }

    @Test
    fun theDictionaryIsBuiltFromTheLabelsSeenWithStableIds() = runTest {
        load("135", "brut", "dishes-only")

        val dishes = assertIs<ApiResponse.Success<List<Dish>>>(source.dishes()).data

        assertEquals(
            listOf("Мясо и стейки", "Сыры", "Устрицы", "Лёгкие закуски"),
            dishes.map { it.labelIn("en") },
            "first seen first; «Легкие» and «Лёгкие» are one dish, labelled as first seen",
        )
        assertEquals(dishIdOf("Легкие закуски"), dishIdOf(" Лёгкие   закуски "))
    }

    @Test
    fun aTemperatureWithoutNumbersIsNoData() {
        assertNull(parseServingTemperature("комнатная"))
        assertNull(parseServingTemperature(null))
        assertEquals(ServingTemperature(12, 12), parseServingTemperature("12"))
        assertEquals(ServingTemperature(16, 18), parseServingTemperature("18-16"))
    }

    private suspend fun load(vararg slugs: String): Map<String, WineGastronomy> =
        assertIs<ApiResponse.Success<List<WineGastronomy>>>(source.gastronomy(slugs.map(::card))).data.associateBy { it.slug }

    private fun card(slug: String) = WineCard(slug = slug, title = slug)
}
