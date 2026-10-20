package com.aiweapps.winescan.domain.status

import com.aiweapps.winescan.domain.scan.model.ServiceState
import kotlinx.coroutines.flow.Flow

/** What every screen showing the service status draws: the pill and the catalogue size. */
data class ServiceSnapshot(
    val state: ServiceState = ServiceState.checking,
    /** Size of the wine catalogue, kept from the last answer that told it. */
    val catalogCards: Int? = null,
)

/**
 * The one place that asks the service for its status.
 *
 * Polling runs only while somebody collects [snapshots] (the scanner tab, the settings tab,
 * each while it is on screen) and one request at a time: every collector shares the same
 * loop, so two visible screens never double the traffic and never race each other.
 */
interface ServiceStatusMonitor {

    /** The latest snapshot first, then a new one after every request. */
    val snapshots: Flow<ServiceSnapshot>

    /**
     * Asks for a fresh reading now instead of at the next tick, e.g. when the user opens
     * the status details. Coalesced: a request already in flight answers it.
     */
    fun refreshNow()
}
