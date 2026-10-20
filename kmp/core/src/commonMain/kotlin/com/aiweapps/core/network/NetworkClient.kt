package com.aiweapps.core.network

import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.auth.Auth
import io.ktor.client.plugins.auth.providers.BearerTokens
import io.ktor.client.plugins.auth.providers.bearer
import com.aiweapps.core.network.auth.TokenRefreshResult
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.plugins.logging.LogLevel
import io.ktor.client.plugins.logging.Logger
import io.ktor.client.plugins.logging.Logging
import io.ktor.client.plugins.logging.SIMPLE
import io.ktor.client.request.header
import io.ktor.http.ContentType
import io.ktor.http.Url
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json

object NetworkClient {

    fun create(config: NetworkConfig): HttpClient {
        return HttpClient {
            defaultRequest {
                url(config.baseUrl)
                contentType(ContentType.Application.Json)
                config.defaultHeaders.forEach { (key, value) ->
                    header(key, value)
                }
            }

            install(ContentNegotiation) {
                json(Json {
                    ignoreUnknownKeys = true
                    isLenient = true
                    prettyPrint = false
                    encodeDefaults = true
                })
            }

            install(HttpTimeout) {
                connectTimeoutMillis = config.connectTimeoutMs
                requestTimeoutMillis = config.requestTimeoutMs
                socketTimeoutMillis = config.socketTimeoutMs
            }

            val authProvider = config.authProvider
            if (authProvider != null) {
                val authorizedHost = Url(config.baseUrl).host

                install(Auth) {
                    bearer {
                        loadTokens {
                            authProvider.loadTokens()?.let { tokens ->
                                BearerTokens(tokens.accessToken, tokens.refreshToken)
                            }
                        }

                        refreshTokens {
                            when (val result = authProvider.refreshTokens()) {
                                is TokenRefreshResult.Success -> BearerTokens(
                                    accessToken = result.tokens.accessToken,
                                    refreshToken = result.tokens.refreshToken,
                                )

                                // The refresh token itself was rejected; nothing left to
                                // recover, so the session is torn down.
                                TokenRefreshResult.Unauthorized -> {
                                    authProvider.onUnauthorized()
                                    null
                                }

                                // Transient failure: fail this request only. The stored
                                // session survives so a later attempt can still refresh.
                                TokenRefreshResult.Failed -> null
                            }
                        }

                        // Attach the token preemptively only to the API this client is configured
                        // for; anything pointing elsewhere must not receive it.
                        sendWithoutRequest { request -> request.url.host == authorizedHost }
                    }
                }
            }

            if (config.enableLogging) {
                install(Logging) {
                    // SIMPLE prints to stdout, which Android forwards to logcat; the default
                    // logger needs an SLF4J binding the app does not ship.
                    logger = Logger.SIMPLE
                    level = LogLevel.INFO
                }
            }

            expectSuccess = false
        }
    }
}
