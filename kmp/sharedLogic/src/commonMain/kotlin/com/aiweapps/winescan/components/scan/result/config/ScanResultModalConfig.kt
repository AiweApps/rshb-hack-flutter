package com.aiweapps.winescan.components.scan.result.config

import com.aiweapps.winescan.domain.scan.model.BottleBox
import kotlinx.serialization.Serializable

/**
 * The sheets of the result screen. They carry what the sheet draws from, because a slot is
 * restored in the constructor, before the answer is back from the history.
 */
@Serializable
internal sealed class ScanResultModalConfig {

    /** Full screen: draw a frame on [photoPath] to open a new result for it. */
    @Serializable
    data class DrawFrame(val photoPath: String, val frame: List<Int>?) : ScanResultModalConfig()

    @Serializable
    data class Compare(
        val crop: BottleBox?,
        val bottleNumber: Int,
        val cardTitle: String,
        val reference: String?,
    ) : ScanResultModalConfig()

    @Serializable
    data class More(
        val isRoi: Boolean,
        val bottleNumber: Int?,
        val canRescanBottle: Boolean,
        val canDrawFrame: Boolean,
    ) : ScanResultModalConfig()

    @Serializable
    data object TechDetails : ScanResultModalConfig()
}
