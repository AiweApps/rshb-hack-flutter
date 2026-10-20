package com.aiweapps.winescan.domain.assistant.model

import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.PI
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/** Approximate entrances of the two stores for which the device catalog was verified. */
object KnownStoreLocations {
    private data class Point(val id: Int, val latitude: Double, val longitude: Double)

    private val points = listOf(
        Point(814, 47.276336, 38.915240), // ТЦ Арбуз, Бакинская 65
        Point(817, 47.219689, 38.920231), // ТЦ СитиЦентр, Гоголевский 2/1
    )

    /** A suggestion for confirmation, never proof that the user is inside the shop. */
    fun nearby(latitude: Double, longitude: Double, stores: List<AssistantStore>): AssistantStore? {
        if (!latitude.isFinite() || !longitude.isFinite()) return null
        val nearest = points.map { point ->
            point.id to distanceMetres(latitude, longitude, point.latitude, point.longitude)
        }.minByOrNull { it.second } ?: return null
        if (nearest.second > MAX_SUGGESTION_METRES) return null
        return stores.firstOrNull { it.id == nearest.first }
    }

    private fun distanceMetres(aLat: Double, aLon: Double, bLat: Double, bLon: Double): Double {
        val lat = PI / 180.0
        val dLat = (bLat - aLat) * lat
        val dLon = (bLon - aLon) * lat
        val h = sin(dLat / 2).pow(2) + cos(aLat * lat) * cos(bLat * lat) * sin(dLon / 2).pow(2)
        return 2 * EARTH_RADIUS_METRES * asin(min(1.0, sqrt(h)))
    }

    private const val EARTH_RADIUS_METRES = 6_371_000.0
    private const val MAX_SUGGESTION_METRES = 3_000.0
}
