package com.aiweapps.core.network.auth

/**
 * Bridge between the network layer and whatever owns the auth session in the app.
 * Keeps `:core` free of any app-domain knowledge.
 */
interface AuthProvider {
    suspend fun loadTokens(): AuthTokens?

    /**
     * Tries to exchange the stored refresh token for a fresh pair.
     *
     * Implementations must report a transient failure as [TokenRefreshResult.Failed] and
     * reserve [TokenRefreshResult.Unauthorized] for a session that is genuinely over —
     * only the latter causes the stored tokens to be dropped.
     */
    suspend fun refreshTokens(): TokenRefreshResult

    /** Called when the refresh failed and the session can no longer be recovered. */
    suspend fun onUnauthorized()
}
