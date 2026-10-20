package com.aiweapps.winescan.data.scan.repository

import com.aiweapps.core.error.AppError
import com.aiweapps.core.files.FileStore
import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.data.scan.model.ApiErrorBodyDto
import com.aiweapps.winescan.data.scan.remote.ScanApi
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess
import com.aiweapps.winescan.domain.scan.model.ScanFailure
import com.aiweapps.winescan.domain.scan.model.ScanFailureKind
import com.aiweapps.winescan.domain.scan.model.ScanOutcome
import com.aiweapps.winescan.domain.scan.model.ServiceStatus
import com.aiweapps.winescan.domain.scan.model.ScanGeometryProgress
import com.aiweapps.winescan.domain.scan.repository.ScanRepository
import com.aiweapps.winescan.domain.session.GuestSession
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json

internal class ScanRepositoryImpl(
    private val api: ScanApi,
    private val fileStore: FileStore,
    private val session: GuestSession,
    private val apiBaseUrl: String,
    private val json: Json,
) : ScanRepository {

    override suspend fun recognize(photoPath: String, targetRoi: BottleBox?): ScanOutcome {
        return recognizeWithProgress(photoPath, targetRoi) {}
    }

    override suspend fun recognizeWithProgress(
        photoPath: String,
        targetRoi: BottleBox?,
        onProgress: (ScanGeometryProgress) -> Unit,
    ): ScanOutcome {
        // The file vanished between picking and uploading (the OS cleaned the cache, the
        // app was restored): a local failure, not a server one.
        val bytes = fileStore.readBytes(photoPath)
            ?: return ScanOutcome.Failed(
                ScanFailure(ScanFailureKind.PHOTO_OPEN, statusCode = null, retryable = false, retryAfterSeconds = null)
            )
        return when (val response = api.recognizeWithProgress(bytes, targetRoi, onProgress)) {
            is ApiResponse.Success -> ScanOutcome.Recognized(response.data.view)
            is ApiResponse.Error -> ScanOutcome.Failed(response.toFailure())
        }
    }

    override suspend fun status(): ApiResponse<ServiceStatus> = api.status()

    override suspend fun referenceAccess(): ReferenceAccess? =
        session.validToken()?.let { ReferenceAccess(baseUrl = apiBaseUrl, token = it) }

    /** The same classification the web UI does in `recognize()`. */
    private fun ApiResponse.Error.toFailure(): ScanFailure {
        val code = statusCode
        val kind = when (error) {
            AppError.Timeout -> ScanFailureKind.TIMEOUT
            AppError.Network -> ScanFailureKind.OFFLINE
            AppError.Unknown -> ScanFailureKind.NO_RESPONSE
            AppError.Unauthorized, is AppError.Server -> when {
                errorKey() == BAD_ROI_KEY -> ScanFailureKind.BAD_ROI
                else -> kindOf(code)
            }
        }
        val retryable = when (kind) {
            ScanFailureKind.BAD_ROI,
            ScanFailureKind.NO_ACCESS,
            ScanFailureKind.TOO_LARGE,
            ScanFailureKind.FORMAT -> false
            else -> true
        }
        return ScanFailure(kind = kind, statusCode = code, retryable = retryable, retryAfterSeconds = retryAfterSeconds)
    }

    private fun kindOf(code: Int?): ScanFailureKind = when (code) {
        null -> ScanFailureKind.NO_RESPONSE
        HTTP_UNAUTHORIZED -> ScanFailureKind.NO_ACCESS
        HTTP_TOO_LARGE -> ScanFailureKind.TOO_LARGE
        HTTP_UNSUPPORTED -> ScanFailureKind.FORMAT
        HTTP_UNPROCESSABLE -> ScanFailureKind.UNPROCESSED
        ScanFailure.HTTP_TOO_MANY -> ScanFailureKind.TOO_MANY
        HTTP_BAD_GATEWAY -> ScanFailureKind.SERVICE
        ScanFailure.HTTP_BUSY -> ScanFailureKind.BUSY
        HTTP_GATEWAY_TIMEOUT -> ScanFailureKind.TIMEOUT
        else -> ScanFailureKind.OTHER
    }

    /** Machine-readable code from the body (`{"error": "bad_roi"}`), when the backend sent one. */
    private fun ApiResponse.Error.errorKey(): String? {
        val body = debugMessage ?: return null
        return try {
            json.decodeFromString<ApiErrorBodyDto>(body).error
        } catch (_: SerializationException) {
            null
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private companion object {
        const val BAD_ROI_KEY = "bad_roi"
        const val HTTP_UNAUTHORIZED = 401
        const val HTTP_TOO_LARGE = 413
        const val HTTP_UNSUPPORTED = 415
        const val HTTP_UNPROCESSABLE = 422
        const val HTTP_BAD_GATEWAY = 502
        const val HTTP_GATEWAY_TIMEOUT = 504
    }
}
