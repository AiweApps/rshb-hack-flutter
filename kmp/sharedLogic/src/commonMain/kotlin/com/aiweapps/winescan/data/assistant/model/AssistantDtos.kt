package com.aiweapps.winescan.data.assistant.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

@Serializable
internal data class SessionListDto(val sessions: List<SessionSummaryDto> = emptyList())

@Serializable
internal data class SessionSummaryDto(
    @SerialName("session_id") val sessionId: String,
    val title: String? = null,
)

@Serializable
internal data class SessionDto(
    @SerialName("session_id") val sessionId: String,
    val messages: List<AssistantMessageDto> = emptyList(),
    @SerialName("store_pending") val storePending: Boolean = false,
)

@Serializable
internal data class AssistantMessageDto(
    val id: String,
    val role: String,
    val text: String = "",
    val events: List<AssistantEventDto> = emptyList(),
    @SerialName("request_id") val requestId: String? = null,
    @SerialName("reply_to") val replyTo: String? = null,
)

@Serializable
internal data class AssistantEventDto(
    val type: String,
    val data: JsonObject = JsonObject(emptyMap()),
)

@Serializable
internal data class SendResponseDto(val message: AssistantMessageDto)

@Serializable
internal data class ReplacementCandidatesDto(
    val products: List<JsonObject> = emptyList(),
    @SerialName("data_mode") val dataMode: String? = null,
    @SerialName("checked_at") val checkedAt: String? = null,
    @SerialName("store_id") val storeId: Int? = null,
)

@Serializable
internal data class ReplacementRequestDto(
    @SerialName("request_id") val requestId: String,
    @SerialName("old_product_id") val oldProductId: Long,
    @SerialName("replacement_product_id") val replacementProductId: Long,
    val packages: Int,
)

@Serializable
internal data class DinnerSelectionRequestDto(
    @SerialName("request_id") val requestId: String,
    @SerialName("option_id") val optionId: String,
)

@Serializable
internal data class SelectedWineDto(
    val slug: String,
    val title: String,
    val producer: String? = null,
    @SerialName("food_pairings") val foodPairings: List<String> = emptyList(),
    val uncertain: Boolean = false,
)

@Serializable
internal data class PhotoWineDto(
    @SerialName("photo_number") val photoNumber: Int,
    val wine: SelectedWineDto,
)

@Serializable
internal data class PhotoScanDto(
    @SerialName("photo_number") val photoNumber: Int,
    val status: String,
)

@Serializable
internal data class SendMessageDto(
    @SerialName("request_id") val requestId: String,
    val text: String,
    @SerialName("store_id") val storeId: Int? = null,
    @SerialName("selected_wine") val selectedWine: SelectedWineDto? = null,
    @SerialName("photo_wines") val photoWines: List<PhotoWineDto> = emptyList(),
    @SerialName("photo_scans") val photoScans: List<PhotoScanDto> = emptyList(),
    @SerialName("comparison_wines") val comparisonWines: List<SelectedWineDto> = emptyList(),
)

@Serializable
internal data class StoreListDto(val stores: List<JsonObject> = emptyList())
@Serializable
internal data class ConfirmStoreDto(@SerialName("request_id") val requestId: String, @SerialName("store_id") val storeId: Int)

@Serializable
internal data class WineSearchDto(val wines: List<com.aiweapps.winescan.domain.scan.model.WineCard> = emptyList())
