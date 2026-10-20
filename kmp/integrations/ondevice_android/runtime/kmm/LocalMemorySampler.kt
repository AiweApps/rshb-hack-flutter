package com.aiweapps.winescan.local

import android.os.Debug
import android.os.SystemClock
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.zip.GZIPOutputStream

/** Measurements for a manually operated prototype scan, including native allocations. */
internal class LocalMemorySampler(private val output: File) : AutoCloseable {
    private val started = SystemClock.elapsedRealtime()
    private val rows = mutableListOf<JSONObject>()
    private val timer = Executors.newSingleThreadScheduledExecutor()

    init {
        sample()
        timer.scheduleAtFixedRate({ sample() }, 1, 1, TimeUnit.SECONDS)
    }

    @Synchronized private fun sample() {
        try {
            val status = File("/proc/self/status").readLines().associate { line ->
                line.substringBefore(':') to line.substringAfter(':').trim()
            }
            fun kb(name: String) = status[name]?.substringBefore(' ')?.toLongOrNull()
            val heap = Runtime.getRuntime()
            rows += JSONObject().put("elapsed_ms", SystemClock.elapsedRealtime() - started)
                .put("pss_kib", Debug.getPss()).put("rss_kib", kb("VmRSS") ?: JSONObject.NULL)
                .put("process_historical_hwm_kib", kb("VmHWM") ?: JSONObject.NULL)
                .put("java_heap_bytes", heap.totalMemory() - heap.freeMemory())
        } catch (error: Exception) {
            rows += JSONObject().put("elapsed_ms", SystemClock.elapsedRealtime() - started)
                .put("measurement_error", error.javaClass.simpleName)
        }
    }

    override fun close() {
        timer.shutdown()
        timer.awaitTermination(3, TimeUnit.SECONDS)
        synchronized(this) {
            sample()
            val report = JSONObject().put("kind", "android-manual-scan-memory-v1")
                .put("sample_interval_ms", 1000).put("not_an_upper_bound", true)
                .put("samples", JSONArray(rows))
            output.parentFile!!.mkdirs()
            GZIPOutputStream(output.outputStream()).bufferedWriter().use { it.write(report.toString()) }
        }
    }
}
