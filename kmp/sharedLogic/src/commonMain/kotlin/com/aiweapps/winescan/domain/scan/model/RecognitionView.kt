package com.aiweapps.winescan.domain.scan.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

/** How the request addressed the photo. */
enum class ScanMode(val apiName: String) {
    AUTOMATIC("automatic"),
    EXPLICIT_ROI("explicit_roi"),
    UNKNOWN("unknown");

    companion object {
        fun fromString(value: String?): ScanMode =
            entries.firstOrNull { it.apiName == value } ?: UNKNOWN
    }
}

/**
 * The service's verdict for the photo or for one bottle. `UNCERTAIN` is the normal "here
 * are candidates" outcome; there is no accepted state, because confidence is not calibrated.
 */
enum class ScanDecision(val apiName: String) {
    UNCERTAIN("uncertain"),
    MATCHED("matched"),
    UNKNOWN("unknown"),
    INSUFFICIENT_EVIDENCE("insufficient_evidence"),
    AMBIGUOUS_TARGET("ambiguous_target"),
    NO_TARGET("no_target"),
    INVALID_IMAGE("invalid_image"),
    OTHER("other");

    companion object {
        fun fromString(value: String?): ScanDecision =
            entries.firstOrNull { it.apiName == value } ?: OTHER
    }
}

/**
 * An answer without bottles: for the whole photo or a drawn frame, and whether the verdict
 * itself already says «no bottle» (then only the advice follows).
 */
enum class EmptyAnswer { AUTO, AUTO_NO_TARGET, ROI, ROI_NO_TARGET }

/**
 * The `view` object of `POST /api/recognize` (gateway `build_view`).
 *
 * Wire-shaped on purpose — see [WineCard]. Enum-like fields stay raw strings so an
 * unknown value from a newer backend cannot break parsing; the typed view is a getter.
 */
@Serializable
data class RecognitionView(
    val decision: String = ScanDecision.OTHER.apiName,
    @SerialName("decision_text") val decisionText: String? = null,
    @SerialName("raw_slug") val rawSlug: String? = null,
    @SerialName("best_slug") val bestSlug: String? = null,
    @SerialName("published_card") val publishedCard: WineCard? = null,
    val mode: String = ScanMode.UNKNOWN.apiName,
    val roi: JsonElement? = null,
    @SerialName("bottle_count") val bottleCount: Int = 0,
    @SerialName("primary_instance_id") val primaryInstanceId: String? = null,
    @SerialName("primary_basis") val primaryBasis: String? = null,
    @SerialName("frame_size") val frameSize: List<Int>? = null,
    val image: ImageInfo? = null,
    val bottles: List<RecognizedBottle> = emptyList(),
    val reasons: List<String> = emptyList(),
    @SerialName("profile_checksum") val profileChecksum: String? = null,
    @SerialName("backend_ms") val backendMs: Double? = null,
) {
    val decisionKind: ScanDecision get() = ScanDecision.fromString(decision)

    val modeKind: ScanMode get() = ScanMode.fromString(mode)

    val roiBox: BottleBox? get() = BottleBox.fromJson(roi)

    /** Width and height of the EXIF-oriented frame every box refers to. */
    val frame: List<Int>? get() = frameSize ?: image?.size

    val isExplicitRoi: Boolean get() = modeKind == ScanMode.EXPLICIT_ROI

    /** Which «nothing found» text an answer without bottles gets. */
    val emptyAnswer: EmptyAnswer
        get() {
            val noTarget = decisionKind == ScanDecision.NO_TARGET
            return when {
                isExplicitRoi && noTarget -> EmptyAnswer.ROI_NO_TARGET
                isExplicitRoi -> EmptyAnswer.ROI
                noTarget -> EmptyAnswer.AUTO_NO_TARGET
                else -> EmptyAnswer.AUTO
            }
        }

    /**
     * The bottle box, the user's explicit frame, or a detected label when the bottle
     * outline is unavailable (for example a close-up). No box means show the source photo.
     */
    fun cropOf(bottle: RecognizedBottle): BottleBox? =
        bottle.geometryBox ?: roiBox?.takeIf { isExplicitRoi } ?: bottle.labelBox

    /** The bottle the service suggests as the central one, when it says so. */
    fun isNearCenter(bottle: RecognizedBottle): Boolean =
        bottle.primary && primaryBasis == CENTRAL_SUGGESTION

    fun bottleById(instanceId: String?): RecognizedBottle? =
        instanceId?.let { id -> bottles.firstOrNull { it.instanceId == id } }

    /**
     * The bottle an answer opens on. The service sends no scores (probability is `null`,
     * confidence is not calibrated), so the order comes from what it does say: the bottle it
     * names in `primary_instance_id` first; otherwise a matched verdict before an uncertain
     * one before the rest, then a bottle with a best card before one without, then the lowest
     * number. `null` only when there are no bottles.
     */
    fun bestBottle(): RecognizedBottle? =
        bottleById(primaryInstanceId) ?: bottles.minWithOrNull(BEST_FIRST)

    /**
     * The bottle that may wear the crown on its chip: an automatic answer with several
     * bottles, and the choice is unambiguous — the service named it, or exactly one bottle
     * ranks top by [bestBottle]'s order. A tie (for instance `primary_basis = ambiguous_tie`
     * with two uncertain bottles) crowns nobody, though [bestBottle] still opens the first.
     */
    val winnerInstanceId: String?
        get() {
            if (isExplicitRoi || bottles.size < 2) return null
            bottleById(primaryInstanceId)?.let { return it.instanceId }
            val top = bottles.minWithOrNull(BEST_FIRST) ?: return null
            val tied = bottles.count { RANK.compare(it, top) == 0 }
            return top.instanceId.takeIf { tied == 1 }
        }

    // Public, as on the assistant branch, so the generated serializer stays reachable from
    // platform code; everything inside is private.
    companion object {
        private const val CENTRAL_SUGGESTION = "central_suggestion"

        /** Matched before uncertain before every other verdict; a best card before none. */
        private val RANK: Comparator<RecognizedBottle> = compareBy<RecognizedBottle> { bottle ->
            when (bottle.decisionKind) {
                ScanDecision.MATCHED -> 0
                ScanDecision.UNCERTAIN -> 1
                else -> 2
            }
        }.thenBy { if (it.best != null) 0 else 1 }

        private val BEST_FIRST: Comparator<RecognizedBottle> = RANK.thenBy { it.number }
    }
}

/** One physical bottle found in the photo, with its candidates. */
@Serializable
data class RecognizedBottle(
    val number: Int,
    @SerialName("instance_id") val instanceId: String,
    val geometry: JsonElement? = null,
    @SerialName("label_bbox") val labelBbox: JsonElement? = null,
    @SerialName("select_roi") val selectRoi: JsonElement? = null,
    val selectable: String? = null,
    val primary: Boolean = false,
    val addressed: Boolean = false,
    val decision: String = ScanDecision.OTHER.apiName,
    @SerialName("decision_text") val decisionText: String? = null,
    val reasons: List<String> = emptyList(),
    val best: WineCard? = null,
    val alternatives: List<WineCard> = emptyList(),
) {
    val decisionKind: ScanDecision get() = ScanDecision.fromString(decision)

    val geometryBox: BottleBox? get() = BottleBox.fromJson(geometry)

    val labelBox: BottleBox? get() = BottleBox.fromJson(labelBbox)?.takeIf { box ->
        listOf(box.x1, box.y1, box.x2, box.y2).all { it.isFinite() } && box.width > 0 && box.height > 0
    }

    val selectRoiBox: BottleBox? get() = BottleBox.fromJson(selectRoi)
}

/** What the service saw in the uploaded file. */
@Serializable
data class ImageInfo(
    val format: String? = null,
    val mime: String? = null,
    val size: List<Int>? = null,
    val bytes: Long? = null,
)
