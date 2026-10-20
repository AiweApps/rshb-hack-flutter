package com.aiweapps.winescan.testutil

import com.aiweapps.core.error.AppError
import com.aiweapps.core.network.ApiResponse
import com.aiweapps.core.platform.PlatformLinks
import com.aiweapps.core.share.PlatformShare
import com.aiweapps.core.share.ShareFilePayload
import com.aiweapps.core.share.SharePayload
import com.aiweapps.winescan.domain.history.model.ScanHistoryItem
import com.aiweapps.winescan.domain.history.model.ScanRecord
import com.aiweapps.winescan.domain.history.repository.ScanHistoryRepository
import com.aiweapps.winescan.domain.preferences.repository.AppPreferencesRepository
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess
import com.aiweapps.winescan.domain.scan.model.ScanOutcome
import com.aiweapps.winescan.domain.scan.model.ServiceStatus
import com.aiweapps.winescan.domain.scan.repository.ScanRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map

class FakeScanRepository : ScanRepository {

    /** What the next recognition answers with. */
    var nextOutcome: ScanOutcome = ScanOutcome.Recognized(RecognitionView())

    var status: ApiResponse<ServiceStatus> = ApiResponse.Error(AppError.Unknown)

    var recognizeCalls: Int = 0
        private set

    /** The frame of the last request, so a test can check what the component asked for. */
    var lastRoi: BottleBox? = null
        private set

    var lastPhotoPath: String? = null
        private set

    override suspend fun recognize(photoPath: String, targetRoi: BottleBox?): ScanOutcome {
        recognizeCalls++
        lastRoi = targetRoi
        lastPhotoPath = photoPath
        return nextOutcome
    }

    var statusCalls: Int = 0
        private set

    override suspend fun status(): ApiResponse<ServiceStatus> {
        statusCalls++
        return status
    }

    override suspend fun referenceAccess(): ReferenceAccess? = ReferenceAccess("https://example.test/", "token")
}

class FakeScanHistoryRepository : ScanHistoryRepository {

    private val records = MutableStateFlow<List<ScanRecord>>(emptyList())
    private var nextId = 1L

    val saved: List<ScanRecord> get() = records.value

    /** Set to have every write blow up, the way a full disk would. */
    var failOnWrite: Boolean = false

    fun seed(photoPath: String, view: RecognitionView): Long {
        val id = nextId++
        records.value = records.value + ScanRecord(id, createdAtMillis = id, photoPath = photoPath, view = view)
        return id
    }

    override fun watchAll(): Flow<List<ScanHistoryItem>> = records.map { list -> list.map { it.toItem() } }

    override fun watchRecent(limit: Int): Flow<List<ScanHistoryItem>> =
        records.map { list -> list.take(limit).map { it.toItem() } }

    override suspend fun byId(id: Long): ScanRecord? = records.value.firstOrNull { it.id == id }

    override suspend fun save(photoPath: String, view: RecognitionView): Long {
        if (failOnWrite) error("storage unavailable")
        return seed(photoPath, view)
    }

    override suspend fun delete(id: Long) {
        if (failOnWrite) error("storage unavailable")
        records.value = records.value.filterNot { it.id == id }
    }

    override suspend fun clear() {
        if (failOnWrite) error("storage unavailable")
        records.value = emptyList()
    }

    private fun ScanRecord.toItem() = ScanHistoryItem(
        id = id,
        createdAtMillis = createdAtMillis,
        photoPath = photoPath,
        bestTitle = view.bottles.firstOrNull()?.best?.title,
        bestProducer = null,
        bestSlug = view.bottles.firstOrNull()?.best?.slug,
        bestReference = null,
        bottleCount = view.bottles.size,
    )
}

class FakeAppPreferencesRepository : AppPreferencesRepository {

    override var isOnboardingDone: Boolean = false
        private set

    override fun setOnboardingDone(value: Boolean) {
        isOnboardingDone = value
    }
}

/** Records what shared code decided to share — the only thing testable without a device. */
class FakePlatformShare : PlatformShare {

    val shared: MutableList<SharePayload> = mutableListOf()
    val sharedFiles: MutableList<ShareFilePayload> = mutableListOf()

    override fun share(payload: SharePayload) {
        shared += payload
    }

    override fun shareFile(payload: ShareFilePayload) {
        sharedFiles += payload
    }
}

class FakePlatformLinks : PlatformLinks {

    val openedUrls: MutableList<String> = mutableListOf()
    var settingsOpened: Int = 0
        private set

    override fun openUrl(url: String) {
        openedUrls += url
    }

    override fun openAppSettings() {
        settingsOpened++
    }
}
