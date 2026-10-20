package com.aiweapps.winescan.data.gastronomy

import com.aiweapps.core.error.AppError
import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.data.gastronomy.repository.GastronomyRepositoryImpl
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.testutil.TestDishes
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlinx.coroutines.test.runTest

class GastronomyRepositoryImplTest {

    private val source = CountingSource()
    private val repository = GastronomyRepositoryImpl(source)

    @Test
    fun theDictionaryIsAskedForEveryTimeBecauseItGrows() = runTest {
        repository.dishes()
        repository.dishes()

        assertEquals(2, source.dishCalls, "the source adds the dishes of every wine it reads")
    }

    @Test
    fun aSlugIsAskedForOnceEvenWhenItHasNoData() = runTest {
        repository.gastronomy(listOf(card("a"), card("missing")))
        val second = repository.gastronomy(listOf(card("a"), card("missing"), card("b")))

        assertEquals(listOf(listOf("a", "missing"), listOf("b")), source.requests)
        assertEquals(setOf("a", "b"), assertIs<ApiResponse.Success<Map<String, WineGastronomy>>>(second).data.keys)
    }

    @Test
    fun aFailureIsNotCached() = runTest {
        source.fail = true
        assertIs<ApiResponse.Error>(repository.gastronomy(listOf(card("a"))))
        assertIs<ApiResponse.Error>(repository.dishes())

        source.fail = false

        assertIs<ApiResponse.Success<*>>(repository.gastronomy(listOf(card("a"))))
        assertEquals(2, source.requests.size, "the failed slug is asked for again")
    }

    private fun card(slug: String) = WineCard(slug = slug, title = slug)

    private class CountingSource : GastronomyDataSource {
        var fail = false
        var dishCalls = 0
        val requests = mutableListOf<List<String>>()

        override suspend fun dishes(): ApiResponse<List<Dish>> {
            dishCalls++
            return if (fail) ApiResponse.Error(AppError.Network) else ApiResponse.Success(TestDishes.ALL, 200)
        }

        override suspend fun gastronomy(cards: List<WineCard>): ApiResponse<List<WineGastronomy>> {
            requests += cards.map { it.slug }
            if (fail) return ApiResponse.Error(AppError.Network)
            return ApiResponse.Success(cards.filter { it.slug != "missing" }.map { WineGastronomy(slug = it.slug) }, 200)
        }
    }
}
