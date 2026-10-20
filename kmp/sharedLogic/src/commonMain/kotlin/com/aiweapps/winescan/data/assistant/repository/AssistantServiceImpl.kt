package com.aiweapps.winescan.data.assistant.repository

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.data.assistant.model.AssistantEventDto
import com.aiweapps.winescan.data.assistant.model.AssistantMessageDto
import com.aiweapps.winescan.data.assistant.model.SelectedWineDto
import com.aiweapps.winescan.data.assistant.model.PhotoWineDto
import com.aiweapps.winescan.data.assistant.model.PhotoScanDto
import com.aiweapps.winescan.data.assistant.model.SendMessageDto
import com.aiweapps.winescan.data.assistant.model.ReplacementRequestDto
import com.aiweapps.winescan.data.assistant.model.ReplacementCandidatesDto
import com.aiweapps.winescan.data.assistant.model.DinnerSelectionRequestDto
import com.aiweapps.winescan.data.assistant.remote.AssistantApi
import com.aiweapps.winescan.domain.assistant.model.AssistantConversation
import com.aiweapps.winescan.domain.assistant.model.AssistantDinner
import com.aiweapps.winescan.domain.assistant.model.AssistantMessage
import com.aiweapps.winescan.domain.assistant.model.AssistantMessageKind
import com.aiweapps.winescan.domain.assistant.model.AssistantProduct
import com.aiweapps.winescan.domain.assistant.model.AssistantReplacementCandidates
import com.aiweapps.winescan.domain.assistant.model.AssistantUiError
import com.aiweapps.winescan.domain.assistant.model.AssistantWine
import com.aiweapps.winescan.domain.assistant.model.AssistantPhotoWine
import com.aiweapps.winescan.domain.assistant.model.AssistantPhotoScan
import com.aiweapps.winescan.domain.assistant.repository.AssistantService
import com.aiweapps.winescan.domain.assistant.repository.AssistantDinnerSelectionStale
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.longOrNull

/** Converts the local assistant HTTP protocol into native renderable items. */
internal class AssistantServiceImpl(private val api: AssistantApi) : AssistantService {
    override suspend fun searchStores(query: String) = api.searchStores(query).requireData().stores.mapNotNull { it.toStore() }
    override suspend fun nearbyStores(latitude: Double, longitude: Double) =
        api.nearbyStores(latitude, longitude).requireData().stores.mapNotNull { it.toStore() }
    override suspend fun confirmStore(conversationId: String, requestId: String, storeId: Int) =
        render(api.confirmStore(conversationId, com.aiweapps.winescan.data.assistant.model.ConfirmStoreDto(requestId, storeId)).requireData().message)
    override suspend fun conversations(): List<AssistantConversation> =
        api.sessions().requireData().sessions.map { session ->
            AssistantConversation(session.sessionId, session.title.orEmpty(), session.title.orEmpty())
        }

    override suspend fun createConversation(): String = api.create().requireData().sessionId

    override suspend fun messages(conversationId: String): List<AssistantMessage> =
        api.session(conversationId).requireData().let { session ->
            val requestIds = session.messages.filter { it.role == "user" }.associate { it.id to it.requestId }
            session.messages.flatMap { message -> render(message).map { item ->
                item.copy(requestId = if (message.role == "user") message.requestId else requestIds[message.replyTo])
            } } + if (session.storePending)
                listOf(AssistantMessage("$conversationId-pending-store", AssistantMessageKind.LOCATION_REQUEST)) else emptyList()
        }

    override suspend fun send(
        conversationId: String,
        requestId: String,
        text: String,
        selectedWine: AssistantWine?,
        photoWines: List<AssistantPhotoWine>,
        photoScans: List<AssistantPhotoScan>,
        storeId: Int?,
        comparisonWines: List<AssistantWine>,
    ): List<AssistantMessage> = api.send(
        conversationId,
        SendMessageDto(
            requestId = requestId,
            text = text,
            storeId = storeId,
            selectedWine = selectedWine?.let {
                SelectedWineDto(it.slug, it.title, it.producer, it.foodPairings.take(12), it.uncertain)
            },
            photoWines = photoWines.take(30).map { item ->
                PhotoWineDto(item.photoNumber, SelectedWineDto(
                    item.wine.slug, item.wine.title, item.wine.producer,
                    item.wine.foodPairings.take(12), item.wine.uncertain,
                ))
            },
            comparisonWines = comparisonWines.take(3).map {
                SelectedWineDto(it.slug, it.title, it.producer, it.foodPairings.take(12), it.uncertain)
            },
            photoScans = photoScans.take(10).map { PhotoScanDto(it.photoNumber, it.status.name.lowercase()) },
        ),
    ).requireData().message.let { message -> render(message).map { it.copy(requestId = requestId) } }

    override suspend fun selectDinner(
        conversationId: String, sourceMessageId: String, requestId: String, optionId: String,
    ): List<AssistantMessage> = when (val response = api.selectDinner(
        conversationId, sourceMessageId, DinnerSelectionRequestDto(requestId, optionId),
    )) {
        is ApiResponse.Success -> render(response.data.message)
        is ApiResponse.Error -> if (response.statusCode == 409) throw AssistantDinnerSelectionStale()
            else throw AssistantServiceUnavailable()
    }

    override suspend fun replacementCandidates(
        conversationId: String, sourceMessageId: String, query: String,
    ): AssistantReplacementCandidates {
        val response = api.replacementCandidates(conversationId, sourceMessageId, query).requireData()
        return AssistantReplacementCandidates(
            products = response.products.mapNotNull { it.toProduct() },
            source = response.dataMode?.takeIf {
                it in setOf("live_catalog", "saved_snapshot", "session_context", "perekrestok_webview")
            },
            checkedAt = replacementCheckedAt(response),
            storeId = response.storeId,
        )
    }

    @OptIn(kotlin.time.ExperimentalTime::class)
    private fun replacementCheckedAt(response: ReplacementCandidatesDto): String? {
        fun valid(value: String?): Pair<kotlin.time.Instant, String>? {
            if (value.isNullOrBlank()) return null
            val instant = runCatching { kotlin.time.Instant.parse(value) }.getOrNull() ?: return null
            return instant to value
        }
        // Offsets can differ: compare parsed instants, not the strings' lexical order.
        return valid(response.checkedAt)?.second ?: response.products
            .mapNotNull { valid(it.string("checked_at")) }
            .minByOrNull { it.first }?.second
    }

    override suspend fun replaceProduct(
        conversationId: String, sourceMessageId: String, requestId: String,
        oldProductId: String, replacementProductId: String, packages: Int,
    ): List<AssistantMessage> = api.replace(conversationId, sourceMessageId, ReplacementRequestDto(
        requestId, oldProductId.toLong(), replacementProductId.toLong(), packages,
    )).requireData().message.let(::render)

    private fun render(message: AssistantMessageDto): List<AssistantMessage> {
        if (message.role == "user") {
            val wines = message.events.filter { it.type == "wine_card" }.mapNotNull { it.data.toWine() }
            return listOf(AssistantMessage(message.id, AssistantMessageKind.USER_TEXT, message.text)) +
                if (wines.isNotEmpty()) listOf(AssistantMessage(
                    id = "${message.id}-wines", kind = AssistantMessageKind.WINE_RESULTS,
                    wines = wines.distinctBy { it.slug }, source = "catalog_context",
                    comparisonContext = message.events.any {
                        it.type == "wine_card" && (it.data["comparison"] as? JsonPrimitive)?.booleanOrNull == true
                    },
                )) else emptyList()
        }
        val result = mutableListOf(AssistantMessage(message.id, AssistantMessageKind.ASSISTANT_TEXT, message.text))
        // Search calls remain in the server trace for provenance and replacements.
        // A finished dinner is the answer; raw intermediate lists are not another meal.
        val hasMeal = message.events.any { event ->
            when (event.type) {
                "dinner_options" -> dinnerOptions("probe", message.id, event) != null
                "shopping_list" -> shoppingList("probe", message.id, event) != null
                else -> false
            }
        }
        message.events.forEachIndexed { index, event ->
            val item = when (event.type) {
                "location_request" -> AssistantMessage("${message.id}-$index", AssistantMessageKind.LOCATION_REQUEST)
                "store_candidates" -> AssistantMessage("${message.id}-$index", AssistantMessageKind.STORE_CANDIDATES,
                    stores = event.data.array("stores").mapNotNull { (it as? JsonObject)?.toStore() })
                "store_selected" -> AssistantMessage("${message.id}-$index", AssistantMessageKind.STORE_SELECTED,
                    stores = listOfNotNull((event.data["store"] as? JsonObject)?.toStore()))
                "product_options" -> if (hasMeal) null else productOptions("${message.id}-$index", event)
                "dinner_options" -> dinnerOptions("${message.id}-$index", message.id, event)
                "shopping_list" -> shoppingList("${message.id}-$index", message.id, event)
                "assistant_status", "retailer_status" -> if (event.data.string("status") == "unavailable") {
                    AssistantMessage(
                        id = "${message.id}-$index", kind = AssistantMessageKind.ERROR,
                        errorCode = if (event.data.string("manual_action") == "open_store" || event.data.string("reason") in setOf("challenge_or_block", "retailer_session_not_ready",
                            "http_401", "http_403", "retailer_access_required", "retailer_circuit_open")) AssistantUiError.RETAIL_ACCESS_REQUIRED
                            else if (event.type == "retailer_status") AssistantUiError.STORE_UNAVAILABLE
                            else AssistantUiError.SERVICE_UNAVAILABLE,
                    )
                } else null
                else -> null
            }
            if (item != null) result.add(item)
        }
        return result
    }

    private fun productOptions(id: String, event: AssistantEventDto): AssistantMessage? {
        val products = event.data.array("products").mapNotNull { (it as? JsonObject)?.toProduct() }
        if (products.isEmpty()) return null
        return AssistantMessage(
            id = id, kind = AssistantMessageKind.PRODUCTS,
            products = products, source = event.data.string("data_mode") ?: "saved_snapshot",
            retailStoreId = event.data.int("store_id"),
            checkedAt = event.data.array("products").mapNotNull { (it as? JsonObject)?.string("checked_at") }.minOrNull(),
        )
    }

    private fun shoppingList(id: String, sourceMessageId: String, event: AssistantEventDto): AssistantMessage? {
        val rows = productsFromRows(event.data.array("items"))
        if (rows.isEmpty()) return null
        // A product replacement updates the basket, not the recipe. Keep the original
        // title in the source event, but do not label a changed basket as that old dish.
        val title = if (event.data.long("replaced_product_id") != null) ""
            else event.data.string("dinner_title").orEmpty()
        val total = event.data.long("total_kopeks")
        val selected = event.data.string("selected_option_id") != null ||
            event.data.string("source_message_id") != null || event.data.long("replaced_product_id") != null
        val dinner = AssistantDinner(id, title, event.data.string("explanation").orEmpty(),
            event.data.int("preparation_minutes"), total, rows)
        return AssistantMessage(
            id = id, kind = if (selected) AssistantMessageKind.PRODUCTS else AssistantMessageKind.DINNER_OPTIONS,
            text = if (selected) title else "",
            dinners = if (selected) emptyList() else listOf(dinner),
            products = rows, totalKopeks = total,
            source = event.data.string("data_mode") ?: "saved_snapshot",
            retailStoreId = event.data.int("store_id"),
            sourceMessageId = sourceMessageId,
            selectedDinnerOptionId = event.data.string("selected_option_id"),
            checkedAt = event.data.string("checked_at") ?: event.data.array("items").mapNotNull {
                ((it as? JsonObject)?.get("product") as? JsonObject)?.string("checked_at")
            }.minOrNull(),
        )
    }

    private fun dinnerOptions(id: String, sourceMessageId: String, event: AssistantEventDto): AssistantMessage? {
        val dinners = event.data.array("options").mapNotNull { item ->
            val raw = item as? JsonObject ?: return@mapNotNull null
            val optionId = raw.string("id") ?: return@mapNotNull null
            val title = raw.string("title")?.takeIf { it.isNotBlank() } ?: return@mapNotNull null
            val products = productsFromRows(raw.array("items"))
            if (products.isEmpty()) return@mapNotNull null
            AssistantDinner(
                id = optionId, title = title, explanation = raw.string("explanation").orEmpty(),
                preparationMinutes = raw.int("preparation_minutes"),
                totalKopeks = raw.long("total_kopeks"), products = products,
                remoteOptionId = optionId,
            )
        }
        if (dinners.isEmpty()) return null
        return AssistantMessage(
            id = id, kind = AssistantMessageKind.DINNER_OPTIONS,
            dinners = dinners, products = dinners.flatMap { it.products },
            sourceMessageId = sourceMessageId,
            source = event.data.string("data_mode") ?: "saved_snapshot",
            retailStoreId = event.data.int("store_id"),
            checkedAt = event.data.string("checked_at") ?: event.data.array("options").mapNotNull {
                (it as? JsonObject)?.string("checked_at")
            }.minOrNull(),
        )
    }

    private fun productsFromRows(items: JsonArray): List<AssistantProduct> = items.mapNotNull { item ->
            val row = item as? JsonObject ?: return@mapNotNull null
            val raw = row["product"] as? JsonObject ?: return@mapNotNull null
            raw.toProduct()?.copy(
                quantity = row.int("packages") ?: 1,
                lineTotalKopeks = row.long("line_total_kopeks"),
                recipeQuantity = row.string("recipe_quantity"),
            )
        }

    private fun JsonObject.toWine(): AssistantWine? {
        val slug = string("slug") ?: return null
        val title = string("name") ?: string("title") ?: return null
        val card = com.aiweapps.winescan.domain.scan.model.WineCard(
            slug = slug, title = title, producer = string("producer"),
            category = string("category"), region = string("region"),
        )
        return AssistantWine(
            slug = slug, title = card.presentationTitle, producer = card.producer,
            region = card.region, category = card.category,
            foodPairings = array("food_pairings").mapNotNull { (it as? JsonPrimitive)?.contentOrNull },
            reference = string("reference"), pageUrl = string("page_url"),
            photoId = null, photoPath = null, instanceId = null,
            uncertain = (get("uncertain") as? JsonPrimitive)?.booleanOrNull ?: true,
            description = string("description"),
            dishes = array("dishes").mapNotNull { item ->
                val dish = item as? JsonObject ?: return@mapNotNull null
                val name = dish.string("name") ?: return@mapNotNull null
                com.aiweapps.winescan.domain.scan.model.WineDish(name, dish.string("image_url"))
            },
        )
    }

    private fun JsonObject.toStore(): com.aiweapps.winescan.domain.assistant.model.AssistantStore? {
        val id = int("id") ?: return null
        val address = string("address") ?: return null
        return com.aiweapps.winescan.domain.assistant.model.AssistantStore(
            id, string("name") ?: "Перекрёсток", address, string("mode") ?: "pickup", null,
            string("sap_id"), string("latitude")?.toDoubleOrNull(), string("longitude")?.toDoubleOrNull(),
            string("distance_metres")?.toDoubleOrNull(), string("chain") ?: "perekrestok", string("source_url"), string("updated_at"),
        )
    }
    private fun JsonObject.toProduct(): AssistantProduct? {
        val id = long("product_id")?.toString() ?: return null
        val title = string("title") ?: return null
        val lot = get("purchase_lot") as? JsonObject
        return AssistantProduct(
            id = id,
            title = title,
            pack = string("unit_name"),
            quantity = 1,
            unitPriceKopeks = long("price_kopeks"),
            lineTotalKopeks = null,
            url = string("url"),
            imageUrl = string("image_url"),
            availability = string("balance_state"),
            source = string("source"),
            retailSlug = string("slug"),
            retailPlu = string("plu"),
            primaryCategoryId = int("primary_category_id"),
            catalogPrimaryCategoryId = int("catalog_primary_category_id"),
            retailUnit = int("unit"),
            quantum = string("quantum")?.toDoubleOrNull(),
            quantumStep = string("quantum_step")?.toDoubleOrNull(),
            weight = string("weight")?.toDoubleOrNull(),
            volume = string("volume")?.toDoubleOrNull(),
            pricePerQuantumKopeks = long("price_per_quantum_kopeks"),
            priceBasis = string("price_basis") ?: "unknown",
            purchaseLotQuantity = lot?.string("quantity")?.toDoubleOrNull(),
            purchaseLotUnit = lot?.string("unit"),
            purchaseLotPriceKopeks = lot?.long("price_kopeks"),
        )
    }

    private fun JsonObject.string(key: String): String? =
        (get(key) as? JsonPrimitive)?.contentOrNull

    private fun JsonObject.long(key: String): Long? =
        (get(key) as? JsonPrimitive)?.longOrNull

    private fun JsonObject.int(key: String): Int? =
        (get(key) as? JsonPrimitive)?.intOrNull

    private fun JsonObject.array(key: String): JsonArray = get(key) as? JsonArray ?: JsonArray(emptyList())

    private fun <T> ApiResponse<T>.requireData(): T = when (this) {
        is ApiResponse.Success -> data
        is ApiResponse.Error -> {
            val detail = try {
                (kotlinx.serialization.json.Json.parseToJsonElement(debugMessage.orEmpty()) as? JsonObject)?.string("detail")
            } catch (_: Exception) { null }
            if (detail in setOf("challenge_or_block", "retailer_session_not_ready", "http_401", "http_403",
                "retailer_access_required", "retailer_needs_attention", "device_offline", "device_timeout", "device_id_required"))
                throw com.aiweapps.winescan.domain.assistant.repository.AssistantRetailAccessRequired()
            if (statusCode == 409) throw com.aiweapps.winescan.domain.assistant.repository.AssistantStoreContextChanged()
            throw AssistantServiceUnavailable()
        }
    }
}

internal class AssistantServiceUnavailable : Exception()
