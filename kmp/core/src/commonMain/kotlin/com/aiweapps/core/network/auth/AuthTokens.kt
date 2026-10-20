package com.aiweapps.core.network.auth

/**
 * [refreshToken] is optional: a session that is re-issued rather than refreshed (a guest
 * token, an API key) has none, and the Bearer plugin accepts that.
 */
data class AuthTokens(
    val accessToken: String,
    val refreshToken: String? = null,
)
