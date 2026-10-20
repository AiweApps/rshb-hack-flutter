package com.aiweapps.winescan.local

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import com.chaquo.python.Python
import org.json.JSONArray
import org.json.JSONObject
import java.io.Closeable
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.MessageDigest
import java.util.concurrent.atomic.AtomicBoolean
import android.os.SystemClock

/** One serial request, pinned local models, no network and no alternate model downloads. */
class AndroidNativeInference(modelDirectory: String, manifestSHA: String) : Closeable {
    private val root = File(modelDirectory).canonicalFile
    private val env = OrtEnvironment.getEnvironment()
    private val specs: JSONObject
    private val sessions = mutableMapOf<String, OrtSession>()
    private var deadline = 0L
    private var remaining = 0
    private val cancelled = AtomicBoolean(false)
    @Volatile private var geometryListener: ((String) -> Unit)? = null
    private var closed = false

    init {
        require(manifestSHA.matches(Regex("[a-f0-9]{64}"))) { "Pinned manifest SHA required" }
        val manifest = File(root, "manifest.json")
        require(sha(manifest) == manifestSHA) { "Android model manifest changed" }
        specs = JSONObject(manifest.readText()).getJSONObject("models")
        // Verify every source before the first allocation. A file path alone is not admission.
        specs.keys().forEach { role ->
            val spec = specs.getJSONObject(role)
            val file = checkedFile(spec.optString("filename", spec.optString("path")))
            require(sha(file) == spec.getString("sha256")) { "Model SHA changed: $role" }
        }
    }

    @Synchronized fun beginRequest() {
        check(!closed) { "Native owner closed" }
        deadline = SystemClock.elapsedRealtime() + 180_000L
        remaining = 256
        cancelled.set(false)
    }

    fun cancel() { cancelled.set(true) }

    fun checkCancelled() {
        check(!closed && !cancelled.get() && !Thread.currentThread().isInterrupted) { "Native request cancelled" }
        check(deadline > 0 && SystemClock.elapsedRealtime() < deadline) { "Native request budget exhausted" }
    }

    fun setGeometryListener(listener: ((String) -> Unit)?) { geometryListener = listener }

    fun publishGeometry(json: String) { checkCancelled(); geometryListener?.invoke(json) }

    /** Input is packed little-endian float32, NCHW. Output carries real tensor shapes. */
    @Synchronized fun runTensor(role: String, inputBytes: ByteArray, shapeJson: String): String {
        checkCancelled()
        // OCR was one native callback on iOS: internal line forwards must not
        // consume the frozen detector/encoder256-forward allowance.
        if (!role.startsWith("ocr-")) {
            check(remaining > 0) { "Native request budget exhausted" }
            remaining -= 1
        }
        val dims = JSONArray(shapeJson)
        require(dims.length() in 1..4) { "Invalid tensor rank" }
        val shape = LongArray(dims.length()) { dims.getLong(it) }
        var count = 1L
        shape.forEach { require(it > 0 && it <= 16_000_000L); count = Math.multiplyExact(count, it) }
        require(count <= 16_000_000L && count * 4 == inputBytes.size.toLong()) { "Invalid tensor byte count" }
        val spec = specs.getJSONObject(if (specs.has(role)) role else role.replace('-', '_'))
        val session = sessions.getOrPut(role) {
            val options = OrtSession.SessionOptions()
            try {
                options.setIntraOpNumThreads(2)
                options.setInterOpNumThreads(1)
                options.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
                env.createSession(checkedFile(spec.optString("filename", spec.optString("path"))).absolutePath, options)
            } finally { options.close() }
        }
        val inputName = if (spec.get("input") is JSONObject) spec.getJSONObject("input").getString("name") else spec.getString("input")
        require(session.inputNames == setOf(inputName)) { "Model input contract changed: $role" }
        val floats = ByteBuffer.wrap(inputBytes).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
        OnnxTensor.createTensor(env, floats, shape).use { input ->
            session.run(mapOf(inputName to input)).use { result ->
                checkCancelled()
                val output = JSONObject()
                for (entry in result) {
                    val tensor = entry.value as? OnnxTensor ?: error("Non-tensor output: $role")
                    val buffer = tensor.floatBuffer
                    val packed = ByteBuffer.allocate(buffer.remaining() * 4).order(ByteOrder.LITTLE_ENDIAN)
                    while (buffer.hasRemaining()) {
                        val value = buffer.get()
                        require(value.isFinite()) { "Non-finite output: $role" }
                        packed.putFloat(value)
                    }
                    output.put(entry.key, JSONObject().put("shape", JSONArray(tensor.info.shape.toList()))
                        .put("data_base64", android.util.Base64.encodeToString(packed.array(), android.util.Base64.NO_WRAP)))
                }
                val inputSHA = MessageDigest.getInstance("SHA-256").digest(inputBytes)
                    .joinToString("") { "%02x".format(it.toInt() and 255) }
                return JSONObject().put("outputs", output).put("role", role)
                    .put("shape", JSONArray(shape.toList())).put("input_sha256", inputSHA).toString()
            }
        }
    }

    /** Same bound envelope as iOS. PIL owns exact resize/pad and native OCR owns OpenCV math. */
    @Synchronized fun invoke(rgb: ByteArray, width: Int, height: Int, operation: Int): String {
        return try {
            checkCancelled()
            Python.getInstance().getModule("android_native_ops")
                .callAttr("invoke", this, rgb, width, height, operation).toString()
        } catch (error: Exception) {
            JSONObject().put("ok", false).put("error", "${error.javaClass.simpleName}: ${error.message}").toString()
        }
    }

    fun modelDirectory(): String = root.absolutePath

    @Synchronized override fun close() {
        closed = true
        cancelled.set(true)
        sessions.values.forEach { it.close() }
        sessions.clear()
    }

    private fun checkedFile(relative: String): File {
        val file = File(root, relative).canonicalFile
        require(file.path.startsWith(root.path + File.separator) && file.isFile) { "Model outside owned directory" }
        return file
    }

    companion object {
        private fun sha(file: File): String {
            val digest = MessageDigest.getInstance("SHA-256")
            file.inputStream().use { stream ->
                val buffer = ByteArray(1024 * 1024)
                while (true) { val n = stream.read(buffer); if (n < 0) break; digest.update(buffer, 0, n) }
            }
            return digest.digest().joinToString("") { "%02x".format(it.toInt() and 255) }
        }
    }
}
