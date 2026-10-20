package com.aiweapps.winescan.domain.scan

import com.aiweapps.core.error.AppError
import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.domain.scan.model.ServiceAvailability
import com.aiweapps.winescan.domain.scan.model.ServiceQueue
import com.aiweapps.winescan.domain.scan.model.ServiceState
import com.aiweapps.winescan.domain.scan.model.ServiceStatus
import kotlin.test.Test
import kotlin.test.assertEquals

/** The pill's reading of `/api/status`, the same table the web UI applies. */
class ServiceStateTest {

    @Test
    fun busyCarriesTheQueueLength() {
        val status = ServiceStatus(
            backendReachable = true,
            profileMatch = true,
            queue = ServiceQueue(inFlight = 1, waiting = 3),
        )

        val state = ServiceState.fromResponse(ApiResponse.Success(status, statusCode = 200))

        assertEquals(ServiceAvailability.BUSY, state.availability)
        assertEquals(3, state.waiting)
    }

    @Test
    fun unreachableBackendWinsOverEverythingElse() {
        val status = ServiceStatus(backendReachable = false, profileMatch = true, ready = true)

        val state = ServiceState.fromResponse(ApiResponse.Success(status, statusCode = 200))

        assertEquals(ServiceAvailability.DOWN, state.availability)
    }

    @Test
    fun throttlingAndSessionFailuresHaveTheirOwnPills() {
        val tooMany = ApiResponse.Error(AppError.Server(code = 429), statusCode = 429)
        val noSession = ApiResponse.Error(AppError.Unauthorized, statusCode = 401)
        val offline = ApiResponse.Error(AppError.Timeout)

        assertEquals(ServiceAvailability.RATE_LIMITED, ServiceState.fromResponse(tooMany).availability)
        assertEquals(ServiceAvailability.NO_ACCESS, ServiceState.fromResponse(noSession).availability)
        assertEquals(ServiceAvailability.OFFLINE, ServiceState.fromResponse(offline).availability)
    }
}
