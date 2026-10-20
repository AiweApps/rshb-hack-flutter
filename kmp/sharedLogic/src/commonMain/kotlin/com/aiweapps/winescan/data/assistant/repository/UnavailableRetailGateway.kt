package com.aiweapps.winescan.data.assistant.repository

import com.aiweapps.winescan.domain.assistant.repository.RetailGateway
import com.aiweapps.winescan.domain.assistant.repository.RetailResult
import com.aiweapps.winescan.domain.assistant.repository.RetailUnavailableReason

/** iOS and unsupported environments use the assistant service for retailer data. */
class UnavailableRetailGateway : RetailGateway {
    override suspend fun selectStore(storeId: Int): RetailResult =
        RetailResult.Unavailable(RetailUnavailableReason.DEVICE_OFFLINE)

    override suspend fun searchProducts(query: String, storeId: Int): RetailResult =
        RetailResult.Unavailable(RetailUnavailableReason.DEVICE_OFFLINE)
}
