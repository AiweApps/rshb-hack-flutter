package com.aiweapps.winescan.components.assistant

import com.arkivanov.decompose.ComponentContext
import com.arkivanov.decompose.value.Value
import com.aiweapps.winescan.components.assistant.model.AssistantState

/** The assistant owns conversation, attachment and request state for both native views. */
interface AssistantComponent {
    val state: Value<AssistantState>

    fun onAccountSubmit(username: String, password: String, register: Boolean)
    fun onLogoutClicked()
    fun onAccountErrorDismissed()
    fun onLocationCardRequested()
    fun onDraftChanged(text: String)
    fun onSendClicked()
    /** Reserve a stable conversation; null means account startup is not yet ready for a picker. */
    fun onPhotoSelectionStarted(): String?
    fun onAttachmentPicked(photoPath: String)
    fun onRemoveAttachment(id: String)
    fun onNewConversationClicked()
    fun onConversationSelected(id: String)
    /** Preserve an existing conversation, then stage a distinct comparison dinner conversation. */
    fun onComparisonRequested(wines: List<com.aiweapps.winescan.domain.scan.model.WineCard>, prompt: String)
    fun onWineSelected(slug: String)
    fun onWineFavoriteClicked(slug: String)
    fun onWineInstanceSelected(photoId: String?, instanceId: String?, slug: String)
    /** An explicit dinner intent; does not consume or overwrite the composer's draft. */
    fun onWineDinnerRequested(photoId: String?, instanceId: String?, slug: String, prompt: String) {
        onWineInstanceSelected(photoId, instanceId, slug)
    }
    fun onWineInstanceFavoriteClicked(photoId: String?, instanceId: String?, slug: String)
    /** Add the exact displayed bottle to the shared comparison set, then open that set. */
    fun onWineInstanceCompareClicked(photoId: String?, instanceId: String?, slug: String)
    fun onCompareNoticeConsumed()
    fun onLocationRequested()
    fun onLocationResolved(latitude: Double, longitude: Double, address: String)
    fun onAddressEntered(address: String)
    fun onStoreSelected(storeId: Int)
    fun onSearchProductsRequested(query: String)
    fun onDinnerSelected(id: String)
    fun onProductReplacementRequested(productId: String)
    fun onReplacementCandidateSelected(productId: String)
    fun onLinkClicked(url: String)
    fun onProductReplacementRequestedFrom(messageId: String, productId: String) {
        onProductReplacementRequested(productId)
    }
    fun onMessageRetryClicked(messageId: String) { onRetryClicked() }
    fun onReplacementCandidateChosen(messageId: String, originalProductId: String, productId: String) {
        onReplacementCandidateSelected(productId)
    }
    fun onRetryClicked()

    fun interface Factory {
        fun create(componentContext: ComponentContext, onOpenCompare: (com.aiweapps.winescan.domain.compare.model.AddToCompareResult) -> Unit): AssistantComponent
    }
}
