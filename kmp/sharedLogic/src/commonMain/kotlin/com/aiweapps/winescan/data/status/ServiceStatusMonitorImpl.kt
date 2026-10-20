package com.aiweapps.winescan.data.status

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.config.ApiConstants
import com.aiweapps.winescan.domain.scan.model.ServiceState
import com.aiweapps.winescan.domain.scan.model.ScannerBackend
import com.aiweapps.winescan.domain.scan.repository.ScanRepository
import com.aiweapps.winescan.domain.scan.repository.ScannerBackendControls
import com.aiweapps.winescan.domain.status.ServiceSnapshot
import com.aiweapps.winescan.domain.status.ServiceStatusMonitor
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.flow.shareIn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.withTimeoutOrNull

/**
 * A single polling loop shared by every collector: it starts with the first collector,
 * stops with the last one, and keeps the last snapshot for the next one to start from.
 * Requests are strictly sequential because there is only the one loop.
 */
internal class ServiceStatusMonitorImpl(
    private val scanRepository: ScanRepository,
    scope: CoroutineScope,
    private val intervalMs: Long = ApiConstants.STATUS_REFRESH_INTERVAL_MS,
    private val backendControls: ScannerBackendControls? = null,
) : ServiceStatusMonitor {

    // Conflated: any number of «refresh now» while a request runs collapse into one wake-up.
    private val refreshRequests = Channel<Unit>(Channel.CONFLATED)

    private var last = ServiceSnapshot()
    private var lastBackend: ScannerBackend? = null

    @OptIn(ExperimentalCoroutinesApi::class)
    override val snapshots: Flow<ServiceSnapshot> =
        (backendControls?.backendState?.map { it.selected }?.distinctUntilChanged() ?: flowOf(null)).flatMapLatest { backend ->
        if (lastBackend != backend) {
            last = ServiceSnapshot(catalogCards = last.catalogCards)
            lastBackend = backend
        }
        channelFlow {
        send(last)
        while (true) {
            last = read(last)
            // Whatever asked for a refresh while this request ran has its answer now.
            refreshRequests.tryReceive()
            send(last)
            withTimeoutOrNull(intervalMs) { refreshRequests.receive() }
        }
        }
    }.shareIn(scope, SharingStarted.WhileSubscribed(), replay = 1)

    override fun refreshNow() {
        refreshRequests.trySend(Unit)
    }

    private suspend fun read(previous: ServiceSnapshot): ServiceSnapshot {
        val response = scanRepository.status()
        return ServiceSnapshot(
            state = ServiceState.fromResponse(response),
            // A failed request does not erase what the catalogue size was.
            catalogCards = (response as? ApiResponse.Success)?.data?.catalog?.cards ?: previous.catalogCards,
        )
    }
}
