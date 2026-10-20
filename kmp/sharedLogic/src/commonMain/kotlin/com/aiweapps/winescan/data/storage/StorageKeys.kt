package com.aiweapps.winescan.data.storage

object StorageKeys {

    /** Name of the plain (non-encrypted) storage holding user preferences. */
    const val APP_PREFERENCES = "app_prefs"

    /** Name of the encrypted storage holding the guest session. */
    const val SECURE_PREFERENCES = "secure_prefs"

    /** Folder of the file store that keeps the photos of the scan history. */
    const val SCAN_PHOTOS_DIRECTORY = "scans"

    /** Folder of the file store that keeps its own copy of each photo in the comparison set. */
    const val COMPARE_PHOTOS_DIRECTORY = "compare"

    /** Independent copies of photos attached to assistant conversations. */
    const val ASSISTANT_PHOTOS_DIRECTORY = "assistant"

    /** First-install guest bootstrap: pending survives failed attempts; closed never reopens. */
    const val ASSISTANT_BOOTSTRAP_STATUS = "assistant_bootstrap_status"
    const val ASSISTANT_DEVICE_ID = "assistant_device_id"
    const val ASSISTANT_TOKEN = "assistant_account_token"
    const val ASSISTANT_EXPIRES_AT = "assistant_account_expires_at"
    const val ASSISTANT_SUBJECT = "assistant_account_subject"
    const val ASSISTANT_ACCOUNT_KIND = "assistant_account_kind"
    const val ASSISTANT_USERNAME = "assistant_account_username"
    const val ASSISTANT_SAVED_WINES = "assistant_saved_wines_"

    const val DATABASE_NAME = "winescan.db"

    const val THEME_MODE = "theme_mode"
    const val IS_ONBOARDING_DONE = "is_onboarding_done"
    const val SCANNER_BACKEND = "scanner_backend_v1"

    /** Guest session — stored in the encrypted storage only. */
    const val GUEST_TOKEN = "guest_access_token"
    const val GUEST_TOKEN_EXPIRES_AT = "guest_access_token_expires_at"
}
