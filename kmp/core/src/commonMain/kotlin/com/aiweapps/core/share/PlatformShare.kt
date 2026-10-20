package com.aiweapps.core.share

/**
 * Hands a payload to the platform's own share UI.
 *
 * Declared here and implemented **in the application module**, not through
 * `expect`/`actual`. The reason is the dependency graph: an `actual` lives in this module's
 * platform source set, and `:core` sits above both applications, so it can never ask the
 * app which Activity is on screen or which view controller should present the sheet.
 *
 * The application implements this interface and hands the implementation to `initKoin` as a
 * constructor parameter, so a missing implementation is a compile error on both platforms
 * rather than a Koin resolution failure at runtime.
 */
interface PlatformShare {

    fun share(payload: SharePayload)

    /** Shares [ShareFilePayload.content] as a file the receiving app can open or save. */
    fun shareFile(payload: ShareFilePayload)
}

/**
 * Data, never a finished sentence: wording, separators and the chooser caption belong to
 * the platform, which owns the localized resources.
 *
 * [url] is nullable because not everything shareable has a public address; an implementation
 * that receives `null` shares [title] alone.
 */
data class SharePayload(
    val title: String,
    val url: String?,
)

/** A text document to share as a file: the platform writes it out and attaches it. */
data class ShareFilePayload(
    val fileName: String,
    val mimeType: String,
    val content: String,
)
