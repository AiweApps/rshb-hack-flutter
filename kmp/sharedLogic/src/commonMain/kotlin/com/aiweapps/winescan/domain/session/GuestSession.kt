package com.aiweapps.winescan.domain.session

/** The anonymous 24-hour session of the recognition API (docs/mobile-api.md). */
interface GuestSession {

    /**
     * A token valid for at least the configured margin, fetching a new one when needed.
     * `null` when no session could be opened (no network, service down).
     */
    suspend fun validToken(): String?

    /** Discard only the token actually rejected by the server; keep any newer concurrent token. */
    suspend fun invalidateRejectedToken(rejectedToken: String)
}
