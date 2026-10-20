package com.aiweapps.winescan.local

import android.content.Context
import android.util.Log
import com.aiweapps.winescan.domain.scan.repository.LocalScanEngine
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Platform execution only. Shared Kotlin owns the mode, request and saved history. */
class AndroidLocalScanEngine(context: Context) : LocalScanEngine {
    private val app = context.applicationContext
    private val worker = Executors.newSingleThreadExecutor()
    private val storage = File(app.filesDir, "local-scanner")
    private val models = File(storage, "models-v1")
    private val runtime = File(storage, "runtime-${AndroidLocalPins.BUNDLE_SHA.take(16)}")
    private val requests = ConcurrentHashMap<String, Request>()
    private val lifecycleLock = Any()
    private var activeRequest: Request? = null
    private val ready = AtomicBoolean(false)
    @Volatile private var phase = "preparing"
    @Volatile private var assetError: String? = null
    @Volatile private var observer: ((String) -> Unit)? = null
    @Volatile private var catalogue: JSONObject? = null
    @Volatile private var searchable: Set<String> = emptySet()
    private var backend: AndroidNativeInference? = null

    private class Request {
        val cancelled = AtomicBoolean(false)
        @Volatile var native: AndroidNativeInference? = null
    }

    init {
        worker.execute {
            try {
                installBundle()
                phase = "verifying"; notifyAssets()
                verifyModels()
                ready.set(true); phase = "ready"
            } catch (error: Exception) {
                phase = "not_installed"; assetError = "local_assets_missing_or_invalid"
                Log.w("WineLocal", "Assets unavailable: ${error.message}")
            }
            notifyAssets()
        }
    }

    override fun isAvailable(): Boolean = ready.get()
    override fun assetsStateJson(): String = JSONObject()
        .put("phase", phase).put("available", ready.get())
        .put("error", assetError ?: JSONObject.NULL).toString()
    override fun observeAssetsState(observer: (String) -> Unit) {
        this.observer = observer; observer(assetsStateJson())
    }
    private fun notifyAssets() { observer?.invoke(assetsStateJson()) }

    override fun statusJson(): String = JSONObject().put("ready", ready.get())
        .put("backend_reachable", ready.get()).put("profile_match", ready.get())
        .put("runtime_descriptor", "ondevice-android-full-policy-v1")
        .put("catalog", JSONObject().put("cards", catalogue()?.length() ?: 0)).toString()

    override fun referenceBaseUrl(): String = File(runtime, "catalog").toURI().toString().trimEnd('/') + "/"
    override fun wineJson(slug: String): String? = catalogue()?.optJSONObject(slug)?.toString()
    override fun searchJson(query: String): String {
        val terms = query.lowercase().split(Regex("""[^\p{L}\p{N}]+""")).filter { it.isNotBlank() }.take(12)
        if (terms.isEmpty()) return "[]"
        val cards = catalogue() ?: return "[]"
        val result = JSONArray()
        searchable.sorted().asSequence().mapNotNull { cards.optJSONObject(it) }.filter { card ->
            val text = listOf("title", "producer", "grapes", "region").joinToString(" ") { card.optString(it) }.lowercase()
            terms.all(text::contains)
        }.take(20).forEach(result::put)
        return result.toString()
    }
    @Synchronized private fun catalogue(): JSONObject? {
        if (catalogue == null && File(runtime, "catalog/cards.json").isFile) {
            catalogue = JSONObject(File(runtime, "catalog/cards.json").readText())
            val slugs = JSONArray(File(runtime, "catalog/searchable-slugs.json").readText())
            searchable = (0 until slugs.length()).map(slugs::getString).toSet()
        }
        return catalogue
    }

    override fun recognize(requestId: String, photoPath: String, roiJson: String?, completion: (String?, String?) -> Unit) =
        recognizeWithProgress(requestId, photoPath, roiJson, {}, completion)

    override fun recognizeWithProgress(requestId: String, photoPath: String, roiJson: String?,
                                      progress: (String) -> Unit, completion: (String?, String?) -> Unit) {
        val request = Request()
        require(requests.putIfAbsent(requestId, request) == null) { "Duplicate request ID" }
        worker.execute {
            var output: File? = null
            var memory: LocalMemorySampler? = null
            try {
                check(!request.cancelled.get()) { "cancelled" }
                check(ready.get()) { "local_assets_unavailable" }
                val photo = File(photoPath).canonicalFile
                check(photo.path.startsWith(app.dataDir.canonicalPath + "/")) { "Photo must belong to this application" }
                output = File(app.filesDir, "local-diagnostics/$requestId")
                output.mkdirs()
                memory = LocalMemorySampler(File(output, "memory.json.gz"))
                if (!Python.isStarted()) Python.start(AndroidPlatform(app))
                val native = backend ?: AndroidNativeInference(models.path, AndroidLocalPins.MODELS_SHA).also { backend = it }
                synchronized(lifecycleLock) {
                    request.native = native
                    activeRequest = request
                    native.beginRequest()
                    if (request.cancelled.get()) native.cancel()
                }
                native.setGeometryListener { if (!request.cancelled.get()) progress(it) }
                val result = Python.getInstance().getModule("android_application").callAttr("run",
                    File(runtime, "policy").path,
                    File(app.applicationInfo.nativeLibraryDir, "libwinegeometry.so").path,
                    AndroidLocalPins.MODELS_SHA, photo.path, roiJson ?: "null", output.path, native).toString()
                val outcome = JSONObject(result)
                if (request.cancelled.get()) return@execute
                check(outcome.optBoolean("ok") && outcome.optInt("HTTP", -1) == 0 &&
                    outcome.optBoolean("outer_request_wrappers_complete")) {
                    outcome.optString("error", "Full local policy failed")
                }
                completion(outcome.getJSONObject("view").toString(), null)
            } catch (error: Exception) {
                Log.e("WineLocal", "Full local request failed: ${error.message}", error)
                if (!request.cancelled.get()) completion(null, "local_recognition_failed")
            } finally {
                try { memory?.close() } catch (error: Exception) { Log.w("WineLocal", "Memory report failed", error) }
                request.native?.setGeometryListener(null)
                synchronized(lifecycleLock) {
                    if (activeRequest === request) activeRequest = null
                    requests.remove(requestId, request)
                }
                // Compressed source-bound evidence is retained only for this prototype audit.
                output?.let { File(it, "category").deleteRecursively() }
            }
        }
    }

    override fun cancel(requestId: String) {
        synchronized(lifecycleLock) {
            requests[requestId]?.let {
                it.cancelled.set(true)
                if (activeRequest === it) it.native?.cancel()
            }
        }
    }
    override fun releaseModels() {
        worker.execute {
            backend?.close(); backend = null
            if (Python.isStarted()) Python.getInstance().getModule("android_application").callAttr("release")
        }
    }

    private fun verifyModels() {
        check(AndroidLocalPins.MODELS_SHA.isNotBlank()) { "Model package has not been built" }
        val manifest = File(models, "manifest.json")
        check(sha(manifest) == AndroidLocalPins.MODELS_SHA) { "Android model manifest mismatch" }
        val pins = JSONObject(manifest.readText()).getJSONObject("files")
        for (name in pins.keys()) {
            val file = child(models, name)
            val pin = pins.getJSONObject(name)
            check(file.length() == pin.getLong("bytes") && sha(file) == pin.getString("sha256")) { "Model asset differs: $name" }
        }
    }

    private fun installBundle() {
        storage.mkdirs()
        val data = app.assets.open("bundle.json").use { it.readBytes() }
        check(digest(data) == AndroidLocalPins.BUNDLE_SHA) { "Policy bundle pin mismatch" }
        if (File(runtime, "verified.sha256").takeIf { it.isFile }?.readText() == AndroidLocalPins.BUNDLE_SHA) return
        val staging = File(storage, "runtime-${AndroidLocalPins.BUNDLE_SHA.take(16)}.staging")
        staging.deleteRecursively(); staging.mkdirs()
        try {
            val pins = JSONObject(String(data, Charsets.UTF_8)).getJSONObject("files")
            for (name in pins.keys()) {
                val destination = child(staging, name)
                val pin = pins.getJSONObject(name)
                destination.parentFile!!.mkdirs()
                app.assets.open(pin.getString("asset")).use { source -> destination.outputStream().use { source.copyTo(it) } }
                check(destination.length() == pin.getLong("bytes") && sha(destination) == pin.getString("sha256")) { "Policy source differs: $name" }
            }
            File(staging, "verified.sha256").writeText(AndroidLocalPins.BUNDLE_SHA)
            check(!runtime.exists() && staging.renameTo(runtime)) { "Policy install failed" }
        } finally { if (staging.exists()) staging.deleteRecursively() }
    }

    private fun child(root: File, name: String): File = File(root, name).canonicalFile.also {
        check(it.path.startsWith(root.canonicalPath + "/")) { "Unsafe asset path" }
    }
    private fun sha(file: File): String {
        val md = MessageDigest.getInstance("SHA-256")
        file.inputStream().buffered().use { stream ->
            val buffer = ByteArray(256 * 1024)
            while (true) { val count = stream.read(buffer); if (count < 0) break; md.update(buffer, 0, count) }
        }
        return md.digest().joinToString("") { "%02x".format(it) }
    }
    private fun digest(data: ByteArray): String = MessageDigest.getInstance("SHA-256").digest(data)
        .joinToString("") { "%02x".format(it) }
}
