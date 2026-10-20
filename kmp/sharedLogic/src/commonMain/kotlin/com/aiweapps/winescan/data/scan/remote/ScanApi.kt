package com.aiweapps.winescan.data.scan.remote

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.core.network.safeApiCall
import com.aiweapps.winescan.config.ApiConstants
import com.aiweapps.winescan.data.scan.model.RecognizeResponseDto
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.ServiceStatus
import io.ktor.client.HttpClient
import io.ktor.client.plugins.timeout
import io.ktor.client.request.forms.formData
import io.ktor.client.request.forms.submitFormWithBinaryData
import io.ktor.client.request.get
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.http.contentType
import com.aiweapps.core.error.AppError
import com.aiweapps.core.network.httpStatusToAppError
import com.aiweapps.core.network.timeoutError
import com.aiweapps.winescan.domain.scan.model.ScanGeometryProgress
import io.ktor.client.call.body
import io.ktor.client.request.preparePost
import io.ktor.client.request.setBody
import io.ktor.client.request.header
import io.ktor.client.request.forms.MultiPartFormDataContent
import io.ktor.client.statement.bodyAsChannel
import io.ktor.client.statement.bodyAsText
import io.ktor.client.plugins.HttpRequestTimeoutException
import io.ktor.client.network.sockets.ConnectTimeoutException
import io.ktor.client.network.sockets.SocketTimeoutException
import io.ktor.utils.io.readUTF8Line
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.io.IOException
import kotlin.coroutines.cancellation.CancellationException

/** Must be constructed with the *authorized* client: every call carries the guest Bearer. */
internal class ScanApi(private val httpClient: HttpClient, private val json: Json) {

    /** A single upload. Older servers may return their ordinary JSON to this Accept header. */
    suspend fun recognizeWithProgress(
        imageBytes: ByteArray,
        targetRoi: BottleBox?,
        onProgress: (ScanGeometryProgress) -> Unit,
    ): ApiResponse<RecognizeResponseDto> = try {
        httpClient.preparePost(ScanRoutes.RECOGNIZE) {
            header(HttpHeaders.Accept, "text/event-stream")
            val multipart = MultiPartFormDataContent(formData {
                append(ApiConstants.IMAGE_FIELD, imageBytes, Headers.build {
                    append(HttpHeaders.ContentType, ApiConstants.UPLOAD_MIME_TYPE)
                    append(HttpHeaders.ContentDisposition, "filename=\"${ApiConstants.UPLOAD_FILE_NAME}\"")
                })
                targetRoi?.let { append(ApiConstants.TARGET_ROI_FIELD, it.toJson().toString()) }
            })
            contentType(multipart.contentType)
            setBody(multipart)
            timeout {
                requestTimeoutMillis = ApiConstants.RECOGNIZE_TIMEOUT_MS
                socketTimeoutMillis = ApiConstants.RECOGNIZE_TIMEOUT_MS
            }
        }.execute { response ->
            val status = response.status.value
            if (status !in 200..299) {
                return@execute ApiResponse.Error(httpStatusToAppError(status), status,
                    debugMessage = response.bodyAsText(),
                    retryAfterSeconds = response.headers[HttpHeaders.RetryAfter]?.toLongOrNull())
            }
            if (response.headers[HttpHeaders.ContentType]?.contains("text/event-stream") != true) {
                return@execute ApiResponse.Success(response.body<RecognizeResponseDto>(), status)
            }
            val channel = response.bodyAsChannel()
            var kind: String? = null
            var data: String? = null
            var terminal: ApiResponse<RecognizeResponseDto>? = null
            while (terminal == null) {
                val line = channel.readUTF8Line(8 * 1024 * 1024) ?: break
                when {
                    line.startsWith(":") -> Unit
                    line.startsWith("event: ") -> kind = line.substring(7)
                    line.startsWith("data: ") -> {
                        check(data == null) { "Unexpected multiline scan event" }
                        data = line.substring(6)
                    }
                    line.isEmpty() && data != null -> {
                        val payload = data
                        when (kind) {
                            "geometry" -> json.decodeFromString<ScanGeometryProgress>(payload).let {
                                check(it.isValid) { "Invalid scan geometry" }
                                onProgress(it)
                            }
                            "result" -> terminal = ApiResponse.Success(json.decodeFromString<RecognizeResponseDto>(payload), status)
                            "error" -> {
                                val body = json.parseToJsonElement(payload).jsonObject
                                val code = body["status"]?.jsonPrimitive?.intOrNull ?: 502
                                terminal = ApiResponse.Error(httpStatusToAppError(code), code,
                                    debugMessage = payload,
                                    retryAfterSeconds = body["retry_after"]?.jsonPrimitive?.longOrNull)
                            }
                            else -> error("Unknown scan event")
                        }
                        kind = null
                        data = null
                    }
                }
            }
            terminal ?: ApiResponse.Error(AppError.Network, debugMessage = "Recognition stream ended without result")
        }
    } catch (error: CancellationException) {
        throw error
    } catch (error: HttpRequestTimeoutException) {
        timeoutError(error)
    } catch (error: ConnectTimeoutException) {
        timeoutError(error)
    } catch (error: SocketTimeoutException) {
        timeoutError(error)
    } catch (error: IOException) {
        ApiResponse.Error(AppError.Network, debugMessage = error.message, throwable = error)
    } catch (error: Exception) {
        ApiResponse.Error(AppError.Unknown, debugMessage = error.message, throwable = error)
    }

    suspend fun recognize(imageBytes: ByteArray, targetRoi: BottleBox?): ApiResponse<RecognizeResponseDto> =
        safeApiCall {
            httpClient.submitFormWithBinaryData(
                url = ScanRoutes.RECOGNIZE,
                formData = formData {
                    append(
                        key = ApiConstants.IMAGE_FIELD,
                        value = imageBytes,
                        headers = Headers.build {
                            append(HttpHeaders.ContentType, ApiConstants.UPLOAD_MIME_TYPE)
                            append(
                                HttpHeaders.ContentDisposition,
                                "filename=\"${ApiConstants.UPLOAD_FILE_NAME}\"",
                            )
                        },
                    )
                    if (targetRoi != null) {
                        append(ApiConstants.TARGET_ROI_FIELD, targetRoi.toJson().toString())
                    }
                },
            ) {
                timeout {
                    requestTimeoutMillis = ApiConstants.RECOGNIZE_TIMEOUT_MS
                    socketTimeoutMillis = ApiConstants.RECOGNIZE_TIMEOUT_MS
                }
            }
        }

    suspend fun status(): ApiResponse<ServiceStatus> = safeApiCall {
        httpClient.get(ScanRoutes.STATUS)
    }
}
