package com.aiweapps.winescan.data.status

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.domain.scan.model.CatalogSummary
import com.aiweapps.winescan.domain.scan.model.ServiceAvailability
import com.aiweapps.winescan.domain.scan.model.ServiceStatus
import com.aiweapps.winescan.domain.status.ServiceSnapshot
import com.aiweapps.winescan.testutil.FakeScanRepository
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class ServiceStatusMonitorImplTest {

    private val repository = FakeScanRepository().apply {
        status = ApiResponse.Success(ServiceStatus(backendReachable = true, profileMatch = true, catalog = CatalogSummary(cards = 2266)), statusCode = 200)
    }

    @Test
    fun twoListenersShareOneLoopAndOneRequestPerTick() = runTest {
        val monitor = ServiceStatusMonitorImpl(repository, backgroundScope, intervalMs = 1_000)
        val first = mutableListOf<ServiceSnapshot>()
        val second = mutableListOf<ServiceSnapshot>()
        monitor.snapshots.onEach { first += it }.launchIn(backgroundScope)
        monitor.snapshots.onEach { second += it }.launchIn(backgroundScope)
        runCurrent()

        assertEquals(1, repository.statusCalls, "the second listener does not start its own request")
        assertEquals(ServiceAvailability.READY, second.last().state.availability)
        assertEquals(2266, second.last().catalogCards)

        advanceTimeBy(1_001)
        assertEquals(2, repository.statusCalls)
    }

    @Test
    fun refreshNowWakesTheLoopWithoutWaitingForTheTick() = runTest {
        val monitor = ServiceStatusMonitorImpl(repository, backgroundScope, intervalMs = 60_000)
        monitor.snapshots.launchIn(backgroundScope)
        runCurrent()

        monitor.refreshNow()
        monitor.refreshNow()
        runCurrent()

        assertEquals(2, repository.statusCalls, "two quick requests collapse into one")
    }
}
