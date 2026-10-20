package com.aiweapps.winescan.data.gastronomy.model

import com.aiweapps.winescan.config.GastronomyConfig
import com.aiweapps.winescan.data.gastronomy.CategoryHints
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.ServingTemperature
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlin.math.roundToInt

/**
 * One catalogue card's gastronomy. The catalogue speaks in free text — «Красное сухое»,
 * «экстра брют», «16-18», «Мясо и стейки» — so every field is read leniently and a value
 * that cannot be read is «no data», never a guess.
 *
 * [recognized] is the card the screen holds, for its category when the catalogue's lacks one.
 */
internal fun WineCard.toGastronomy(recognized: WineCard?): WineGastronomy {
    val category = CategoryHints.parse(category)
    val recognizedCategory = CategoryHints.parse(recognized?.category)
    // `color` is the hue («Рубиновый», «Розовый»): it names the colour only sometimes.
    val hue = CategoryHints.parse(color)
    val sugarWords = CategoryHints.parse(sugar)
    return WineGastronomy(
        slug = slug,
        color = category.color ?: recognizedCategory.color ?: hue.color,
        isSparkling = category.isSparkling ?: sugarWords.isSparkling ?: recognizedCategory.isSparkling,
        sugar = sugarWords.sugar ?: category.sugar ?: recognizedCategory.sugar,
        servingTemperature = parseServingTemperature(servingTemperature),
        pairingIds = catalogDishes()?.map { it.id },
        sourceUrl = catalogueUrl,
    )
}

/**
 * The dishes the card lists, each with an id derived from its label; `null` is «no data»,
 * empty is «lists none». `food_pairings` is the list; the illustrated `dishes` stand in
 * only when it is missing.
 */
internal fun WineCard.catalogDishes(): List<Dish>? {
    val labels = foodPairings ?: dishes.takeIf { it.isNotEmpty() }?.map { it.name } ?: return null
    return labels.map { it.trim().replace(WHITESPACE, " ") }
        .filter { it.isNotEmpty() }
        .map { label -> Dish(id = dishIdOf(label), labels = mapOf(GastronomyConfig.CATALOG_LANGUAGE to label)) }
        .distinctBy { it.id }
}

/**
 * A stable id for a catalogue dish label: case, «ё» and spacing do not make a new dish, so
 * «Лёгкие закуски» and «Легкие закуски» are one. Saved choices keep these ids, so the rule
 * must not change.
 */
internal fun dishIdOf(label: String): String =
    label.trim().lowercase().replace('ё', 'е').replace(WHITESPACE, " ")

/** «16-18», «16–18 °C», «8» to whole degrees; anything without a number is «no data». */
internal fun parseServingTemperature(text: String?): ServingTemperature? {
    val numbers = NUMBER.findAll(text.orEmpty())
        .mapNotNull { it.value.replace(',', '.').toDoubleOrNull()?.roundToInt() }
        .toList()
    val low = numbers.firstOrNull() ?: return null
    val high = numbers.last()
    return ServingTemperature(minC = minOf(low, high), maxC = maxOf(low, high))
}

private val WHITESPACE = Regex("\\s+")
private val NUMBER = Regex("\\d+(?:[.,]\\d+)?")
