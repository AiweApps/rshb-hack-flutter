package com.aiweapps.winescan.components.scan.result.model

/** One line of the «technical details» list. The UI localises the key and the special values. */
data class TechRow(
    val key: TechKey,
    val value: TechValue,
)

enum class TechKey {
    DECISION,
    PRIMARY_BASIS,
    MODE,
    RAW_SLUG,
    BEST_CANDIDATE,
    CARD_SLUG,
    PAGE_URL,
    PAGE_SOURCE,
    SNAPSHOT,
    ROI,
    BOTTLES,
    FRAME,
    FILE,
    PROBABILITY,
    BACKEND_TIME,
    PROFILE,
    REASONS,
}

sealed class TechValue {
    /** A raw value from the answer, shown as is. */
    data class Text(val text: String) : TechValue()

    data object None : TechValue()

    data object SnapshotYes : TechValue()

    data object SnapshotNo : TechValue()

    /** «not calculated (no calibration)» — the service does not score its answers. */
    data object ProbabilityNotCalculated : TechValue()

    data class File(val format: String, val bytes: Long) : TechValue()

    data class Milliseconds(val millis: Double) : TechValue()
}
