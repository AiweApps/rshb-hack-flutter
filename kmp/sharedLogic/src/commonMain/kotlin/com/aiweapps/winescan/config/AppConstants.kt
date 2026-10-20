package com.aiweapps.winescan.config

/** Behaviour of the recognition API client. The base URL comes from [AppEnvironment]. */
object ApiConstants {
    /**
     * Recognition is queued on the server and may take up to three minutes; the web client
     * waits the same 200 seconds.
     */
    const val RECOGNIZE_TIMEOUT_MS: Long = 200_000
    const val GUEST_TOKEN_TIMEOUT_MS: Long = 15_000

    /** The status pill on the scan screen re-reads the service state this often. */
    const val STATUS_REFRESH_INTERVAL_MS: Long = 15_000

    /**
     * 429 and "busy" 503 responses say when to come back: the client waits and retries on
     * its own this many times before showing an error.
     */
    const val MAX_AUTO_RETRIES: Int = 3
    const val DEFAULT_RETRY_AFTER_SECONDS: Long = 5

    /**
     * A token that would expire within this margin is refreshed ahead of time, so a long
     * recognition request does not start with a token about to die.
     */
    const val GUEST_TOKEN_EXPIRY_MARGIN_MS: Long = 60_000

    const val IMAGE_FIELD = "image"
    const val TARGET_ROI_FIELD = "target_roi"
    const val UPLOAD_FILE_NAME = "photo.jpg"
    const val UPLOAD_MIME_TYPE = "image/jpeg"
    const val JSON_MIME_TYPE = "application/json"

    /** One catalogue card (`v1/wines/<slug>`); a slower answer counts as a failure. */
    const val CATALOG_TIMEOUT_MS: Long = 8_000

    /** Catalogue cards kept in memory for the session, oldest dropped first. */
    const val CATALOG_CACHE_SIZE: Int = 256

    const val HTTP_NOT_FOUND: Int = 404
}

/**
 * Limits of what the app keeps and prepares on the device. Public because the platforms
 * prepare the photo themselves and must agree with the shared code on the numbers.
 */
object ScanLimits {
    /**
     * The photo is downsized to this side before upload: well under the 24 MP server cap
     * and still enough for the label to be read.
     */
    const val UPLOAD_MAX_SIDE: Int = 4000
    const val UPLOAD_JPEG_QUALITY: Int = 92

    /** Recent scans shown on the scan tab while the camera is not available. */
    const val MAX_RECENT_SCANS_ON_HOME: Int = 5

    /** A drawn frame narrower than this (in screen points) is a tap, not a box. */
    const val MIN_ROI_SIDE_ON_SCREEN: Float = 16f
    const val MIN_ROI_SIDE_WHILE_RESIZING: Float = 24f

    /** How far the comparison panes zoom in. */
    const val COMPARE_MAX_ZOOM: Float = 5f

    /** Padding around the bottle crop shown next to the reference, as a share of the longer side. */
    const val CROP_PADDING_FACTOR: Float = 0.04f
}

/** The comparison set and the dish pairing built on it. */
object CompareLimits {
    /** How many different wines can be compared side by side. */
    const val MAX_WINES: Int = 3
}

/** Where colour, sugar, serving temperature and food pairings come from. */
object GastronomyConfig {
    /** The language a dish label falls back to when the catalogue has none in the UI's. */
    const val DEFAULT_LANGUAGE = "ru"

    /** The source catalogue names its dish categories in Russian only. */
    const val CATALOG_LANGUAGE = "ru"
}

object TimingConstants {
    const val SPLASH_DELAY_MS: Long = 900

    /**
     * How long a status other than «ready» stays in the hint over the shutter before it
     * folds back into «point at the label». Long enough to read, short enough not to nag.
     */
    const val STATUS_HINT_VISIBLE_MS: Long = 4_000
    const val RETRY_TICK_MS: Long = 1_000
}

/** External addresses the app opens or recognises. */
object LinkConstants {
    /** Only catalogue pages under this prefix are offered as a link, the same rule as the web UI. */
    const val VINO_SVOE_WINES_PREFIX = "https://vino-svoe.ru/wines/"
    const val VINO_SVOE_SITE = "https://vino-svoe.ru/"
}
