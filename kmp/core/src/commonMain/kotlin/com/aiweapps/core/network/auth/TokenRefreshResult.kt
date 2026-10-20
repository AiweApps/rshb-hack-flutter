package com.aiweapps.core.network.auth

/**
 * Outcome of an attempt to exchange the refresh token for a fresh token pair.
 *
 * Telling [Unauthorized] apart from [Failed] is what keeps a flaky network from ending the
 * session: only the former means the stored tokens are worthless.
 */
sealed interface TokenRefreshResult {

    data class Success(val tokens: AuthTokens) : TokenRefreshResult

    /** Refresh token rejected by the server — the session is over. */
    data object Unauthorized : TokenRefreshResult

    /** Transient failure (no connectivity, 5xx) — keep the session and retry later. */
    data object Failed : TokenRefreshResult
}
