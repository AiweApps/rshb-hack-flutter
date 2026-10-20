package com.aiweapps.core.network

import com.aiweapps.core.error.AppError
import io.ktor.client.call.body
import io.ktor.client.network.sockets.ConnectTimeoutException
import io.ktor.client.network.sockets.SocketTimeoutException
import io.ktor.client.plugins.HttpRequestTimeoutException
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpHeaders
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.io.IOException

/**
 * Runs [block] and classifies the outcome into an [AppError] the presentation layer can
 * render. The raw response body never leaves [ApiResponse.Error.debugMessage].
 *
 * The three Ktor timeout exceptions are subtypes of [IOException], so they are caught
 * before it: a timeout and a dead network are told apart on purpose, because the first
 * is worth retrying at once and the second is not.
 */
suspend inline fun <reified T> safeApiCall(
    block: () -> HttpResponse
): ApiResponse<T> {
    return try {
        val response = block()
        val statusCode = response.status.value

        if (statusCode in 200..299) {
            ApiResponse.Success(
                data = response.body<T>(),
                statusCode = statusCode
            )
        } else {
            ApiResponse.Error(
                error = httpStatusToAppError(statusCode),
                statusCode = statusCode,
                debugMessage = runCatching { response.bodyAsText() }.getOrNull(),
                retryAfterSeconds = response.headers[HttpHeaders.RetryAfter]?.trim()?.toLongOrNull(),
            )
        }
    } catch (e: CancellationException) {
        // Cancellation is not a failure: swallowing it would keep a caller running after
        // its scope died and let it write state into a component that is already gone.
        throw e
    } catch (e: HttpRequestTimeoutException) {
        timeoutError(e)
    } catch (e: ConnectTimeoutException) {
        timeoutError(e)
    } catch (e: SocketTimeoutException) {
        timeoutError(e)
    } catch (e: IOException) {
        ApiResponse.Error(
            error = AppError.Network,
            debugMessage = e.message,
            throwable = e,
        )
    } catch (e: Exception) {
        ApiResponse.Error(
            error = AppError.Unknown,
            debugMessage = e.message,
            throwable = e,
        )
    }
}

fun timeoutError(e: Exception): ApiResponse.Error = ApiResponse.Error(
    error = AppError.Timeout,
    debugMessage = e.message,
    throwable = e,
)

private const val HTTP_UNAUTHORIZED = 401
private const val HTTP_FORBIDDEN = 403

/**
 * Maps a non-2xx HTTP status onto the domain error model. Only 401/403 mean "the caller is
 * not allowed"; every other failing status is a server-side problem carrying its own code.
 */
fun httpStatusToAppError(statusCode: Int): AppError = when (statusCode) {
    HTTP_UNAUTHORIZED, HTTP_FORBIDDEN -> AppError.Unauthorized
    else -> AppError.Server(statusCode)
}
