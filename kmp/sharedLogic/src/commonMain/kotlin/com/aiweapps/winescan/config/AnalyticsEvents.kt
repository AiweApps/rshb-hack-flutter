package com.aiweapps.winescan.config

/**
 * Names the analytics reports are built on. Renaming one splits its history in two, so a
 * value here changes only together with the dashboards that read it.
 */
internal object AnalyticsEvents {
    const val PHOTO_TAKEN = "photo_taken"
    const val RECOGNITION_SUCCEEDED = "recognition_succeeded"
    const val RECOGNITION_FAILED = "recognition_failed"
    const val WINE_PAGE_OPENED = "wine_page_opened"
    const val RESULT_SHARED = "result_shared"
    /** Every tap, with [AnalyticsParams.RESULT]: a full set or a wine already there is an answer too. */
    const val COMPARE_ADD = "compare_add"
    const val PAIRING_SAVED = "pairing_saved"
    const val ONBOARDING_FINISHED = "onboarding_finished"
    /** Colour, sugar or pairings could not be loaded and the screen shows «no data» instead. */
    const val GASTRONOMY_FAILED = "gastronomy_failed"
}

internal object AnalyticsParams {
    const val SOURCE = "source"
    const val REQUEST = "request"
    const val DECISION = "decision"
    const val BOTTLES = "bottles"
    const val REASON = "reason"
    const val SCOPE = "scope"
    const val RESULT = "result"
    const val SCREEN = "screen"
    const val WINES = "wines"
    const val DISH = "dish"
    const val SKIPPED_FROM = "skipped_from"
}

internal object AnalyticsValues {
    const val SOURCE_CAMERA = "camera"
    const val SOURCE_GALLERY = "gallery"

    /** What a recognition was asked for: the whole photo, one bottle of it, a drawn frame. */
    const val REQUEST_PHOTO = "photo"
    const val REQUEST_BOTTLE = "bottle"
    const val REQUEST_FRAME = "frame"

    const val SCOPE_PHOTO = "photo"
    const val SCOPE_BOTTLE = "bottle"

    /** Which gastronomy request failed: the dish dictionary or the wines' data. */
    const val REQUEST_DISHES = "dishes"
    const val REQUEST_WINES = "wines"

    const val REASON_NETWORK = "network"
    const val REASON_TIMEOUT = "timeout"
    const val REASON_UNAUTHORIZED = "unauthorized"
    const val REASON_SERVER = "server"
    const val REASON_UNKNOWN = "unknown"

    const val RESULT_COMPLETED = "completed"
    const val RESULT_SKIPPED = "skipped"
}

/** Also the value of [AnalyticsParams.SCREEN] for an action that several screens offer. */
internal object AnalyticsScreens {
    const val ONBOARDING = "onboarding"
    const val SCAN = "scan"
    const val HISTORY = "history"
    const val COMPARE = "compare"
    const val SETTINGS = "settings"
    const val SCAN_RESULT = "scan_result"
    const val WINE_DETAIL = "wine_detail"
    const val DISH_PAIRING = "dish_pairing"
    const val ASSISTANT = "assistant"
}
