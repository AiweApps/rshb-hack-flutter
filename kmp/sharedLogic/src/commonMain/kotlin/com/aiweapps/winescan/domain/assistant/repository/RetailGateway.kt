package com.aiweapps.winescan.domain.assistant.repository

import com.aiweapps.winescan.domain.assistant.model.AssistantProduct
import com.aiweapps.winescan.domain.assistant.model.AssistantStore

/** A platform-owned retailer session. WebView cookies and request headers stay on-device. */
interface RetailGateway {
    fun configureStore(store: AssistantStore) {}
    suspend fun selectStore(storeId: Int): RetailResult
    suspend fun searchProducts(query: String, storeId: Int): RetailResult
}

sealed interface RetailResult {
    data class Success(
        val store: AssistantStore,
        val products: List<AssistantProduct>,
        /** Search checks sapId. Product detail has a weaker session-only binding. */
        val storeVerified: Boolean,
    ) : RetailResult

    data class Unavailable(val reason: RetailUnavailableReason) : RetailResult
}

enum class RetailUnavailableReason { DEVICE_OFFLINE, ACCESS_REQUIRED, STORE_MISMATCH, BUSY, OTHER }
