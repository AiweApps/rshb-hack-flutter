package com.aiweapps.winescan.data.gastronomy

import com.aiweapps.winescan.domain.gastronomy.model.WineColor
import com.aiweapps.winescan.domain.gastronomy.model.WineSugar

/** What a catalogue category such as «Красное сухое» or «Игристое брют» says about the wine. */
internal data class CategoryHints(
    val color: WineColor?,
    val isSparkling: Boolean?,
    val sugar: WineSugar?,
) {
    companion object {

        private val NONE = CategoryHints(color = null, isSparkling = null, sugar = null)

        private val COLOR_PREFIXES = listOf(
            "красн" to WineColor.RED, "red" to WineColor.RED,
            "бел" to WineColor.WHITE, "white" to WineColor.WHITE,
            "розов" to WineColor.ROSE, "rose" to WineColor.ROSE,
            "оранжев" to WineColor.ORANGE, "orange" to WineColor.ORANGE,
        )
        private val SPARKLING_PREFIXES = listOf("игрист", "шампан", "sparkling")
        private val STILL_SUGAR_PREFIXES = listOf(
            "полусух" to WineSugar.SEMI_DRY,
            "полусладк" to WineSugar.SEMI_SWEET,
            "сладк" to WineSugar.SWEET, "десертн" to WineSugar.SWEET, "sweet" to WineSugar.SWEET,
            "сух" to WineSugar.DRY, "dry" to WineSugar.DRY,
        )

        fun parse(category: String?): CategoryHints {
            val words = category.orEmpty().lowercase().replace('ё', 'е').replace('é', 'e')
                .split(' ', '-', ',', '/', '.').filter { it.isNotEmpty() }
            if (words.isEmpty()) return NONE
            val color = words.firstNotNullOfOrNull { word -> COLOR_PREFIXES.firstOrNull { word.startsWith(it.first) }?.second }
            val sugar = sparklingSugar(words) ?: words.firstNotNullOfOrNull { word ->
                STILL_SUGAR_PREFIXES.firstOrNull { word.startsWith(it.first) }?.second
            }
            val sparklingWord = words.any { word -> SPARKLING_PREFIXES.any { word.startsWith(it) } }
            val isSparkling = when {
                sparklingWord || sugar in SPARKLING_SUGARS -> true
                color != null || sugar != null -> false
                else -> null
            }
            return CategoryHints(color = color, isSparkling = isSparkling, sugar = sugar)
        }

        private fun sparklingSugar(words: List<String>): WineSugar? {
            val brut = words.indexOfFirst { it == "брют" || it == "brut" }
            if (brut < 0) return null
            val before = words.getOrNull(brut - 1)
            val after = words.getOrNull(brut + 1)
            return when {
                before == "экстра" || before == "extra" -> WineSugar.EXTRA_BRUT
                after != null && (after.startsWith("натур") || after.startsWith("натюр") || after == "nature") ->
                    WineSugar.BRUT_NATURE
                else -> WineSugar.BRUT
            }
        }

        private val SPARKLING_SUGARS = setOf(WineSugar.BRUT, WineSugar.EXTRA_BRUT, WineSugar.BRUT_NATURE)
    }
}
