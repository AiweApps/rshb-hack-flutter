package com.aiweapps.core.network

import com.aiweapps.core.error.AppError

sealed class ApiResponse<out T> {
    data class Success<T>(
        val data: T,
        val statusCode: Int
    ) : ApiResponse<T>()

    data class Error(
        val error: AppError,
        val statusCode: Int? = null,
        /** Raw server payload. Diagnostics and logs only — never render this to a user. */
        val debugMessage: String? = null,
        val throwable: Throwable? = null,
        /** The server's `Retry-After` header, in seconds, when it sent one. */
        val retryAfterSeconds: Long? = null,
    ) : ApiResponse<Nothing>()
}

inline fun <T> ApiResponse<T>.onSuccess(block: (T) -> Unit): ApiResponse<T> {
    if (this is ApiResponse.Success) block(data)
    return this
}

inline fun <T> ApiResponse<T>.onError(block: (ApiResponse.Error) -> Unit): ApiResponse<T> {
    if (this is ApiResponse.Error) block(this)
    return this
}

inline fun <T, R> ApiResponse<T>.map(transform: (T) -> R): ApiResponse<R> {
    return when (this) {
        is ApiResponse.Success -> ApiResponse.Success(transform(data), statusCode)
        is ApiResponse.Error -> this
    }
}
