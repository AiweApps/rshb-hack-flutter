package com.aiweapps.winescan.retail

import android.content.Context
import com.aiweapps.winescan.BuildConfig
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import org.json.JSONArray
import org.json.JSONObject

/**
 * Debug-only paired USB loopback transport for the existing local MCP server. It never opens a
 * listener, accepts a URL or JavaScript from the server, or includes WebView credentials in a
 * response. Pairing is read from no-backup app storage, provisioned outside the APK.
 */
class RetailBridgeClient(
    private val context: Context,
    private val adapter: PerekrestokWebViewAdapter,
    private val accounts: com.aiweapps.winescan.domain.assistant.repository.AssistantAccountRepository,
    private val assistantBaseUrl: String,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var polling: Job? = null

    fun start() {
        if (polling?.isActive == true) return
        polling = scope.launch {
            while (isActive && adapter.isForeground) {
                accounts.initialize()
                val identity = accounts.account.value
                val pairing = if (identity != null && !identity.expired) {
                    try {
                        val credentials = accounts.credentials()
                        if (credentials.subject != identity.subject) null
                        else Pairing(credentials.token, assistantBaseUrl.trimEnd('/'), credentials.deviceId)
                    } catch (cancelled: CancellationException) { throw cancelled }
                    catch (_: Exception) { null }
                } else if (identity == null && BuildConfig.DEBUG) readPairing() else null
                if (pairing != null) {
                    try {
                        val path = if (pairing.deviceId == null) "/next" else "/v1/device/commands?device_id=${pairing.deviceId}"
                        val command = http(pairing, path, null).optJSONObject("command")
                        if (command != null && adapter.isForeground) {
                            val result = execute(command, requireExpiry = pairing.deviceId != null)
                            // Do not submit a previous account's command after logout or account switch.
                            if (pairing.deviceId != null && accounts.account.value?.subject != identity?.subject) continue
                            val payload = if (pairing.deviceId == null) result.put("id", command.optString("id")) else
                                JSONObject().put("device_id", pairing.deviceId).put("id", command.optString("id")).put("result", result)
                            http(pairing, if (pairing.deviceId == null) "/result" else "/v1/device/results", payload)
                        }
                    } catch (_: RetailUnauthorized) {
                        // A delayed rejection of A must not revoke B after an account switch.
                        if (identity != null && pairing.deviceId != null) {
                            accounts.expireIfCurrent(identity.subject, pairing.token)
                        }
                    } catch (cancelled: CancellationException) {
                        throw cancelled
                    } catch (_: Exception) {
                        // The stdio MCP host may not be running. A later foreground poll reconnects.
                    }
                }
                delay(if (pairing == null) UNPAIRED_POLL_MS else POLL_MS)
            }
        }
    }

    fun stop() {
        polling?.cancel()
        polling = null
    }

    fun close() {
        stop()
        scope.cancel()
    }

    private fun readPairing(): Pairing? = try {
        val file = context.noBackupFilesDir.resolve(CONFIG_FILE)
        if (!file.isFile || file.length() !in 1..MAX_CONFIG_BYTES.toLong()) return null
        val config = JSONObject(file.readText())
        val token = config.optString("token")
        if (config.optString("url") != BRIDGE_ORIGIN || token.length < MIN_TOKEN_LENGTH ||
            token.length > MAX_TOKEN_LENGTH || !token.all {
                it in 'a'..'z' || it in 'A'..'Z' || it in '0'..'9' || it == '-' || it == '_'
            }
        ) null else Pairing(token)
    } catch (_: Exception) { null }

    private fun http(pairing: Pairing, path: String, body: JSONObject?): JSONObject {
        val connection = URL(pairing.origin + path).openConnection() as HttpURLConnection
        connection.instanceFollowRedirects = false
        connection.connectTimeout = CONNECT_TIMEOUT_MS
        connection.readTimeout = READ_TIMEOUT_MS
        connection.setRequestProperty("Authorization", "Bearer ${pairing.token}")
        pairing.deviceId?.let { connection.setRequestProperty("X-Device-Id", it) }
        try {
            if (body != null) {
                val payload = body.toString().toByteArray(Charsets.UTF_8)
                require(payload.size <= MAX_RESULT_BYTES)
                connection.requestMethod = "POST"
                connection.doOutput = true
                connection.setRequestProperty("Content-Type", "application/json")
                connection.outputStream.use { it.write(payload) }
            }
            if (connection.responseCode == 401) throw RetailUnauthorized()
            if (connection.responseCode != HttpURLConnection.HTTP_OK) throw IllegalStateException("bridge_http")
            val bytes = ByteArrayOutputStream()
            connection.inputStream.use { input ->
                val buffer = ByteArray(2048)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    bytes.write(buffer, 0, count)
                    if (bytes.size() > MAX_BRIDGE_REPLY_BYTES) throw IllegalStateException("bridge_reply_limit")
                }
            }
            return JSONObject(bytes.toString(Charsets.UTF_8.name()))
        } finally {
            connection.disconnect()
        }
    }

    private suspend fun execute(command: JSONObject, requireExpiry: Boolean): JSONObject {
        val expiry = command.optString("expires_at").takeIf { it.isNotBlank() }?.let {
            runCatching { java.time.Instant.parse(it).toEpochMilli() }.getOrNull()
        }
        if ((requireExpiry && expiry == null) || (expiry != null && expiry <= System.currentTimeMillis())) return failure("command_expired")
        val id = command.optString("id")
        if (runCatching { UUID.fromString(id) }.isFailure) return failure("invalid_arguments")
        val storeId = command.optInt("store_id", -1)
        if (storeId <= 0) return failure("invalid_arguments")
        val operation = command.optString("operation")
        val expectedSap = (command.opt("sap_id") as? String)?.takeIf { it.matches(Regex("[0-9]{1,12}")) }
        if (!command.isNull("sap_id") && expectedSap == null) return failure("invalid_arguments")
        if (requireExpiry && operation != "select_store" && expectedSap == null) return failure("invalid_arguments")
        expectedSap?.let { adapter.configureStore(storeId, it) }
        val result = try {
            withTimeout(COMMAND_TIMEOUT_MS) {
                when (operation) {
                    "select_store" -> adapter.selectStore(storeId, expectedSap)
                    "search_products" -> {
                        val query = command.optString("query")
                        val page = command.optInt("page", -1)
                        if (query.isBlank() || query.length > 100 || page !in 1..20) {
                            return@withTimeout RetailOperationResult.Failure(RetailFailure.InvalidRequest)
                        }
                        adapter.searchProducts(query, storeId, page)
                    }
                    "get_product" -> {
                        val productId = command.optInt("product_id", -1)
                        if (productId <= 0) return@withTimeout RetailOperationResult.Failure(RetailFailure.InvalidRequest)
                        adapter.getProduct(productId, storeId)
                    }
                    else -> RetailOperationResult.Failure(RetailFailure.InvalidRequest)
                }
            }
        } catch (_: kotlinx.coroutines.TimeoutCancellationException) {
            return failure("device_timeout")
        }
        return when (result) {
            is RetailOperationResult.Failure -> failure(when (val reason = result.reason) {
                RetailFailure.SessionNotReady -> "retailer_session_not_ready"
                RetailFailure.Offline -> "device_offline"
                RetailFailure.ChallengeOrBlocked -> "challenge_or_block"
                RetailFailure.StoreMismatch -> "store_mismatch"
                RetailFailure.Busy -> "device_busy"
                RetailFailure.InvalidRequest -> "invalid_arguments"
                RetailFailure.InvalidResponse -> "invalid_native_result"
                is RetailFailure.HttpFailure -> "http_${reason.status}"
            })
            is RetailOperationResult.Success -> boundedResponse(operation, result.snapshot, requireExpiry)
        }
    }

    private fun boundedResponse(operation: String, snapshot: RetailSnapshot, publicDevice: Boolean): JSONObject {
        val store = JSONObject().put("id", snapshot.storeId).put("sap_id", snapshot.sapId)
            .put("mode", snapshot.mode)
        val selected = JSONObject().put("operation", "select_store")
            .put("http_status", 200).put("shop_id", snapshot.storeId)
            .put("sap_id", snapshot.sapId).put("mode", snapshot.mode)
            .put("response_url", snapshot.selectResponseUrl ?: JSONObject.NULL)
            .put("request_method", snapshot.selectRequestMethod ?: JSONObject.NULL)
        val rows = JSONArray().put(selected)
        if (operation != "select_store") {
            val row = JSONObject().put("operation", operation).put("http_status", 200)
                .put("sap_id", snapshot.sapId)
            if (operation == "search_products") {
                row.put("store_verified", snapshot.storeBinding == RetailStoreBinding.VerifiedSearch)
                row.put("items", JSONArray().apply { snapshot.items.forEach { put(product(it)) } })
            } else {
                row.put("store_binding", "session_context")
                row.put("item", snapshot.items.firstOrNull()?.let(::product) ?: JSONObject.NULL)
            }
            rows.put(row)
        }
        return JSONObject().put("done", true).put("store", store).put("results", rows)
            .put("origin", snapshot.origin ?: JSONObject.NULL)
            .put("provenance", JSONObject().put("platform", "android").put("adapter", "android_webview")
                .put("transport", if (publicDevice) "https_device_poll" else "local_mcp")
                .put("contract_version", 1))
            .put("captured_at_ms", snapshot.checkedAt)
            .put("source", "perekrestok_android_webview")
            .put("transport", "native_WebView_evaluateJavascript")
            .put("webview_debugging", false)
    }

    private fun product(item: RetailProduct): JSONObject = JSONObject()
        .put("id", item.id)
        .put("title", item.title)
        .put("image_url", item.imageUrl ?: JSONObject.NULL)
        .put("price_kopeks", item.priceKopeks ?: JSONObject.NULL)
        .put("balance_state", item.balanceState ?: JSONObject.NULL)
        .put("slug", item.slug ?: JSONObject.NULL)
        .put("plu", item.plu ?: JSONObject.NULL)
        .put("primary_category_id", item.primaryCategoryId ?: JSONObject.NULL)
        .put("catalog_primary_category_id", item.catalogPrimaryCategoryId ?: JSONObject.NULL)
        .put("unit", item.unit ?: JSONObject.NULL)
        .put("unit_name", item.unitName ?: JSONObject.NULL)
        .put("quantum", item.quantum ?: JSONObject.NULL)
        .put("quantum_step", item.quantumStep ?: JSONObject.NULL)
        .put("weight", item.weight ?: JSONObject.NULL)
        .put("volume", item.volume ?: JSONObject.NULL)
        .put("price_per_quantum_kopeks", item.pricePerQuantumKopeks ?: JSONObject.NULL)
        .put("url", item.productUrl ?: JSONObject.NULL)

    private fun failure(code: String): JSONObject = JSONObject().put("error", code)

    private class RetailUnauthorized : Exception()
    private data class Pairing(val token: String, val origin: String = BRIDGE_ORIGIN, val deviceId: String? = null)

    private companion object {
        const val BRIDGE_ORIGIN = "http://127.0.0.1:18765"
        const val CONFIG_FILE = "bridge-config.json"
        const val MIN_TOKEN_LENGTH = 24
        const val MAX_TOKEN_LENGTH = 256
        const val MAX_CONFIG_BYTES = 2048
        const val MAX_RESULT_BYTES = 256_000
        const val MAX_BRIDGE_REPLY_BYTES = 65_536
        const val CONNECT_TIMEOUT_MS = 1500
        const val READ_TIMEOUT_MS = 2000
        const val COMMAND_TIMEOUT_MS = 20_000L
        const val POLL_MS = 700L
        const val UNPAIRED_POLL_MS = 2000L
    }
}
