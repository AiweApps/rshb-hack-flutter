package com.aiweapps.core.network

import com.aiweapps.core.error.AppError
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import io.ktor.serialization.kotlinx.json.json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Reference test for the network boundary. The contract worth pinning down is not "it
 * parses JSON" but the classification: which HTTP outcome becomes which [AppError], and
 * the promise that a raw server payload never leaves [ApiResponse.Error.debugMessage].
 */
class SafeApiCallTest {

    @Serializable
    private data class Payload(val name: String)

    @Test
    fun successReturnsParsedBody() = runTest {
        val client = clientRespondingWith(HttpStatusCode.OK, """{"name":"Rick"}""")

        val response = safeApiCall<Payload> { client.get("/character") }

        val success = assertIs<ApiResponse.Success<Payload>>(response)
        assertEquals("Rick", success.data.name)
        assertEquals(200, success.statusCode)
    }

    @Test
    fun unauthorizedIsClassifiedFromStatus() = runTest {
        val client = clientRespondingWith(HttpStatusCode.Unauthorized, """{"message":"nope"}""")

        val response = safeApiCall<Payload> { client.get("/character") }

        val error = assertIs<ApiResponse.Error>(response)
        assertEquals(AppError.Unauthorized, error.error)
        assertEquals(401, error.statusCode)
    }

    @Test
    fun serverErrorKeepsItsStatusCode() = runTest {
        val client = clientRespondingWith(HttpStatusCode.InternalServerError, "boom")

        val response = safeApiCall<Payload> { client.get("/character") }

        val error = assertIs<ApiResponse.Error>(response)
        assertEquals(AppError.Server(500), error.error)
    }

    @Test
    fun rawServerBodyStaysInTheDebugField() = runTest {
        val body = """{"internal":"stack trace the user must never see"}"""
        val client = clientRespondingWith(HttpStatusCode.BadRequest, body)

        val response = safeApiCall<Payload> { client.get("/character") }

        val error = assertIs<ApiResponse.Error>(response)
        assertEquals(body, error.debugMessage)
        // AppError is what the UI renders, and it carries nothing but a status code.
        assertEquals(AppError.Server(400), error.error)
    }

    @Test
    fun transportFailureBecomesNetworkError() = runTest {
        val client = HttpClient(MockEngine { throw IOException("connection reset") }) {
            expectSuccess = false
        }

        val response = safeApiCall<Payload> { client.get("/character") }

        val error = assertIs<ApiResponse.Error>(response)
        assertEquals(AppError.Network, error.error)
        assertNull(error.statusCode)
    }

    @Test
    fun unparseableBodyIsNotReportedAsNetworkTrouble() = runTest {
        val client = clientRespondingWith(HttpStatusCode.OK, """{"unexpected":true}""")

        val response = safeApiCall<Payload> { client.get("/character") }

        val error = assertIs<ApiResponse.Error>(response)
        // Telling the user "check your connection" when the server changed its contract
        // sends them chasing the wrong problem.
        assertEquals(AppError.Unknown, error.error)
        assertTrue(error.throwable != null)
    }

    @Test
    fun statusMappingCoversTheAuthorizationPair() {
        assertEquals(AppError.Unauthorized, httpStatusToAppError(401))
        assertEquals(AppError.Unauthorized, httpStatusToAppError(403))
        assertEquals(AppError.Server(418), httpStatusToAppError(418))
    }

    private fun clientRespondingWith(status: HttpStatusCode, body: String): HttpClient =
        HttpClient(
            MockEngine {
                respond(
                    content = body,
                    status = status,
                    headers = headersOf(HttpHeaders.ContentType, ContentType.Application.Json.toString()),
                )
            }
        ) {
            install(ContentNegotiation) {
                json(Json { ignoreUnknownKeys = true })
            }
            expectSuccess = false
        }
}
