package com.aiweapps.winescan.domain.scan.repository

/** Native model/OCR boundary. No app state or network fallback belongs here. */
interface LocalScanEngine {
    fun isAvailable(): Boolean
    fun statusJson(): String
    fun referenceBaseUrl(): String
    fun wineJson(slug: String): String?
    fun searchJson(query: String): String
    fun recognize(requestId: String, photoPath: String, roiJson: String?, completion: (String?, String?) -> Unit)
    fun recognizeWithProgress(
        requestId: String, photoPath: String, roiJson: String?,
        progress: (String) -> Unit, completion: (String?, String?) -> Unit,
    ) = recognize(requestId, photoPath, roiJson, completion)
    fun cancel(requestId: String)
    fun releaseModels()
    fun assetsStateJson(): String = "{}"
    fun observeAssetsState(observer: (String) -> Unit) = observer(assetsStateJson())
    fun downloadAssets(baseUrl: String, token: String) {}
    fun cancelAssetDownload() {}
}
