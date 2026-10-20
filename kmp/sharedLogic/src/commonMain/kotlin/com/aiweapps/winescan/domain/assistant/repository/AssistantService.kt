package com.aiweapps.winescan.domain.assistant.repository

import com.aiweapps.winescan.domain.assistant.model.AssistantConversation
import com.aiweapps.winescan.domain.assistant.model.AssistantMessage
import com.aiweapps.winescan.domain.assistant.model.AssistantWine
import com.aiweapps.winescan.domain.assistant.model.AssistantReplacementCandidates
import com.aiweapps.winescan.domain.assistant.model.AssistantPhotoWine
import com.aiweapps.winescan.domain.assistant.model.AssistantPhotoScan

/** Only prepared scanner facts and text cross this boundary; raw photos never do. */
interface AssistantService {
    suspend fun searchStores(query: String): List<com.aiweapps.winescan.domain.assistant.model.AssistantStore>
    suspend fun nearbyStores(latitude: Double, longitude: Double): List<com.aiweapps.winescan.domain.assistant.model.AssistantStore>
    suspend fun confirmStore(conversationId: String, requestId: String, storeId: Int): List<AssistantMessage>
    suspend fun conversations(): List<AssistantConversation>
    suspend fun createConversation(): String
    suspend fun messages(conversationId: String): List<AssistantMessage>
    suspend fun send(
        conversationId: String,
        requestId: String,
        text: String,
        selectedWine: AssistantWine?,
        photoWines: List<AssistantPhotoWine>,
        photoScans: List<AssistantPhotoScan>,
        storeId: Int?,
        comparisonWines: List<AssistantWine> = emptyList(),
    ): List<AssistantMessage>

    suspend fun selectDinner(
        conversationId: String, sourceMessageId: String, requestId: String, optionId: String,
    ): List<AssistantMessage>

    suspend fun replacementCandidates(
        conversationId: String, sourceMessageId: String, query: String,
    ): AssistantReplacementCandidates

    suspend fun replaceProduct(
        conversationId: String, sourceMessageId: String, requestId: String,
        oldProductId: String, replacementProductId: String, packages: Int,
    ): List<AssistantMessage>
}

class AssistantDinnerSelectionStale : Exception()

class AssistantStoreContextChanged : Exception()

class AssistantRetailAccessRequired : Exception()
