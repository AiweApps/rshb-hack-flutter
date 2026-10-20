package com.aiweapps.winescan.data.pairing.repository

import com.aiweapps.winescan.config.GastronomyConfig
import com.aiweapps.winescan.data.gastronomy.model.dishIdOf
import com.aiweapps.winescan.data.pairing.dao.SavedPairingDao
import com.aiweapps.winescan.data.pairing.model.SavedPairingEntity
import com.aiweapps.winescan.data.pairing.model.SavedPairingSnapshot
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.pairing.model.SavedPairing
import com.aiweapps.winescan.domain.pairing.repository.SavedPairingRepository
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json

@OptIn(ExperimentalTime::class)
internal class SavedPairingRepositoryImpl(
    private val dao: SavedPairingDao,
    private val json: Json,
    private val clock: Clock = Clock.System,
) : SavedPairingRepository {

    override fun watchAll(): Flow<List<SavedPairing>> =
        dao.observeAll().map { rows -> rows.mapNotNull { it.toDomain() } }

    override suspend fun byId(id: Long): SavedPairing? = dao.byId(id)?.toDomain()

    override suspend fun save(
        dish: Dish,
        wines: List<WineCard>,
        gastronomy: Map<String, WineGastronomy>,
        dishes: List<Dish>,
        compareSetSize: Int,
    ): Long {
        val slugs = wines.map { it.slug }.toSet()
        val kept = gastronomy.filterKeys { it in slugs }.values.toList()
        val listed = kept.flatMap { it.pairingIds.orEmpty() }.toSet() + dish.id
        val snapshot = SavedPairingSnapshot(
            dish = dish,
            gastronomy = kept,
            dishes = dishes.filter { it.id in listed },
            compareSetSize = compareSetSize,
        )
        return dao.insert(
            SavedPairingEntity(
                dish = dish.labelIn(GastronomyConfig.DEFAULT_LANGUAGE),
                winesJson = json.encodeToString(wines),
                createdAt = clock.now().toEpochMilliseconds(),
                snapshotJson = json.encodeToString(snapshot),
            )
        )
    }

    override suspend fun delete(id: Long) {
        dao.deleteById(id)
    }

    // A row whose JSON no longer parses is skipped rather than crashing the list.
    private fun SavedPairingEntity.toDomain(): SavedPairing? {
        val wines = decode { json.decodeFromString<List<WineCard>>(winesJson) } ?: return null
        val snapshot = snapshotJson?.let { decode { json.decodeFromString<SavedPairingSnapshot>(it) } }
        return SavedPairing(
            id = id,
            // A row from before dish ids kept the catalogue's label: its id is derived the same
            // way the catalogue's dishes get theirs, so it matches today's chips.
            dish = snapshot?.dish ?: Dish(id = dishIdOf(dish), labels = mapOf(GastronomyConfig.CATALOG_LANGUAGE to dish)),
            wines = wines,
            gastronomy = snapshot?.gastronomy.orEmpty().associateBy { it.slug },
            dishes = snapshot?.dishes.orEmpty(),
            createdAtMillis = createdAt,
            // The set itself was never kept before the size was; its matching wines are the floor.
            compareSetSize = snapshot?.compareSetSize ?: wines.size,
        )
    }

    private inline fun <T> decode(block: () -> T): T? = try {
        block()
    } catch (_: SerializationException) {
        null
    } catch (_: IllegalArgumentException) {
        null
    }
}
