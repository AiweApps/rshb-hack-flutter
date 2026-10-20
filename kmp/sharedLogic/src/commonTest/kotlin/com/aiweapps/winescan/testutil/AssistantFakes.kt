package com.aiweapps.winescan.testutil

import com.aiweapps.winescan.domain.assistant.model.AssistantConversation
import com.aiweapps.winescan.domain.assistant.model.AssistantPhoto
import com.aiweapps.winescan.domain.assistant.model.AssistantWine
import com.aiweapps.winescan.domain.assistant.repository.AssistantLocalRepository
import com.aiweapps.winescan.domain.assistant.repository.AssistantLocalState
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf

/** «My wines» in memory; the conversations are not needed by the screens tested here. */
class FakeAssistantLocalRepository : AssistantLocalRepository {

    private val saved = MutableStateFlow<List<AssistantWine>>(emptyList())

    val savedWines: List<AssistantWine> get() = saved.value

    var failOnWrite: Boolean = false

    fun seed(wine: AssistantWine) {
        saved.value = saved.value + wine
    }

    override suspend fun hasAnyAssistantData(): Boolean = saved.value.isNotEmpty()

    override fun watchConversations(): Flow<List<AssistantConversation>> = flowOf(emptyList())

    override suspend fun load(conversationId: String): AssistantLocalState? = null

    override suspend fun save(state: AssistantLocalState) = Unit

    override suspend fun delete(conversationId: String) = Unit

    override suspend fun loadSavedWines(): List<AssistantWine> = saved.value

    override suspend fun saveSavedWines(wines: List<AssistantWine>) {
        if (failOnWrite) error("storage unavailable")
        saved.value = wines
    }

    override fun watchSavedWines(): Flow<List<AssistantWine>> = saved

    override suspend fun updateSavedWines(
        transform: (List<AssistantWine>) -> List<AssistantWine>,
    ): List<AssistantWine> {
        if (failOnWrite) error("storage unavailable")
        return transform(saved.value).also { saved.value = it }
    }

    override suspend fun copyPhoto(conversationId: String, photo: AssistantPhoto): AssistantPhoto = photo

    override suspend fun deleteDraftPhoto(conversationId: String, photoId: String) = Unit

    override suspend fun resolvePhotoPath(photoId: String): String? = null
}

fun savedWine(slug: String) = AssistantWine(
    slug = slug,
    title = slug,
    producer = null,
    region = null,
    category = null,
    foodPairings = emptyList(),
    reference = null,
    pageUrl = null,
    photoId = "chat-photo",
    photoPath = null,
    instanceId = "b1",
    uncertain = false,
)
