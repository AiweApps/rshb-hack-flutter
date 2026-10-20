package com.aiweapps.winescan.testutil

import com.aiweapps.winescan.domain.scan.model.ServiceAvailability
import com.aiweapps.winescan.domain.scan.model.ServiceState
import com.aiweapps.winescan.domain.status.ServiceSnapshot
import com.aiweapps.winescan.domain.status.ServiceStatusMonitor
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

/** A status the test sets by hand; [refreshCalls] counts the «refresh now» requests. */
class FakeServiceStatusMonitor(initial: ServiceAvailability = ServiceAvailability.READY) : ServiceStatusMonitor {

    private val current = MutableStateFlow(ServiceSnapshot(ServiceState(initial)))

    var refreshCalls: Int = 0
        private set

    fun emit(availability: ServiceAvailability, waiting: Int = 0) {
        current.value = ServiceSnapshot(ServiceState(availability, waiting))
    }

    override val snapshots: Flow<ServiceSnapshot> = current

    override fun refreshNow() {
        refreshCalls++
    }
}
