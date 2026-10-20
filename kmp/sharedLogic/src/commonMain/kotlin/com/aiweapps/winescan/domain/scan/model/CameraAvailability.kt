package com.aiweapps.winescan.domain.scan.model

/** Whether the viewfinder can run — what the platform camera reports. */
enum class CameraAvailability {
    READY,

    /** Refused once; the system will ask again. */
    DENIED,

    /** Refused for good; only the system settings can change it. */
    PERMANENTLY_DENIED,

    /** No camera on this device (a simulator, a tablet without one). */
    UNAVAILABLE,
}

/** What the scan tab shows instead of, or as, the viewfinder. */
enum class CameraStatus {
    /** Not decided yet, or the camera was stopped while the tab was away. */
    STARTING,
    READY,
    DENIED,
    PERMANENTLY_DENIED,
    UNAVAILABLE,
}
