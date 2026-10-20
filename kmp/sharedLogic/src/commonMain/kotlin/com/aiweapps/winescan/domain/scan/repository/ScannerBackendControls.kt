package com.aiweapps.winescan.domain.scan.repository

import com.aiweapps.winescan.domain.scan.model.ScannerBackend
import com.aiweapps.winescan.domain.scan.model.ScannerBackendState
import kotlinx.coroutines.flow.StateFlow

/** Shared owner of the build policy and the server build's remembered choice. */
interface ScannerBackendControls {
    val backendState: StateFlow<ScannerBackendState>
    fun selectBackend(backend: ScannerBackend)
    fun downloadLocalAssets()
    fun cancelLocalAssets()
}
