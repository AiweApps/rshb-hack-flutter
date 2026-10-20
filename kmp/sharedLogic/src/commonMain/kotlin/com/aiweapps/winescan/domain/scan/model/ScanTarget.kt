package com.aiweapps.winescan.domain.scan.model

import kotlinx.serialization.Serializable

/**
 * What the result screen is opened with: a fresh photo to recognise, a scan from the
 * history to show again, or a frame on another result's photo — drawn by hand or a bottle's
 * own box. Serializable because it is the navigation argument.
 */
@Serializable
sealed class ScanTarget {

    /** [photoPath] is the picked photo, already downsized for upload. */
    @Serializable
    data class NewScan(val photoPath: String) : ScanTarget()

    @Serializable
    data class Stored(val scanId: Long) : ScanTarget()

    /**
     * A frame on another result's photo: the same photo, recognised for [roi] only (already
     * clamped to the photo's frame). Such an answer is never stored in the history.
     *
     * [isBottle] — [roi] is a recognised bottle's own box, picked with «Recognise only this
     * bottle» in «More», not drawn by hand. The screen is the same; only analytics tells
     * the two requests apart.
     *
     * [photoPath] is the path the other result was showing: the history's stored photo once
     * the answer was saved, otherwise the downsized temp photo. Both stay on disk while the
     * app runs, but after process death a temp file may be gone; the request then fails as
     * it does for a [NewScan] whose photo cannot be opened, with the error panel.
     */
    @Serializable
    data class Framed(val photoPath: String, val roi: BottleBox, val isBottle: Boolean = false,
        /** New explicit rescans must not compare equal to the currently open result. */
        val requestId: String? = null,
    ) : ScanTarget()
}
