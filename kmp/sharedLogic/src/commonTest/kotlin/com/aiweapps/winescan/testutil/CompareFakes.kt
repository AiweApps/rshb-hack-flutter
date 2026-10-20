package com.aiweapps.winescan.testutil

import com.aiweapps.winescan.config.CompareLimits
import com.aiweapps.winescan.domain.compare.model.AddToCompareResult
import com.aiweapps.winescan.domain.compare.model.CompareCandidate
import com.aiweapps.winescan.domain.compare.model.CompareEntry
import com.aiweapps.winescan.domain.compare.repository.CompareSetRepository
import com.aiweapps.winescan.domain.gastronomy.model.Dish
import com.aiweapps.winescan.domain.gastronomy.model.WineGastronomy
import com.aiweapps.winescan.domain.pairing.model.SavedPairing
import com.aiweapps.winescan.domain.pairing.repository.SavedPairingRepository
import com.aiweapps.winescan.domain.scan.model.WineCard
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

/** The comparison set in memory, with the same two rules as the real one: no duplicates, a cap. */
class FakeCompareSetRepository : CompareSetRepository {

    private val entries = MutableStateFlow<List<CompareEntry>>(emptyList())
    private var nextTime = 1L

    val current: List<CompareEntry> get() = entries.value

    var failOnWrite: Boolean = false

    fun seed(card: WineCard, photoPath: String = "photo.jpg"): CompareEntry {
        val entry = CompareEntry(card, photoPath, crop = null, frame = null, scanId = null, addedAtMillis = nextTime++)
        entries.value = entries.value + entry
        return entry
    }

    override fun watch(): Flow<List<CompareEntry>> = entries

    override suspend fun add(candidate: CompareCandidate): AddToCompareResult {
        if (failOnWrite) error("storage unavailable")
        if (entries.value.any { it.slug == candidate.card.slug }) return AddToCompareResult.ALREADY_THERE
        if (entries.value.size >= CompareLimits.MAX_WINES) return AddToCompareResult.FULL
        entries.value = entries.value + CompareEntry(
            card = candidate.card,
            photoPath = candidate.photoPath,
            crop = candidate.crop,
            frame = candidate.frame,
            scanId = candidate.scanId,
            addedAtMillis = nextTime++,
        )
        return AddToCompareResult.ADDED
    }

    override suspend fun remove(slug: String) {
        if (failOnWrite) error("storage unavailable")
        entries.value = entries.value.filterNot { it.slug == slug }
    }

    override suspend fun clear() {
        entries.value = emptyList()
    }
}

class FakeSavedPairingRepository : SavedPairingRepository {

    private val saved = MutableStateFlow<List<SavedPairing>>(emptyList())
    private var nextId = 1L

    val all: List<SavedPairing> get() = saved.value

    var failOnWrite: Boolean = false

    override fun watchAll(): Flow<List<SavedPairing>> = saved

    override suspend fun byId(id: Long): SavedPairing? = saved.value.firstOrNull { it.id == id }

    override suspend fun save(
        dish: Dish,
        wines: List<WineCard>,
        gastronomy: Map<String, WineGastronomy>,
        dishes: List<Dish>,
        compareSetSize: Int,
    ): Long {
        if (failOnWrite) error("storage unavailable")
        val id = nextId++
        val slugs = wines.map { it.slug }.toSet()
        val pairing = SavedPairing(
            id = id,
            dish = dish,
            wines = wines,
            gastronomy = gastronomy.filterKeys { it in slugs },
            dishes = dishes,
            createdAtMillis = id,
            compareSetSize = compareSetSize,
        )
        saved.value = listOf(pairing) + saved.value
        return id
    }

    override suspend fun delete(id: Long) {
        saved.value = saved.value.filterNot { it.id == id }
    }
}
