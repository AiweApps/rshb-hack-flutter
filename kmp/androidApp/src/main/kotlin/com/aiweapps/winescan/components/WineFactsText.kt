package com.aiweapps.winescan.components

import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.aiweapps.winescan.R
import com.aiweapps.winescan.domain.gastronomy.model.ServingTemperature
import com.aiweapps.winescan.domain.gastronomy.model.WineColor
import com.aiweapps.winescan.domain.gastronomy.model.WineSugar
import java.text.NumberFormat

private const val PART_SEPARATOR = " · "

@StringRes
private fun WineColor.labelRes(): Int? = when (this) {
    WineColor.RED -> R.string.wine_color_red
    WineColor.WHITE -> R.string.wine_color_white
    WineColor.ROSE -> R.string.wine_color_rose
    WineColor.ORANGE -> R.string.wine_color_orange
    WineColor.UNKNOWN -> null
}

@StringRes
private fun WineSugar.labelRes(): Int? = when (this) {
    WineSugar.DRY -> R.string.wine_sugar_dry
    WineSugar.SEMI_DRY -> R.string.wine_sugar_semi_dry
    WineSugar.SEMI_SWEET -> R.string.wine_sugar_semi_sweet
    WineSugar.SWEET -> R.string.wine_sugar_sweet
    WineSugar.BRUT -> R.string.wine_sugar_brut
    WineSugar.EXTRA_BRUT -> R.string.wine_sugar_extra_brut
    WineSugar.BRUT_NATURE -> R.string.wine_sugar_brut_nature
    WineSugar.UNKNOWN -> null
}

/** «Красное · Игристое»; `null` when the colour is unknown and the wine is not known to be sparkling. */
@Composable
fun colorText(color: WineColor?, isSparkling: Boolean?): String? {
    val colorName = color?.labelRes()?.let { stringResource(it) }
    val sparkling = if (isSparkling == true) stringResource(R.string.wine_sparkling) else null
    return listOfNotNull(colorName, sparkling).takeIf { it.isNotEmpty() }?.joinToString(PART_SEPARATOR)
}

@Composable
fun sugarText(sugar: WineSugar?): String? = sugar?.labelRes()?.let { stringResource(it) }

/** «16–18 °C», or «16 °C» when the range is a single value. */
@Composable
fun temperatureText(temperature: ServingTemperature?): String? = when {
    temperature == null -> null
    temperature.minC == temperature.maxC -> stringResource(R.string.wine_serving_single, temperature.minC)
    else -> stringResource(R.string.wine_serving_range, temperature.minC, temperature.maxC)
}

/** The domain validates the range; the native formatter supplies locale-specific percent text. */
fun alcoholText(alcohol: Double): String = NumberFormat.getPercentInstance().apply {
    maximumFractionDigits = 2
}.format(alcohol / 100)
