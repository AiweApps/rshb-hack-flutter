package com.aiweapps.core.network

import com.aiweapps.core.network.auth.AuthProvider

data class NetworkConfig(
    val baseUrl: String,
    val defaultHeaders: Map<String, String> = emptyMap(),
    val connectTimeoutMs: Long = 30_000,
    val requestTimeoutMs: Long = 30_000,
    val socketTimeoutMs: Long = 30_000,
    val enableLogging: Boolean = false,
    val authProvider: AuthProvider? = null
)
