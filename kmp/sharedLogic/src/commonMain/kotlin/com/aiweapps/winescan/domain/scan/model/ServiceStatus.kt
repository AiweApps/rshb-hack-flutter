package com.aiweapps.winescan.domain.scan.model

import com.aiweapps.core.error.AppError
import com.aiweapps.core.network.ApiResponse
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** `GET /api/status`: only the fields the app acts on. */
@Serializable
data class ServiceStatus(
    @SerialName("dev_mode") val devMode: Boolean = false,
    val message: String? = null,
    @SerialName("backend_reachable") val backendReachable: Boolean = false,
    @SerialName("profile_match") val profileMatch: Boolean = false,
    val ready: Boolean = false,
    val queue: ServiceQueue? = null,
    val limits: ServiceLimits? = null,
    @SerialName("expected_profile") val expectedProfile: String? = null,
    @SerialName("runtime_descriptor") val runtimeDescriptor: String? = null,
    val catalog: CatalogSummary? = null,
) {
    val isBusy: Boolean get() = (queue?.inFlight ?: 0) > 0

    val waiting: Int get() = queue?.waiting ?: 0
}

@Serializable
data class ServiceQueue(
    @SerialName("in_flight") val inFlight: Int = 0,
    val waiting: Int = 0,
)

@Serializable
data class ServiceLimits(
    @SerialName("max_bytes") val maxBytes: Long? = null,
    @SerialName("max_pixels") val maxPixels: Long? = null,
)

@Serializable
data class CatalogSummary(val cards: Int? = null)

/** What the status pill says about the recognition service. */
enum class ServiceAvailability {
    CHECKING,
    READY,
    BUSY,
    DOWN,
    UNAVAILABLE,
    NO_ACCESS,
    RATE_LIMITED,
    OFFLINE,
    DEV;

    val canRecognize: Boolean get() = this == READY || this == BUSY
}

/** The pill's content: the kind plus, when busy, how many wait ahead. */
@Serializable
data class ServiceState(
    val availability: ServiceAvailability,
    val waiting: Int = 0,
) {
    companion object {
        val checking = ServiceState(ServiceAvailability.CHECKING)

        private const val HTTP_UNAUTHORIZED = 401
        private const val HTTP_TOO_MANY = 429

        /** The same reading of the status the web UI does (`refreshStatus`). */
        fun fromResponse(response: ApiResponse<ServiceStatus>): ServiceState = when (response) {
            is ApiResponse.Success -> fromStatus(response.data)
            is ApiResponse.Error -> ServiceState(fromError(response))
        }

        private fun fromStatus(status: ServiceStatus): ServiceState = when {
            status.devMode -> ServiceState(ServiceAvailability.DEV)
            !status.backendReachable -> ServiceState(ServiceAvailability.DOWN)
            !status.profileMatch -> ServiceState(ServiceAvailability.UNAVAILABLE)
            status.isBusy -> ServiceState(ServiceAvailability.BUSY, waiting = status.waiting)
            else -> ServiceState(ServiceAvailability.READY)
        }

        private fun fromError(error: ApiResponse.Error): ServiceAvailability = when (error.error) {
            AppError.Network, AppError.Timeout -> ServiceAvailability.OFFLINE
            AppError.Unauthorized -> ServiceAvailability.NO_ACCESS
            is AppError.Server -> when (error.statusCode) {
                HTTP_UNAUTHORIZED -> ServiceAvailability.NO_ACCESS
                HTTP_TOO_MANY -> ServiceAvailability.RATE_LIMITED
                else -> ServiceAvailability.UNAVAILABLE
            }
            AppError.Unknown -> ServiceAvailability.UNAVAILABLE
        }
    }
}
