package com.aiweapps.winescan.domain.assistant.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** One input photograph, owned by the conversation that received it. */
@Serializable
data class AssistantPhoto(
    val id: String,
    val path: String,
    val name: String,
)

/** A scanner card remains bound to its source photograph and physical bottle. */
@Serializable
data class AssistantWine(
    val slug: String,
    val title: String,
    val producer: String?,
    val region: String?,
    val category: String?,
    val foodPairings: List<String>,
    val reference: String?,
    val pageUrl: String?,
    val photoId: String?,
    val photoPath: String?,
    val instanceId: String?,
    val uncertain: Boolean,
    val description: String? = null,
    val dishes: List<com.aiweapps.winescan.domain.scan.model.WineDish> = emptyList(),
    /** Exact scanner geometry when available; old conversations keep these unknown. */
    val sourceCrop: com.aiweapps.winescan.domain.scan.model.BottleBox? = null,
    val sourceFrame: List<Int>? = null,
    val sourceScanId: Long? = null,
)

/** A scanner result from the current upload; photoNumber refers to the user's photo order. */
@Serializable
data class AssistantPhotoWine(val photoNumber: Int, val wine: AssistantWine)

@Serializable
enum class AssistantPhotoScanStatus { FOUND, UNKNOWN, SCAN_FAILED }

/** Result of scanning one photo, including photos without wine candidates. */
@Serializable
data class AssistantPhotoScan(val photoNumber: Int, val status: AssistantPhotoScanStatus)

@Serializable
data class AssistantStore(
    val id: Int,
    val name: String,
    val address: String,
    val mode: String,
    val checkedAt: String?,
    val sapId: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val distanceMetres: Double? = null,
    val chain: String = "perekrestok",
    val sourceUrl: String? = null,
    val updatedAt: String? = null,
    /** Local confirmation boundary; an older capture cannot verify a new selection. */
    val selectedAt: String? = null,
)

data class AssistantLocation(
    val address: String,
    val source: AssistantLocationSource,
    val latitude: Double? = null,
    val longitude: Double? = null,
)

enum class AssistantLocationSource { GPS, MANUAL }

/** One replacement search, including its own provenance rather than the source basket's. */
data class AssistantReplacementCandidates(
    val products: List<AssistantProduct>,
    /** Recognized wire mode; null means the source is unknown, never implicitly live. */
    val source: String?,
    val checkedAt: String?,
    val storeId: Int?,
)

@Serializable
data class AssistantProduct(
    val id: String,
    val title: String,
    val pack: String?,
    val quantity: Int,
    val unitPriceKopeks: Long?,
    val lineTotalKopeks: Long?,
    val url: String?,
    val availability: String?,
    val source: String?,
    val recipeQuantity: String? = null,
    val retailSlug: String? = null,
    val retailPlu: String? = null,
    val primaryCategoryId: Int? = null,
    val catalogPrimaryCategoryId: Int? = null,
    val retailUnit: Int? = null,
    val quantum: Double? = null,
    val quantumStep: Double? = null,
    val weight: Double? = null,
    val volume: Double? = null,
    val pricePerQuantumKopeks: Long? = null,
    /** Only the server resolves the retailer price basis and purchasable lot. */
    val priceBasis: String = "unknown",
    val purchaseLotQuantity: Double? = null,
    val purchaseLotUnit: String? = null,
    val purchaseLotPriceKopeks: Long? = null,
    /** Optional public retailer CDN thumbnail. It uses no application Bearer. */
    @SerialName("image_url") val imageUrl: String? = null,
) {
    val hasKnownPurchaseQuantity: Boolean get() = priceBasis in setOf("piece", "weight") &&
        purchaseLotQuantity?.let { it.isFinite() && it > 0 } == true && !purchaseLotUnit.isNullOrBlank()
    val hasKnownPurchaseLot: Boolean get() = hasKnownPurchaseQuantity && purchaseLotPriceKopeks?.let { it >= 0 } == true
    val displayLineTotalKopeks: Long? get() = lineTotalKopeks.takeIf { hasKnownPurchaseLot }
}


@Serializable
data class AssistantDinner(
    val id: String,
    val title: String,
    val explanation: String,
    val preparationMinutes: Int?,
    val totalKopeks: Long?,
    val products: List<AssistantProduct>,
    val caveat: String? = null,
    /** Present only for server-backed alternatives that require an explicit choice. */
    val remoteOptionId: String? = null,
) {
    val displayTotalKopeks: Long? get() = verifiedPurchaseTotal(products, totalKopeks)
}

@Serializable
enum class AssistantMessageKind {
    USER_TEXT, USER_PHOTOS, ASSISTANT_TEXT, WINE_RESULTS, DINNER_OPTIONS,
    PRODUCTS, STATUS, ERROR, LOCATION_REQUEST, STORE_CANDIDATES, STORE_SELECTED,
}

@Serializable
enum class AssistantUiError {
    SCAN_FAILED,
    WINE_UNKNOWN,
    SERVICE_UNAVAILABLE,
    SESSION_OPEN_FAILED,
    STORE_UNAVAILABLE,
    RETAIL_SEARCH_FAILED,
    RETAIL_ACCESS_REQUIRED,
    REPLACEMENT_UNAVAILABLE,
    DINNER_SELECTION_UNAVAILABLE,
    DINNER_SELECTION_STALE,
}

/** Exact wire context for a resumable text request; no filesystem paths or credentials. */
@Serializable
data class AssistantRequestContext(
    val requestId: String,
    val wine: AssistantWine? = null,
    val photoWines: List<AssistantPhotoWine> = emptyList(),
    val photoScans: List<AssistantPhotoScan> = emptyList(),
    val storeId: Int? = null,
    val comparisonWines: List<AssistantWine> = emptyList(),
    val awaitingReply: Boolean = true,
)

@Serializable
data class AssistantMessage(
    val id: String,
    val kind: AssistantMessageKind,
    val text: String = "",
    val photos: List<AssistantPhoto> = emptyList(),
    val wines: List<AssistantWine> = emptyList(),
    val dinners: List<AssistantDinner> = emptyList(),
    val products: List<AssistantProduct> = emptyList(),
    val stores: List<AssistantStore> = emptyList(),
    val storeVerified: Boolean = false,
    val totalKopeks: Long? = null,
    val source: String? = null,
    /** Raw assistant message UUID required by the server's versioned shopping-list API. */
    val sourceMessageId: String? = null,
    val selectedDinnerOptionId: String? = null,
    val replacementForProductId: String? = null,
    val errorCode: AssistantUiError? = null,
    val checkedAt: String? = null,
    /** Durable idempotency key for a locally authored text request. */
    val requestId: String? = null,
    /** Kept separately from the original user intent's ID when a store is added. */
    val retryContext: AssistantRequestContext? = null,
    /** Exact retailer store from the server event, never inferred from the active UI. */
    val retailStoreId: Int? = null,
    /** Cards imported from comparison, without inventing photo-number attribution. */
    val comparisonContext: Boolean = false,
) {
    val displayTotalKopeks: Long? get() = verifiedPurchaseTotal(products, totalKopeks)
}

data class AssistantConversation(
    val id: String,
    val title: String,
    val lastMessage: String,
)

enum class AssistantPhase { IDLE, RECOGNIZING, THINKING, SEARCHING_STORE, REPLACING_PRODUCT, SELECTING_DINNER }

private fun verifiedPurchaseTotal(products: List<AssistantProduct>, total: Long?): Long? {
    if (products.isEmpty() || products.any { it.displayLineTotalKopeks == null }) return null
    val sum = products.sumOf { it.displayLineTotalKopeks ?: 0 }
    return total?.takeIf { it == sum }
}
