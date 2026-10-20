package com.aiweapps.winescan.testutil

import com.aiweapps.core.error.AppError
import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.domain.catalog.repository.WineCatalogRepository
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.ServingTemperature
import com.aiweapps.winescan.domain.gastronomy.model.WineColor
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.gastronomy.model.WineSugar
import com.aiweapps.winescan.domain.gastronomy.repository.GastronomyRepository
import com.aiweapps.winescan.domain.language.repository.AppLanguageRepository
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/** A handful of dishes with both labels, enough to tell a match from a non-match by id. */
object TestDishes {
    val CHEESE = Dish("hard_cheese", mapOf("ru" to "Выдержанные сыры", "en" to "Aged cheeses"))
    val FISH = Dish("white_fish", mapOf("ru" to "Белая рыба", "en" to "White fish"))
    val MEAT = Dish("red_meat", mapOf("ru" to "Красное мясо", "en" to "Red meat"))
    val DESSERTS = Dish("desserts", mapOf("ru" to "Десерты", "en" to "Desserts"))
    val ALL = listOf(MEAT, FISH, CHEESE, DESSERTS)
}

fun gastronomy(
    slug: String,
    pairings: List<Dish>? = null,
    color: WineColor? = WineColor.RED,
    sugar: WineSugar? = WineSugar.DRY,
    temperature: ServingTemperature? = ServingTemperature(16, 18),
): WineGastronomy = WineGastronomy(
    slug = slug,
    color = color,
    isSparkling = false,
    sugar = sugar,
    servingTemperature = temperature,
    pairingIds = pairings?.map { it.id },
)

/** Answers from what was seeded; a slug never seeded has no data, as the API leaves it out. */
class FakeGastronomyRepository(
    private val dishes: List<Dish> = TestDishes.ALL,
) : GastronomyRepository {

    private val bySlug = mutableMapOf<String, WineGastronomy>()

    var failDishes: Boolean = false
    var failGastronomy: Boolean = false
    val requestedSlugs = mutableListOf<List<String>>()

    fun seed(vararg items: WineGastronomy) {
        items.forEach { bySlug[it.slug] = it }
    }

    override suspend fun dishes(): ApiResponse<List<Dish>> =
        if (failDishes) ApiResponse.Error(AppError.Network) else ApiResponse.Success(dishes, statusCode = 200)

    override suspend fun gastronomy(cards: List<WineCard>): ApiResponse<Map<String, WineGastronomy>> {
        requestedSlugs += cards.map { it.slug }
        if (failGastronomy) return ApiResponse.Error(AppError.Server(503))
        return ApiResponse.Success(cards.mapNotNull { bySlug[it.slug] }.associateBy { it.slug }, statusCode = 200)
    }
}

class FakeAppLanguageRepository(initial: String = "ru") : AppLanguageRepository {

    private val current = MutableStateFlow(initial)

    override val language: StateFlow<String> = current

    fun switchTo(code: String) {
        current.value = code
    }

    override fun refresh() {
        // The test switches the language by hand; there is no platform to re-read.
    }
}

/**
 * The source catalogue: cards by slug, 404 for any other slug, or a failure for every
 * request while [fail] is set. [requests] counts what reached it.
 */
class FakeWineCatalogRepository(vararg cards: WineCard) : WineCatalogRepository {

    private val bySlug = cards.associateBy { it.slug }.toMutableMap()

    var fail: Boolean = false
    val requests = mutableListOf<String>()

    fun seed(vararg cards: WineCard) {
        cards.forEach { bySlug[it.slug] = it }
    }

    override suspend fun wine(slug: String): ApiResponse<WineCard> {
        requests += slug
        if (fail) return ApiResponse.Error(AppError.Network)
        val card = bySlug[slug] ?: return ApiResponse.Error(AppError.Server(HTTP_NOT_FOUND), statusCode = HTTP_NOT_FOUND)
        return ApiResponse.Success(card, statusCode = 200)
    }

    override suspend fun enrich(card: WineCard): WineCard {
        val detail = (wine(card.slug) as? ApiResponse.Success)?.data ?: return card
        return card.copy(description = card.description ?: detail.description, alcohol = card.alcohol ?: detail.alcohol)
    }

    override suspend fun search(query: String): List<WineCard> =
        bySlug.values.filter { it.title.contains(query, ignoreCase = true) }

    private companion object {
        const val HTTP_NOT_FOUND = 404
    }
}
