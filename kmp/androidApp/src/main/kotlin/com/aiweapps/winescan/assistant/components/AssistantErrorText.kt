package com.aiweapps.winescan.assistant.components

import com.aiweapps.winescan.R
import com.aiweapps.winescan.domain.assistant.model.AssistantUiError

internal fun AssistantUiError.textRes(): Int = when (this) {
    AssistantUiError.SCAN_FAILED -> R.string.assistant_error_scan
    AssistantUiError.WINE_UNKNOWN -> R.string.assistant_error_unknown
    AssistantUiError.SERVICE_UNAVAILABLE -> R.string.assistant_error_service
    AssistantUiError.SESSION_OPEN_FAILED -> R.string.assistant_error_conversation
    AssistantUiError.STORE_UNAVAILABLE -> R.string.assistant_error_store
    AssistantUiError.RETAIL_ACCESS_REQUIRED -> R.string.assistant_error_retail_access
    AssistantUiError.RETAIL_SEARCH_FAILED -> R.string.assistant_error_search
    AssistantUiError.REPLACEMENT_UNAVAILABLE -> R.string.assistant_error_replacement
    AssistantUiError.DINNER_SELECTION_UNAVAILABLE -> R.string.assistant_error_dinner_selection
    AssistantUiError.DINNER_SELECTION_STALE -> R.string.assistant_error_dinner_stale
}
