package com.aiweapps.core.network.auth

import io.ktor.client.HttpClient
import io.ktor.client.plugins.auth.authProvider
import io.ktor.client.plugins.auth.providers.BearerAuthProvider

/**
 * Drops the token pair the Bearer plugin keeps in memory.
 *
 * The plugin caches whatever [AuthProvider.loadTokens] returned and re-reads it only
 * after a failed refresh — so changes made to the persisted tokens (a logout, or a
 * login with a different account right after) stay invisible to it and the previous
 * session's access token keeps being sent. Call this whenever the stored token pair
 * is replaced or cleared.
 */
fun HttpClient.clearCachedAuthTokens() {
    authProvider<BearerAuthProvider>()?.clearToken()
}
