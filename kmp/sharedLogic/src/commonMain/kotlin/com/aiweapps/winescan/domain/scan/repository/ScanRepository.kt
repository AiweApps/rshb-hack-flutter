package com.aiweapps.winescan.domain.scan.repository

import com.aiweapps.core.network.ApiResponse
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess
import com.aiweapps.winescan.domain.scan.model.ScanOutcome
import com.aiweapps.winescan.domain.scan.model.ScanGeometryProgress
import com.aiweapps.winescan.domain.scan.model.ServiceStatus

/**
 * Shared scanner entry point. The configured backend owns each fresh recognition request.
 *
 * iOS can run the native engine or the network API; Android uses the network API.
 * Previous answers are stored by [com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository].
 */
interface ScanRepository {

    /** Recognizes the photo; [targetRoi] addresses one region in its original coordinates. */
    suspend fun recognize(photoPath: String, targetRoi: BottleBox?): ScanOutcome

    /** Optional per-request detection evidence. Existing HTTP transport has no intermediate messages. */
    suspend fun recognizeWithProgress(
        photoPath: String,
        targetRoi: BottleBox?,
        onProgress: (ScanGeometryProgress) -> Unit,
    ): ScanOutcome = recognize(photoPath, targetRoi)

    suspend fun status(): ApiResponse<ServiceStatus>

    /**
     * Network origin/Bearer or the native reference directory with an empty token.
     * `null` means reference access is unavailable; recognition can still work.
     */
    suspend fun referenceAccess(): ReferenceAccess?
}
