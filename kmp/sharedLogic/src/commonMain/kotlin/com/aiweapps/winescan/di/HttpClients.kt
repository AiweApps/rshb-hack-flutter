package com.aiweapps.winescan.di

import org.koin.core.qualifier.named

/**
 * Qualifiers for the HTTP clients. All are named so that no client is resolved by
 * accident — picking the wrong one silently changes auth behaviour.
 */
object HttpClients {

    /**
     * The API without the Bearer plugin — used for the guest token call only. Issuing a
     * token must never run through the authorized client or a failing 401 would recurse.
     */
    val PlainAuth = named("plainAuthHttpClient")

    /** The API with the Bearer plugin — recognition, status, references. */
    val Authorized = named("authorizedHttpClient")

    /** Local assistant service; no scanner Bearer and no request logging. */
    val Assistant = named("assistantHttpClient")
}

/**
 * Qualifiers for the two photo stores. The history owns the scan photos; the comparison
 * set keeps its own copies, so clearing one never touches the other.
 */
object FileStores {
    val Scans = named("scanPhotos")
    val Compare = named("comparePhotos")
    val Assistant = named("assistantPhotos")
}
