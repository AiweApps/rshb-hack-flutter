package com.aiweapps.winescan.data.pairing

import com.aiweapps.winescan.data.pairing.dao.SavedPairingDao
import com.aiweapps.winescan.data.pairing.model.SavedPairingEntity
import com.aiweapps.winescan.data.pairing.repository.SavedPairingRepositoryImpl
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.testutil.TestDishes
import com.aiweapps.winescan.testutil.gastronomy
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json

class SavedPairingRepositoryImplTest {

    private val dao = InMemorySavedPairingDao()
    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false }
    private val repository = SavedPairingRepositoryImpl(dao, json)

    @Test
    fun aSavedChoiceKeepsWhatItNeedsToRenderOffline() = runTest {
        val card = WineCard(slug = "a", title = "A")
        val id = repository.save(
            dish = TestDishes.CHEESE,
            wines = listOf(card),
            gastronomy = mapOf(
                "a" to gastronomy("a", pairings = listOf(TestDishes.CHEESE, TestDishes.MEAT)),
                "other" to gastronomy("other", pairings = listOf(TestDishes.FISH)),
            ),
            dishes = TestDishes.ALL,
            compareSetSize = 2,
        )

        val saved = assertNotNull(repository.byId(id))

        assertEquals(TestDishes.CHEESE, saved.dish)
        assertEquals(setOf("a"), saved.gastronomy.keys)
        assertEquals(setOf(TestDishes.MEAT, TestDishes.CHEESE), saved.dishes.toSet(), "only the dishes the wine lists")
        assertEquals("Выдержанные сыры", dao.rows.single().dish, "the plain column keeps the default label")
        assertEquals(2, saved.compareSetSize, "the set the choice was made among, not only the matching wine")
    }

    @Test
    fun aRowFromBeforeDishIdsGetsTheCatalogueDishId() = runTest {
        dao.insert(SavedPairingEntity(dish = "Сыры", winesJson = """[{"slug":"a","title":"A"}]""", createdAt = 1))

        val saved = assertNotNull(repository.byId(1))

        assertEquals(Dish(id = "сыры", labels = mapOf("ru" to "Сыры")), saved.dish, "the id the catalogue's «Сыры» gets")
        assertEquals("Сыры", saved.dish.labelIn("en"))
        assertTrue(saved.gastronomy.isEmpty())
        assertEquals(1, saved.compareSetSize, "an old row counts its own wines")
    }

    private class InMemorySavedPairingDao : SavedPairingDao {
        private val table = MutableStateFlow<List<SavedPairingEntity>>(emptyList())
        val rows: List<SavedPairingEntity> get() = table.value

        override fun observeAll(): Flow<List<SavedPairingEntity>> = table

        override suspend fun byId(id: Long): SavedPairingEntity? = table.value.firstOrNull { it.id == id }

        override suspend fun insert(entity: SavedPairingEntity): Long {
            val row = entity.copy(id = table.value.size + 1L)
            table.value = table.value + row
            return row.id
        }

        override suspend fun deleteById(id: Long) {
            table.value = table.value.filterNot { it.id == id }
        }
    }
}
