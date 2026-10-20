package com.aiweapps.winescan.retail

import android.app.Activity
import android.graphics.Bitmap
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import java.util.Locale
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.resume
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener

data class RetailProduct(
    val id: Int,
    val title: String,
    val priceKopeks: Int?,
    val balanceState: String?,
    val productUrl: String?,
    val unit: Int? = null,
    val unitName: String? = null,
    val quantum: Double? = null,
    val quantumStep: Double? = null,
    val weight: Double? = null,
    val volume: Double? = null,
    val pricePerQuantumKopeks: Int? = null,
    val slug: String? = null,
    val plu: String? = null,
    val primaryCategoryId: Int? = null,
    val catalogPrimaryCategoryId: Int? = null,
    val imageUrl: String? = null,
)

/** A product detail is bound to the selected WebView session; search also verifies response sapId. */
enum class RetailStoreBinding { SelectedStore, VerifiedSearch, SessionContext }

data class RetailSnapshot(
    val storeId: Int,
    val sapId: String,
    val mode: String,
    val items: List<RetailProduct>,
    val checkedAt: Long,
    val source: String = "perekrestok_webview",
    val storeBinding: RetailStoreBinding,
    val origin: String? = null,
    val selectResponseUrl: String? = null,
    val selectRequestMethod: String? = null,
)

sealed interface RetailOperationResult {
    data class Success(val snapshot: RetailSnapshot) : RetailOperationResult
    data class Failure(val reason: RetailFailure) : RetailOperationResult
}

sealed interface RetailFailure {
    data object SessionNotReady : RetailFailure
    data object Offline : RetailFailure
    data object ChallengeOrBlocked : RetailFailure
    data object StoreMismatch : RetailFailure
    data object Busy : RetailFailure
    data object InvalidRequest : RetailFailure
    data class HttpFailure(val status: Int) : RetailFailure
    data object InvalidResponse : RetailFailure
}

enum class RetailSessionStatus { NotOpened, Loading, Ready, NeedsAttention }

/**
 * Android transport for source-checked shops from the store directory. Its Activity owner keeps the
 * WebView alive while the user moves between app screens; the WebView profile stores cookies.
 * Only the selected product fields cross this boundary. No cookie, auth header or arbitrary
 * JavaScript enters a result. The user must call [openStore] to open the website.
 */
class PerekrestokWebViewAdapter(activity: Activity) {
    private val handler = Handler(Looper.getMainLooper())
    private val capturedHeaders = ConcurrentHashMap<String, String>()
    private val script: String = activity.assets.open("retail/command.js").bufferedReader().use { it.readText() }
    @Volatile private var pageGeneration = 0
    private var needsUserAttention = false
    private var active: Operation? = null
    private var closed = false
    private var foreground = false
    private val mutableStatus = MutableStateFlow(RetailSessionStatus.NotOpened)

    val status: StateFlow<RetailSessionStatus> = mutableStatus
    val isForeground: Boolean get() = foreground && !closed
    val webView: WebView = WebView(activity).apply {
        WebView.setWebContentsDebuggingEnabled(false)
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
        settings.allowFileAccess = false
        settings.allowContentAccess = false
        settings.javaScriptCanOpenWindowsAutomatically = false
        settings.setSupportMultipleWindows(false)
        settings.safeBrowsingEnabled = true
        CookieManager.getInstance().setAcceptCookie(true)
        CookieManager.getInstance().setAcceptThirdPartyCookies(this, false)
        webChromeClient = WebChromeClient()
        webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean =
                request.isForMainFrame && !isTrusted(request.url)

            override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? {
                if (isTrusted(request.url) && request.url.path?.startsWith(CUSTOMER_API_PATH) == true) {
                    val generation = pageGeneration
                    val headers = request.requestHeaders.mapNotNull { (name, value) ->
                        val key = name.lowercase(Locale.ROOT)
                        if (key == "auth" || key == "x-device-id") key to value else null
                    }.toMap()
                    handler.post {
                        if (!closed && pageGeneration == generation && isTrusted(url) && !needsUserAttention) {
                            capturedHeaders.putAll(headers)
                            if (capturedHeaders.containsKey("auth") && mutableStatus.value != RetailSessionStatus.Ready) {
                                mutableStatus.value = RetailSessionStatus.Ready
                            }
                        }
                    }
                }
                return null
            }

            override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
                pageGeneration++
                finish(RetailOperationResult.Failure(RetailFailure.SessionNotReady))
                // Main-frame navigation starts a new session-observation epoch. Old auth
                // headers must not make a challenge page look like a ready catalog.
                capturedHeaders.clear()
                needsUserAttention = false
                mutableStatus.value = RetailSessionStatus.Loading
            }

            override fun onPageFinished(view: WebView, url: String) {
                mutableStatus.value = if (!needsUserAttention && isTrusted(Uri.parse(url)) && capturedHeaders.containsKey("auth")) {
                    RetailSessionStatus.Ready
                } else {
                    RetailSessionStatus.NeedsAttention
                }
            }
        }
    }

    /** Show the actual retailer site on a user action, allowing login/location prompts there. */
    fun openStore() {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (closed) return
        if (!isTrusted(webView.url) || mutableStatus.value == RetailSessionStatus.NeedsAttention) {
            capturedHeaders.clear()
            webView.loadUrl(HOME_URL)
        }
    }

    /** A hidden view can serve the open app, but must not process work after it is backgrounded. */
    fun onResume() {
        foreground = true
    }

    fun onPause() {
        foreground = false
        finish(RetailOperationResult.Failure(RetailFailure.SessionNotReady))
    }

    private val sapIds = java.util.concurrent.ConcurrentHashMap(SAP_IDS)
    fun configureStore(storeId: Int, sapId: String) {
        if (storeId > 0 && sapId.length in 1..12 && sapId.all { it.isDigit() }) sapIds[storeId] = sapId
    }
    suspend fun selectStore(storeId: Int, expectedSapId: String? = sapIds[storeId]): RetailOperationResult =
        execute(Command.SelectStore(storeId, expectedSapId))

    suspend fun searchProducts(query: String, storeId: Int, page: Int = 1): RetailOperationResult =
        execute(Command.SearchProducts(storeId, sapIds[storeId], query, page))

    suspend fun getProduct(productId: Int, storeId: Int): RetailOperationResult =
        execute(Command.GetProduct(storeId, sapIds[storeId], productId))

    /** Call from Activity.onDestroy, after removing the WebView from its parent. */
    fun close() {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (closed) return
        closed = true
        finish(RetailOperationResult.Failure(RetailFailure.SessionNotReady))
        handler.removeCallbacksAndMessages(null)
        CookieManager.getInstance().flush()
        (webView.parent as? ViewGroup)?.removeView(webView)
        webView.destroy()
    }

    private suspend fun execute(command: Command): RetailOperationResult = withContext(Dispatchers.Main.immediate) {
        if (!command.valid()) return@withContext RetailOperationResult.Failure(RetailFailure.InvalidRequest)
        if (!closed && foreground && !needsUserAttention && mutableStatus.value == RetailSessionStatus.NotOpened) {
            // This runs for an actual foreground command, never for an idle bridge poll.
            // Cookies remain in WebView; capture fresh page headers after a cold start.
            mutableStatus.value = RetailSessionStatus.Loading
            webView.loadUrl(HOME_URL)
        }
        if (!closed && foreground && mutableStatus.value == RetailSessionStatus.Loading) {
            val readiness = withTimeoutOrNull(INITIAL_READY_TIMEOUT_MS) {
                // onPageFinished without headers is not a confirmed access failure: the
                // retailer can redirect and issue its authenticated XHR a moment later.
                while (!closed && foreground && !needsUserAttention && mutableStatus.value != RetailSessionStatus.Ready) {
                    delay(READINESS_CHECK_INTERVAL_MS)
                }
            }
            if (readiness == null && !closed && foreground && !needsUserAttention &&
                mutableStatus.value != RetailSessionStatus.Ready) {
                requireUserAttention()
            }
        }
        if (closed || !foreground || needsUserAttention || mutableStatus.value != RetailSessionStatus.Ready ||
            !isTrusted(webView.url) || !capturedHeaders.containsKey("auth")) {
            return@withContext RetailOperationResult.Failure(RetailFailure.SessionNotReady)
        }
        if (active != null) return@withContext RetailOperationResult.Failure(RetailFailure.Busy)

        suspendCancellableCoroutine<RetailOperationResult> { continuation ->
            val key = "__retail_" + UUID.randomUUID().toString().replace("-", "")
            val operation = Operation(key, pageGeneration, command, continuation)
            active = operation
            continuation.invokeOnCancellation {
                handler.post {
                    if (active === operation) {
                        clearPageOperation(operation)
                        active = null
                    }
                }
            }
            val headers = JSONObject().apply {
                capturedHeaders.forEach { (name, value) -> put(name, value) }
            }
            val javascript = "(() => { if (location.origin !== '$ORIGIN') return; " +
                "const KEY = ${JSONObject.quote(key)}; " +
                "const HEADERS = $headers; " +
                "const COMMAND = ${command.toJson()}; $script })()"
            webView.evaluateJavascript(javascript) {
                if (active === operation) poll(operation, 0)
            }
        }
    }

    private fun poll(operation: Operation, attempt: Int) {
        if (active !== operation) return
        if (pageGeneration != operation.generation || !isTrusted(webView.url)) {
            finish(RetailOperationResult.Failure(RetailFailure.SessionNotReady))
            return
        }
        if (attempt >= MAX_POLL_ATTEMPTS) {
            finish(RetailOperationResult.Failure(RetailFailure.Offline))
            return
        }
        webView.evaluateJavascript("JSON.stringify(window[${JSONObject.quote(operation.key)}] || null)") { raw ->
            if (active !== operation) return@evaluateJavascript
            try {
                val encoded = JSONTokener(raw).nextValue() as? String
                val result = encoded?.let { JSONTokener(it).nextValue() as? JSONObject }
                if (result?.optBoolean("done") == true) {
                    finish(parseResult(operation.command, result))
                } else {
                    handler.postDelayed({ poll(operation, attempt + 1) }, POLL_INTERVAL_MS)
                }
            } catch (_: Exception) {
                finish(RetailOperationResult.Failure(RetailFailure.InvalidResponse))
            }
        }
    }

    private fun parseResult(command: Command, result: JSONObject): RetailOperationResult {
        val error = result.optString("error")
        if (error == "challenge_or_block" || error == "http_401" || error == "http_403") {
            requireUserAttention()
        }
        if (error.isNotEmpty()) return RetailOperationResult.Failure(
            when {
                error == "challenge_or_block" -> RetailFailure.ChallengeOrBlocked
                error == "store_mismatch" || error == "store_selection_mismatch" ||
                    error == "store_mapping_mismatch" -> RetailFailure.StoreMismatch
                error == "timeout" -> RetailFailure.Offline
                error.startsWith("http_") -> error.removePrefix("http_").toIntOrNull()
                    ?.let(RetailFailure::HttpFailure) ?: RetailFailure.InvalidResponse
                else -> RetailFailure.InvalidResponse
            },
        )
        return try {
            val rows = result.getJSONArray("results")
            val selected = rows.getJSONObject(0)
            val actualSap = selected.getString("sap_id")
            val expectedPickupUrl = "$ORIGIN$CUSTOMER_API_PATH" + "1.4.1.0/delivery/mode/pickup/${command.storeId}"
            if (selected.getString("operation") != "select_store" || selected.getInt("http_status") != 200 ||
                selected.getInt("shop_id") != command.storeId || selected.getString("mode") != "catalog" ||
                !actualSap.matches(Regex("[0-9]{1,12}")) ||
                (command.expectedSapId != null && actualSap != command.expectedSapId) ||
                result.optString("origin") != ORIGIN || selected.optString("request_method") != "PUT" ||
                selected.optString("response_url") != expectedPickupUrl
            ) return RetailOperationResult.Failure(RetailFailure.StoreMismatch)
            val last = rows.getJSONObject(rows.length() - 1)
            if (last.getString("operation") != command.operation || last.getInt("http_status") != 200 ||
                last.getString("sap_id") != actualSap
            ) return RetailOperationResult.Failure(RetailFailure.StoreMismatch)
            // Discovery binds only after the actual pickup response matches this exact shop.
            configureStore(command.storeId, actualSap)
            val products = if (command is Command.SelectStore) emptyList() else readProducts(last.getJSONArray("items"))
            RetailOperationResult.Success(
                RetailSnapshot(
                    storeId = command.storeId,
                    sapId = actualSap,
                    mode = selected.getString("mode"),
                    items = products,
                    checkedAt = System.currentTimeMillis(),
                    storeBinding = when (command) {
                        is Command.SelectStore -> RetailStoreBinding.SelectedStore
                        is Command.SearchProducts -> RetailStoreBinding.VerifiedSearch
                        is Command.GetProduct -> RetailStoreBinding.SessionContext
                    },
                    origin = result.getString("origin"),
                    selectResponseUrl = selected.getString("response_url"),
                    selectRequestMethod = selected.getString("request_method"),
                ),
            )
        } catch (_: Exception) {
            RetailOperationResult.Failure(RetailFailure.InvalidResponse)
        }
    }

    private fun readProducts(array: JSONArray): List<RetailProduct> = buildList {
        if (array.length() > MAX_PRODUCTS) throw IllegalArgumentException("too_many_products")
        for (index in 0 until array.length()) {
            val value = array.getJSONObject(index)
            val id = value.getInt("id").also { require(it > 0) }
            val title = value.getString("title").also { require(it.isNotBlank() && it.length <= MAX_TITLE_LENGTH) }
            val price = if (value.isNull("price_kopeks")) null else value.getInt("price_kopeks").also { require(it >= 0) }
            val balance = value.optString("balance_state").takeIf { !value.isNull("balance_state") }
            val rawUrl = value.optString("url").takeIf { !value.isNull("url") }
            val productUrl = rawUrl?.takeIf { isTrusted(Uri.parse(it)) && Uri.parse(it).path?.startsWith("/cat/") == true }
            add(RetailProduct(
                id, title, price, balance, productUrl,
                unit = value.optionalNumber("unit")?.takeIf { it % 1.0 == 0.0 }?.toInt(),
                unitName = (value.opt("unit_name") as? String)?.take(40),
                quantum = value.optionalNumber("quantum"),
                quantumStep = value.optionalNumber("quantum_step"),
                weight = value.optionalNumber("weight"),
                volume = value.optionalNumber("volume"),
                pricePerQuantumKopeks = value.optionalNumber("price_per_quantum_kopeks")
                    ?.takeIf { it % 1.0 == 0.0 }?.toInt(),
                slug = (value.opt("slug") as? String)?.take(500),
                plu = (value.opt("plu") as? String)?.take(100),
                primaryCategoryId = value.optionalNumber("primary_category_id")?.takeIf { it % 1.0 == 0.0 }?.toInt(),
                catalogPrimaryCategoryId = value.optionalNumber("catalog_primary_category_id")?.takeIf { it % 1.0 == 0.0 }?.toInt(),
                imageUrl = (value.opt("image_url") as? String)?.takeIf { it.length <= MAX_IMAGE_URL_LENGTH },
            ))
        }
    }

    private fun JSONObject.optionalNumber(key: String): Double? =
        (opt(key) as? Number)?.toDouble()?.takeIf { it.isFinite() && it in 0.0..1_000_000_000.0 }

    private fun requireUserAttention() {
        capturedHeaders.clear()
        needsUserAttention = true
        mutableStatus.value = RetailSessionStatus.NeedsAttention
    }

    private fun finish(result: RetailOperationResult) {
        val operation = active ?: return
        active = null
        clearPageOperation(operation)
        if (operation.continuation.isActive) operation.continuation.resume(result)
    }

    private fun clearPageOperation(operation: Operation) {
        if (isTrusted(webView.url) && pageGeneration == operation.generation) {
            val key = JSONObject.quote(operation.key)
            webView.evaluateJavascript("window[$key]?.controller?.abort(); delete window[$key]", null)
        }
    }

    private fun isTrusted(url: String?): Boolean = url?.let { isTrusted(Uri.parse(it)) } ?: false

    private fun isTrusted(uri: Uri): Boolean = uri.scheme == "https" && uri.host == HOST &&
        (uri.port == -1 || uri.port == 443)

    private data class Operation(
        val key: String,
        val generation: Int,
        val command: Command,
        val continuation: kotlinx.coroutines.CancellableContinuation<RetailOperationResult>,
    )

    private sealed class Command(val storeId: Int, val expectedSapId: String?, val operation: String) {
        class SelectStore(storeId: Int, sapId: String?) : Command(storeId, sapId, "select_store")
        class SearchProducts(storeId: Int, sapId: String?, val query: String, val page: Int) : Command(storeId, sapId, "search_products")
        class GetProduct(storeId: Int, sapId: String?, val productId: Int) : Command(storeId, sapId, "get_product")

        fun valid(): Boolean = storeId > 0 && when (this) {
            is SelectStore -> expectedSapId == null || expectedSapId.matches(Regex("[0-9]{1,12}"))
            is SearchProducts -> expectedSapId?.matches(Regex("[0-9]{1,12}")) == true &&
                query.isNotBlank() && query.length <= MAX_QUERY_LENGTH && page in 1..20
            is GetProduct -> expectedSapId?.matches(Regex("[0-9]{1,12}")) == true && productId > 0
        }

        fun toJson(): JSONObject = JSONObject().apply {
            put("operation", operation)
            put("store_id", storeId)
            put("sap_id", expectedSapId)
            when (this@Command) {
                is SelectStore -> Unit
                is SearchProducts -> {
                    put("query", query)
                    put("page", page)
                }
                is GetProduct -> put("product_id", productId)
            }
        }
    }

    private companion object {
        const val HOST = "www.perekrestok.ru"
        const val ORIGIN = "https://www.perekrestok.ru"
        const val HOME_URL = "$ORIGIN/"
        const val CUSTOMER_API_PATH = "/api/customer/"
        const val INITIAL_READY_TIMEOUT_MS = 10_000L
        const val READINESS_CHECK_INTERVAL_MS = 50L
        const val POLL_INTERVAL_MS = 400L
        const val MAX_POLL_ATTEMPTS = 100
        const val MAX_PRODUCTS = 48
        const val MAX_TITLE_LENGTH = 500
        const val MAX_IMAGE_URL_LENGTH = 2000
        const val MAX_QUERY_LENGTH = 100
        val SAP_IDS = mapOf(817 to "2362", 814 to "2441")
    }
}
