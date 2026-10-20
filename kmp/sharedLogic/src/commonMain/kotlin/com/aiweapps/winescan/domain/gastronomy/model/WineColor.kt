package com.aiweapps.winescan.domain.gastronomy.model

import kotlinx.serialization.Serializable

/** The wine's colour; the UI localises it. Sparkling is a separate flag, not a colour. */
@Serializable
enum class WineColor {
    RED, WHITE, ROSE, ORANGE, UNKNOWN;

    companion object {
        fun fromWire(value: String): WineColor = when (value.trim().lowercase()) {
            "red" -> RED
            "white" -> WHITE
            "rose", "rosé" -> ROSE
            "orange" -> ORANGE
            else -> UNKNOWN
        }
    }
}

/** The sugar category, still and sparkling scales together; the UI localises it. */
@Serializable
enum class WineSugar {
    DRY, SEMI_DRY, SEMI_SWEET, SWEET, BRUT, EXTRA_BRUT, BRUT_NATURE, UNKNOWN;

    companion object {
        fun fromWire(value: String): WineSugar = when (value.trim().lowercase().replace('-', '_')) {
            "dry" -> DRY
            "semi_dry" -> SEMI_DRY
            "semi_sweet" -> SEMI_SWEET
            "sweet" -> SWEET
            "brut" -> BRUT
            "extra_brut" -> EXTRA_BRUT
            "brut_nature" -> BRUT_NATURE
            else -> UNKNOWN
        }
    }
}

/** The serving range in whole degrees Celsius; [minC] equals [maxC] for a single value. */
@Serializable
data class ServingTemperature(val minC: Int, val maxC: Int)
