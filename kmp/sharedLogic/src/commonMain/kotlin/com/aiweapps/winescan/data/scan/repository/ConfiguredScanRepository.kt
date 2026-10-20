package com.aiweapps.winescan.data.scan.repository

import com.aiweapps.core.error.AppError
import com.aiweapps.core.network.ApiResponse
import com.aiweapps.core.storage.KeyValueStorage
import com.aiweapps.winescan.config.AppConfig
import com.aiweapps.winescan.data.storage.StorageKeys
import com.aiweapps.winescan.domain.scan.model.BottleBox
import com.aiweapps.winescan.domain.scan.model.RecognitionView
import com.aiweapps.winescan.domain.scan.model.ReferenceAccess
import com.aiweapps.winescan.domain.scan.model.ScanFailure
import com.aiweapps.winescan.domain.scan.model.ScanFailureKind
import com.aiweapps.winescan.domain.scan.model.ScanOutcome
import com.aiweapps.winescan.domain.scan.model.ScanGeometryProgress
import com.aiweapps.winescan.domain.scan.model.LocalModelState
import com.aiweapps.winescan.domain.scan.model.ScannerBackend
import com.aiweapps.winescan.domain.scan.model.ScannerBackendState
import com.aiweapps.winescan.domain.scan.model.ScannerBuild
import com.aiweapps.winescan.domain.scan.model.ServiceStatus
import com.aiweapps.winescan.domain.scan.repository.LocalScanEngine
import com.aiweapps.winescan.domain.scan.repository.ScanRepository
import com.aiweapps.winescan.domain.scan.repository.ScannerBackendControls
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.serialization.json.Json
import kotlin.coroutines.resume
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

internal class ConfiguredScanRepository(
    private val remote: ScanRepository,
    private val local: LocalScanEngine?,
    private val config: AppConfig,
    private val storage: KeyValueStorage,
    private val json: Json,
) : ScanRepository, ScannerBackendControls {
    private val mutableBackend = MutableStateFlow(
        ScannerBackendState(
            selected = if (config.scannerBuild == ScannerBuild.LOCAL) ScannerBackend.LOCAL
                else ScannerBackend.entries.firstOrNull { it.name == storage.getString(StorageKeys.SCANNER_BACKEND) }
                    ?: ScannerBackend.SERVER,
            canChoose = config.scannerBuild == ScannerBuild.SERVER && local != null,
            localAvailable = local?.isAvailable() == true,
        )
    )
    override val backendState = mutableBackend.asStateFlow()
    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var assetJob: Job? = null

    init {
        local?.observeAssetsState { body ->
            val state = try { json.decodeFromString<LocalModelState>(body) }
                catch (_: IllegalArgumentException) { null }
            if (state != null) mutableBackend.update { it.copy(localAvailable = state.available, localModel = state) }
        }
    }

    override fun downloadLocalAssets() {
        val engine = local ?: return
        val state = mutableBackend.value
        if (!state.canChoose || state.localAvailable || state.localModel.isBusy || assetJob?.isActive == true) return
        mutableBackend.update { it.copy(localModel = it.localModel.copy(phase = "preparing", error = null)) }
        assetJob = applicationScope.launch {
            try {
                val access = remote.referenceAccess()
                if (access == null) mutableBackend.update {
                    it.copy(localModel = it.localModel.copy(phase = "failed", error = "download_failed"))
                } else engine.downloadAssets(access.baseUrl, access.token)
            } catch (error: CancellationException) { throw error }
            catch (_: Exception) { mutableBackend.update {
                it.copy(localModel = it.localModel.copy(phase = "failed", error = "download_failed"))
            } }
        }
    }

    override fun cancelLocalAssets() {
        assetJob?.cancel(); assetJob = null
        local?.cancelAssetDownload()
    }

    override fun selectBackend(backend: ScannerBackend) {
        val state = mutableBackend.value
        if (!state.canChoose || state.selected == backend || (backend == ScannerBackend.LOCAL && !state.localAvailable)) return
        storage.putString(StorageKeys.SCANNER_BACKEND, backend.name)
        mutableBackend.update { it.copy(selected = backend) }
        if (backend == ScannerBackend.SERVER) local?.releaseModels()
    }

    override suspend fun recognize(photoPath: String, targetRoi: BottleBox?): ScanOutcome =
        recognizeWithProgress(photoPath, targetRoi) { }

    @OptIn(ExperimentalUuidApi::class)
    override suspend fun recognizeWithProgress(
        photoPath: String, targetRoi: BottleBox?, onProgress: (ScanGeometryProgress) -> Unit,
    ): ScanOutcome {
        // Capture once: a later Settings change cannot reroute this operation.
        val selected = mutableBackend.value.selected
        if (selected == ScannerBackend.SERVER) return remote.recognizeWithProgress(photoPath, targetRoi, onProgress)
        val engine = local ?: return localFailure()
        val requestId = Uuid.random().toString()
        return suspendCancellableCoroutine { continuation ->
            continuation.invokeOnCancellation { engine.cancel(requestId) }
            engine.recognizeWithProgress(requestId, photoPath, targetRoi?.toJson()?.toString(), { body ->
                if (continuation.isActive) {
                    val progress = try { json.decodeFromString<ScanGeometryProgress>(body) }
                        catch (_: IllegalArgumentException) { null }
                    if (progress?.isValid == true) onProgress(progress)
                }
            }) { body, _ ->
                if (continuation.isActive) {
                    val outcome = if (body == null) localFailure() else try {
                        ScanOutcome.Recognized(json.decodeFromString<RecognitionView>(body))
                    } catch (_: IllegalArgumentException) {
                        localFailure()
                    }
                    continuation.resume(outcome)
                }
            }
        }
    }

    override suspend fun status(): ApiResponse<ServiceStatus> {
        if (mutableBackend.value.selected == ScannerBackend.SERVER) return remote.status()
        val engine = local ?: return ApiResponse.Error(AppError.Unknown)
        return try {
            ApiResponse.Success(json.decodeFromString<ServiceStatus>(engine.statusJson()), statusCode = 200)
        } catch (_: IllegalArgumentException) {
            ApiResponse.Error(AppError.Unknown)
        }
    }

    override suspend fun referenceAccess(): ReferenceAccess? =
        if (mutableBackend.value.selected == ScannerBackend.SERVER) remote.referenceAccess()
        else local?.let { ReferenceAccess(baseUrl = it.referenceBaseUrl(), token = "") }

    private fun localFailure(): ScanOutcome.Failed = ScanOutcome.Failed(
        ScanFailure(ScanFailureKind.UNPROCESSED, statusCode = null, retryable = true, retryAfterSeconds = null)
    )
}
