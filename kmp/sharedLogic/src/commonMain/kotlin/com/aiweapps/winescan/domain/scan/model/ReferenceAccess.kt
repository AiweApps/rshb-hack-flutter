package com.aiweapps.winescan.domain.scan.model

/**
 * What a screen needs to load a catalogue reference image: the API origin the relative
 * `reference` path resolves against, and the Bearer the image endpoint requires.
 */
data class ReferenceAccess(
    val baseUrl: String,
    val token: String,
) {
    val authorizationHeader: String get() = "Bearer $token"

    fun resolve(reference: String?): String? {
        if (reference.isNullOrEmpty()) return null
        if (reference.startsWith("http")) return reference
        return baseUrl.trimEnd('/') + "/" + reference.trimStart('/')
    }

    companion object {
        const val AUTHORIZATION_HEADER = "Authorization"
    }
}
