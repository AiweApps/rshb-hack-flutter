package com.aiweapps.winescan.data.scan.remote

internal object ScanRoutes {
    /** `POST /auth/guest/token` — an anonymous 24-hour Bearer, no body. */
    const val GUEST_TOKEN = "auth/guest/token"

    /** `POST /api/recognize` — multipart `image` plus optional `target_roi`. */
    const val RECOGNIZE = "api/recognize"

    /** `GET /api/status` — readiness, queue and limits of the service. */
    const val STATUS = "api/status"
}
