package com.aiweapps.core.error

import kotlinx.serialization.Serializable

/**
 * Serializable because it reaches [com.aiweapps.core.components.model.ScreenState], which a
 * component may hand to its `stateKeeper` to survive process death.
 */
@Serializable
sealed class AppError {
    /** No connectivity, DNS failure, connection refused — the request never got out. */
    @Serializable
    data object Network : AppError()

    /** The request went out but no answer came back in time. */
    @Serializable
    data object Timeout : AppError()

    /** 401/403 — credentials are missing, invalid or expired. */
    @Serializable
    data object Unauthorized : AppError()

    /** Any other non-2xx response. */
    @Serializable
    data class Server(val code: Int) : AppError()

    /** Anything we could not classify. */
    @Serializable
    data object Unknown : AppError()
}
