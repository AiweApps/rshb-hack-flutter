package com.aiweapps.winescan.components.assistant.model

import com.aiweapps.core.components.model.BaseScreenState
import com.aiweapps.core.components.model.ScreenState
import com.aiweapps.winescan.domain.assistant.model.*
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess

enum class AssistantCompareNotice { SOURCE_UNAVAILABLE, FAILED }

data class AssistantState(
    override val screenState: ScreenState = ScreenState.Content,
    val account: com.aiweapps.winescan.domain.assistant.repository.AssistantAccount? = null,
    val accountRequestTicket: Int = 0,
    val accountBusy: Boolean = false,
    val accountError: Boolean = false,
    val legacyHistory: Boolean = true,
    val conversationId: String? = null,
    val conversations: List<AssistantConversation> = emptyList(),
    val messages: List<AssistantMessage> = emptyList(),
    val draft: String = "",
    val attachments: List<AssistantPhoto> = emptyList(),
    val pendingAttachments: Int = 0,
    val selectedWine: AssistantWine? = null,
    val savedWines: List<AssistantWine> = emptyList(),
    val compareSlugs: Set<String> = emptySet(),
    val compareBusyKey: String? = null,
    val compareNotice: AssistantCompareNotice? = null,
    val availableStores: List<AssistantStore> = emptyList(),
    val location: AssistantLocation? = null,
    val selectedStore: AssistantStore? = null,
    val suggestedStore: AssistantStore? = null,
    val locationRequestTicket: Int = 0,
    val phase: AssistantPhase = AssistantPhase.IDLE,
    val errorCode: AssistantUiError? = null,
    val referenceAccess: ReferenceAccess? = null,
) : BaseScreenState {
    /** Message-scoped retry, so an old card cannot launch another operation. */
    val retryableMessageIds: Set<String> get() = messages.mapIndexedNotNull { index, message ->
        if (message.kind != AssistantMessageKind.ERROR) return@mapIndexedNotNull null
        val later = messages.drop(index + 1)
        val superseded = if (message.photos.isNotEmpty()) {
            val ids = message.photos.map { it.id }.toSet()
            later.any { next -> next.wines.any { it.photoId in ids } ||
                (next.kind == AssistantMessageKind.ERROR && next.photos.any { it.id in ids }) }
        } else later.any { it.kind in setOf(AssistantMessageKind.USER_TEXT, AssistantMessageKind.USER_PHOTOS,
            AssistantMessageKind.ASSISTANT_TEXT, AssistantMessageKind.ERROR) }
        message.id.takeUnless { superseded }
    }.toSet()

    val activeBasketMessageId: String? get() = messages.lastOrNull {
        it.kind == AssistantMessageKind.PRODUCTS && it.sourceMessageId != null && it.replacementForProductId == null
    }?.id

    val activeReplacementMessageId: String? get() {
        val basket = messages.firstOrNull { it.id == activeBasketMessageId } ?: return null
        return messages.lastOrNull { it.replacementForProductId != null }
            ?.takeIf { it.sourceMessageId == basket.sourceMessageId }?.id
    }

    val canSend: Boolean get() = screenState == ScreenState.Content && phase == AssistantPhase.IDLE && pendingAttachments == 0 &&
        (draft.isNotBlank() || attachments.isNotEmpty())
}
