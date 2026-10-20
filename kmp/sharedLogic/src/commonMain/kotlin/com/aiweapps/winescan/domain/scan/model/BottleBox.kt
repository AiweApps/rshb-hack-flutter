package com.aiweapps.winescan.domain.scan.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonPrimitive
import kotlin.math.roundToInt

/**
 * An axis-aligned box in EXIF-oriented original pixels, as the API reports bottle geometry
 * and accepts `target_roi`: `[x1, y1, x2, y2]`.
 */
@Serializable
data class BottleBox(
    val x1: Double,
    val y1: Double,
    val x2: Double,
    val y2: Double,
) {
    val width: Double get() = x2 - x1

    val height: Double get() = y2 - y1

    val longerSide: Double get() = if (width > height) width else height

    /** JSON array form for `target_roi`, rounded to whole pixels. */
    fun toList(): List<Int> = listOf(x1.roundToInt(), y1.roundToInt(), x2.roundToInt(), y2.roundToInt())

    fun toJson(): JsonElement = JsonArray(toList().map { JsonPrimitive(it) })

    /** The box clamped to a frame, as the API insists on `0 <= x1 < x2 <= w`. */
    fun clampTo(frameWidth: Double, frameHeight: Double): BottleBox = BottleBox(
        x1 = x1.coerceIn(0.0, frameWidth),
        y1 = y1.coerceIn(0.0, frameHeight),
        x2 = x2.coerceIn(0.0, frameWidth),
        y2 = y2.coerceIn(0.0, frameHeight),
    )

    companion object {
        private const val SIDES = 4

        /** Reads `[x1, y1, x2, y2]`; anything else is treated as no box. */
        fun fromJson(json: JsonElement?): BottleBox? {
            val array = json as? JsonArray ?: return null
            if (array.size != SIDES) return null
            val values = array.map { (it as? JsonPrimitive)?.jsonPrimitive?.doubleOrNull ?: return null }
            return BottleBox(values[0], values[1], values[2], values[3])
        }

        /** A box from two corner points in any order. */
        fun fromPoints(ax: Double, ay: Double, bx: Double, by: Double): BottleBox = BottleBox(
            x1 = minOf(ax, bx),
            y1 = minOf(ay, by),
            x2 = maxOf(ax, bx),
            y2 = maxOf(ay, by),
        )
    }
}
