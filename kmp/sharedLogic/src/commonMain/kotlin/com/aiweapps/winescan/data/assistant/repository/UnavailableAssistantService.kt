package com.aiweapps.winescan.data.assistant.repository

import com.aiweapps.winescan.domain.assistant.model.AssistantConversation
import com.aiweapps.winescan.domain.assistant.model.AssistantMessage
import com.aiweapps.winescan.domain.assistant.model.AssistantWine
import com.aiweapps.winescan.domain.assistant.model.AssistantReplacementCandidates
import com.aiweapps.winescan.domain.assistant.model.AssistantPhotoWine
import com.aiweapps.winescan.domain.assistant.model.AssistantPhotoScan
import com.aiweapps.winescan.domain.assistant.repository.AssistantService

/** Used until a configured local or deployed assistant endpoint is available. */
internal class UnavailableAssistantService : AssistantService {
    override suspend fun searchStores(query: String): List<com.aiweapps.winescan.domain.assistant.model.AssistantStore> = emptyList()
    override suspend fun nearbyStores(latitude: Double, longitude: Double): List<com.aiweapps.winescan.domain.assistant.model.AssistantStore> = emptyList()
    override suspend fun confirmStore(conversationId: String, requestId: String, storeId: Int): List<AssistantMessage> = emptyList()
    override suspend fun conversations(): List<AssistantConversation> = emptyList()
    override suspend fun createConversation(): String = error("Assistant endpoint is not configured")
    override suspend fun messages(conversationId: String): List<AssistantMessage> =
        error("Assistant endpoint is not configured")
    override suspend fun send(
        conversationId: String,
        requestId: String,
        text: String,
        selectedWine: AssistantWine?,
        photoWines: List<AssistantPhotoWine>,
        photoScans: List<AssistantPhotoScan>,
        storeId: Int?,
        comparisonWines: List<AssistantWine>,
    ): List<AssistantMessage> = error("Assistant endpoint is not configured")

    override suspend fun selectDinner(conversationId: String, sourceMessageId: String,
                                      requestId: String, optionId: String): List<AssistantMessage> =
        error("Assistant endpoint is not configured")

    override suspend fun replacementCandidates(conversationId: String, sourceMessageId: String, query: String): AssistantReplacementCandidates =
        error("Assistant endpoint is not configured")

    override suspend fun replaceProduct(conversationId: String, sourceMessageId: String, requestId: String,
                                        oldProductId: String, replacementProductId: String, packages: Int): List<AssistantMessage> =
        error("Assistant endpoint is not configured")
}
