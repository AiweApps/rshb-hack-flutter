package com.aiweapps.winescan.domain.scan.model

import kotlinx.serialization.Serializable

/**
 * Why a recognition request produced no answer, as the user is told about it. The kinds
 * follow the web UI's table of titles by HTTP status.
 */
enum class ScanFailureKind {
    NO_ACCESS,
    TOO_LARGE,
    FORMAT,
    UNPROCESSED,
    BAD_ROI,
    TOO_MANY,
    SERVICE,
    BUSY,
    TIMEOUT,
    NO_RESPONSE,
    OFFLINE,
    PHOTO_OPEN,
    OTHER,
}

@Serializable
data class ScanFailure(
    val kind: ScanFailureKind,
    val statusCode: Int?,
    /** Whether "retry" makes sense: a rejected file or frame will be rejected again. */
    val retryable: Boolean,
    /** When the backend asked to come back later (429, busy 503), in seconds. */
    val retryAfterSeconds: Long?,
) {
    /** The two answers that say "wait and ask again" rather than "this will not work". */
    val isThrottled: Boolean
        get() = statusCode == HTTP_TOO_MANY || (statusCode == HTTP_BUSY && retryAfterSeconds != null)

    companion object {
        const val HTTP_TOO_MANY = 429
        const val HTTP_BUSY = 503
    }
}

/** What a recognition request came back with: an answer, or why there is none. */
sealed interface ScanOutcome {
    data class Recognized(val view: RecognitionView) : ScanOutcome
    data class Failed(val failure: ScanFailure) : ScanOutcome
}
