package com.aiweapps.winescan.domain.scan.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** The two product builds. Server permits an explicit local override; local is fixed. */
enum class ScannerBuild { SERVER, LOCAL }

enum class ScannerBackend { SERVER, LOCAL }

data class ScannerBackendState(
    val selected: ScannerBackend,
    val canChoose: Boolean,
    val localAvailable: Boolean,
    val localModel: LocalModelState = LocalModelState(),
)

@Serializable
data class LocalModelState(
    val phase: String = "not_installed",
    @SerialName("received_bytes") val receivedBytes: Long = 0,
    @SerialName("total_bytes") val totalBytes: Long = 0,
    val available: Boolean = false,
    val error: String? = null,
) {
    val isBusy: Boolean get() = phase in setOf("preparing", "downloading", "verifying", "installing")
}
