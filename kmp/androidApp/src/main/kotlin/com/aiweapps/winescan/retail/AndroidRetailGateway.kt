package com.aiweapps.winescan.retail

import com.aiweapps.winescan.domain.assistant.model.AssistantProduct
import com.aiweapps.winescan.domain.assistant.model.AssistantStore
import com.aiweapps.winescan.domain.assistant.repository.RetailGateway
import com.aiweapps.winescan.domain.assistant.repository.RetailResult
import com.aiweapps.winescan.domain.assistant.repository.RetailUnavailableReason
import java.time.Instant

/** Bridges shared commands to the current foreground Activity's on-device WebView. */
class AndroidRetailGateway : RetailGateway {
    @Volatile private var adapter: PerekrestokWebViewAdapter? = null

    private val stores = java.util.concurrent.ConcurrentHashMap<Int, AssistantStore>()
    override fun configureStore(store: AssistantStore) {
        if (store.chain != "perekrestok") return
        stores[store.id] = store
        store.sapId?.let { adapter?.configureStore(store.id, it) }
    }

    fun attach(current: PerekrestokWebViewAdapter) {
        adapter = current
        stores.values.forEach { store -> store.sapId?.let { current.configureStore(store.id, it) } }
    }

    fun detach(current: PerekrestokWebViewAdapter) {
        if (adapter === current) adapter = null
    }

    override suspend fun selectStore(storeId: Int): RetailResult {
        val current = adapter ?: return RetailResult.Unavailable(RetailUnavailableReason.DEVICE_OFFLINE)
        if (!current.isForeground) return RetailResult.Unavailable(RetailUnavailableReason.DEVICE_OFFLINE)
        return map(current.selectStore(storeId))
    }

    override suspend fun searchProducts(query: String, storeId: Int): RetailResult {
        val current = adapter ?: return RetailResult.Unavailable(RetailUnavailableReason.DEVICE_OFFLINE)
        if (!current.isForeground) return RetailResult.Unavailable(RetailUnavailableReason.DEVICE_OFFLINE)
        return map(current.searchProducts(query, storeId))
    }

    private fun map(result: RetailOperationResult): RetailResult = when (result) {
        is RetailOperationResult.Failure -> RetailResult.Unavailable(when (result.reason) {
            RetailFailure.SessionNotReady, RetailFailure.ChallengeOrBlocked -> RetailUnavailableReason.ACCESS_REQUIRED
            RetailFailure.Offline -> RetailUnavailableReason.DEVICE_OFFLINE
            RetailFailure.StoreMismatch -> RetailUnavailableReason.STORE_MISMATCH
            RetailFailure.Busy -> RetailUnavailableReason.BUSY
            is RetailFailure.HttpFailure -> if (result.reason.status == 401 || result.reason.status == 403)
                RetailUnavailableReason.ACCESS_REQUIRED else RetailUnavailableReason.OTHER
            RetailFailure.InvalidRequest, RetailFailure.InvalidResponse -> RetailUnavailableReason.OTHER
        })
        is RetailOperationResult.Success -> {
            val snapshot = result.snapshot
            val configured = stores[snapshot.storeId]
            val known = configured?.let { it.name to it.address } ?: STORES[snapshot.storeId]
            if (known == null) RetailResult.Unavailable(RetailUnavailableReason.STORE_MISMATCH)
            else {
                val resolved = configured?.copy(
                    mode = snapshot.mode,
                    checkedAt = if (snapshot.items.isNotEmpty() && snapshot.storeBinding == RetailStoreBinding.VerifiedSearch)
                        Instant.ofEpochMilli(snapshot.checkedAt).toString() else null,
                    sapId = snapshot.sapId,
                ) ?: AssistantStore(
                    id = snapshot.storeId,
                    name = known.first,
                    address = known.second,
                    mode = snapshot.mode,
                    checkedAt = if (snapshot.items.isNotEmpty() && snapshot.storeBinding == RetailStoreBinding.VerifiedSearch)
                        Instant.ofEpochMilli(snapshot.checkedAt).toString() else null,
                    sapId = snapshot.sapId,
                )
                stores[snapshot.storeId] = resolved
                RetailResult.Success(
                    store = resolved,
                    products = snapshot.items.map { item ->
                        AssistantProduct(
                            id = item.id.toString(),
                            title = item.title,
                            pack = item.unitName,
                            quantity = 1,
                            unitPriceKopeks = item.priceKopeks?.toLong(),
                            lineTotalKopeks = null,
                            url = item.productUrl,
                            availability = item.balanceState,
                            source = snapshot.source,
                            retailSlug = item.slug,
                            retailPlu = item.plu,
                            primaryCategoryId = item.primaryCategoryId,
                            catalogPrimaryCategoryId = item.catalogPrimaryCategoryId,
                            retailUnit = item.unit,
                            quantum = item.quantum,
                            quantumStep = item.quantumStep,
                            weight = item.weight,
                            volume = item.volume,
                            pricePerQuantumKopeks = item.pricePerQuantumKopeks?.toLong(),
                        )
                    },
                    storeVerified = snapshot.items.isNotEmpty() && snapshot.storeBinding == RetailStoreBinding.VerifiedSearch,
                )
            }
        }
    }

    private companion object {
        val STORES = mapOf(
            814 to ("Перекрёсток Арбуз" to "Таганрог, Бакинская 65"),
            817 to ("Перекрёсток СитиЦентр" to "Таганрог, Гоголевский 2/1"),
        )
    }
}
