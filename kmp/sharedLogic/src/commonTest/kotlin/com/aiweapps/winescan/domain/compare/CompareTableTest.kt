package com.aiweapps.winescan.domain.compare

import com.aiweapps.winescan.domain.compare.model.CompareAttribute
import com.aiweapps.winescan.domain.compare.model.CompareEntry
import com.aiweapps.winescan.domain.compare.model.CompareRow
import com.aiweapps.winescan.domain.compare.model.CompareTable
import com.aiweapps.winescan.domain.compare.model.CompareValue
import com.aiweapps.winescan.domain.gastronomy.model.DishDictionary
import com.aiweapps.winescan.domain.gastronomy.model.ServingTemperature
import com.aiweapps.winescan.domain.gastronomy.model.WineColor
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.gastronomy.model.WineSugar
import com.aiweapps.winescan.domain.pairing.model.DishMatcher
import com.aiweapps.winescan.domain.pairing.model.PairingVerdict
import com.aiweapps.winescan.domain.scan.model.WineCard
import com.aiweapps.winescan.testutil.TestDishes
import com.aiweapps.winescan.testutil.gastronomy
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

class CompareTableTest {

    private val white = entry(WineCard(slug = "tamara", title = "Tamara", region = "Кубань"))
    private val red = entry(WineCard(slug = "saperavi", title = "Саперави", region = "Кубань"))
    private val noData = entry(WineCard(slug = "brut", title = "Брют"))

    private val loaded: Map<String, WineGastronomy?> = mapOf(
        "tamara" to gastronomy(
            "tamara",
            pairings = listOf(TestDishes.FISH, TestDishes.CHEESE),
            color = WineColor.WHITE,
            temperature = ServingTemperature(8, 10),
        ),
        "saperavi" to gastronomy("saperavi", pairings = listOf(TestDishes.MEAT, TestDishes.CHEESE)),
        "brut" to null,
    )
    private val dishes = DishDictionary(TestDishes.ALL)

    @Test
    fun colourSugarAndTemperatureAreComparedAsValuesNotText() {
        val rows = rows(white, red)

        assertTrue(rows.getValue(CompareAttribute.COLOR).isDifferent)
        assertFalse(rows.getValue(CompareAttribute.SUGAR).isDifferent, "dry against dry is the same")
        assertTrue(rows.getValue(CompareAttribute.TEMPERATURE).isDifferent, "8–10 against 16–18 differs")
        assertFalse(rows.getValue(CompareAttribute.REGION).isDifferent)
        assertEquals(CompareValue.Color(WineColor.WHITE, false), rows.getValue(CompareAttribute.COLOR).values[0])
        assertEquals(CompareValue.Sugar(WineSugar.DRY), rows.getValue(CompareAttribute.SUGAR).values[1])
    }

    @Test
    fun aWineWithoutGastronomyIsNoDataAndMakesTheRowDifferent() {
        val rows = rows(white, noData)

        assertEquals(CompareValue.None, rows.getValue(CompareAttribute.PAIRINGS).values[1])
        assertTrue(rows.getValue(CompareAttribute.PAIRINGS).isDifferent)
        assertFalse(rows(noData, noData).getValue(CompareAttribute.TEMPERATURE).isDifferent, "nothing against nothing")
    }

    @Test
    fun sharedPairingsAreMarkedByIdAndNamedInTheLanguage() {
        val row = rows(white, red, language = "en").getValue(CompareAttribute.PAIRINGS)

        val first = assertIs<CompareValue.Pairings>(row.values[0])
        assertEquals(setOf(TestDishes.CHEESE.id), first.sharedIds)
        assertEquals(listOf("White fish", "Aged cheeses"), first.dishes.map { it.label }, "the dictionary's order")
        assertTrue(row.isDifferent)
    }

    @Test
    fun anEmptyListIsNotNoData() {
        val listsNone = mapOf("tamara" to gastronomy("tamara", pairings = emptyList()))

        val cell = CompareTable.build(listOf(white), listsNone, dishes, "ru")
            .first { it.attribute == CompareAttribute.PAIRINGS }.values.single()

        assertEquals(CompareValue.Pairings(emptyList(), emptySet()), cell)
    }

    @Test
    fun aWineStillLoadingIsPendingAndNeverDifferent() {
        val rows = CompareTable.build(listOf(white, red), mapOf("tamara" to loaded["tamara"]), dishes, "ru")
            .associateBy { it.attribute }

        assertEquals(CompareValue.Pending, rows.getValue(CompareAttribute.COLOR).values[1])
        assertFalse(rows.getValue(CompareAttribute.COLOR).isDifferent)
        assertEquals(CompareValue.Text("Кубань"), rows.getValue(CompareAttribute.REGION).values[1], "card fields do not wait")
    }

    @Test
    fun dishesAreTheUnionInTheDictionaryOrder() {
        val dishes = DishMatcher.dishes(listOf(white, red, noData), loaded, dishes, "ru")

        assertEquals(listOf("red_meat", "white_fish", "hard_cheese"), dishes.map { it.id })
    }

    @Test
    fun aWineWithoutPairingsIsNoDataNotNoMatch() {
        val verdicts = DishMatcher.match(listOf(white, red, noData), loaded, TestDishes.CHEESE.id).map { it.verdict }

        assertEquals(listOf(PairingVerdict.MATCH, PairingVerdict.MATCH, PairingVerdict.NO_DATA), verdicts)
        assertEquals(PairingVerdict.NO_MATCH, DishMatcher.match(listOf(red), loaded, TestDishes.FISH.id).single().verdict)
    }

    private fun rows(vararg entries: CompareEntry, language: String = "ru"): Map<CompareAttribute, CompareRow> =
        CompareTable.build(entries.toList(), loaded, dishes, language).associateBy { it.attribute }

    private fun entry(card: WineCard) =
        CompareEntry(card, photoPath = "p.jpg", crop = null, frame = null, scanId = null, addedAtMillis = 0)
}
