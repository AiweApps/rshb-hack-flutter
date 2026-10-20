package com.aiweapps.winescan.data.scan.model

import com.aiweapps.winescan.domain.scan.model.RecognitionView
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Envelope of `POST /api/recognize`: the answer sits under `view`. */
@Serializable
internal data class RecognizeResponseDto(
    val view: RecognitionView,
)

/** `POST /auth/guest/token`. */
@Serializable
internal data class GuestTokenDto(
    @SerialName("access_token") val accessToken: String,
    @SerialName("token_type") val tokenType: String? = null,
    @SerialName("expires_in") val expiresIn: Long,
    @SerialName("guest_id") val guestId: String? = null,
)

/** The body the backend sends with a 4xx: `{"error": "bad_roi", "detail": "…"}`. */
@Serializable
internal data class ApiErrorBodyDto(
    val error: String? = null,
    val detail: String? = null,
)
