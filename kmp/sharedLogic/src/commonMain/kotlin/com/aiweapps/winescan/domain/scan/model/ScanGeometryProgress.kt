package com.aiweapps.winescan.domain.scan.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Detection evidence for this in-flight photo, never a wine identification or stored answer. */
@Serializable
data class ScanGeometryProgress(
    val stage: String,
    @SerialName("frame_size") val frameSize: List<Int>,
    val regions: List<ScanDetectedRegion> = emptyList(),
) {
    val isValid: Boolean get() = frameSize.size == 2 && frameSize.all { it > 0 } &&
        regions.size <= 16 && regions.map { it.id }.distinct().size == regions.size &&
        regions.all { region ->
            region.id.isNotBlank() && region.number > 0 &&
                listOfNotNull(region.bottleBox, region.labelBox).all { box ->
                    listOf(box.x1, box.y1, box.x2, box.y2).all { it.isFinite() } &&
                        box.x1 >= 0 && box.y1 >= 0 && box.x2 <= frameSize[0] && box.y2 <= frameSize[1] &&
                        box.width > 0 && box.height > 0
                }
        }
}

@Serializable
data class ScanDetectedRegion(
    val id: String,
    val number: Int,
    @SerialName("bottle_box") val bottleBox: BottleBox? = null,
    @SerialName("label_box") val labelBox: BottleBox? = null,
)
