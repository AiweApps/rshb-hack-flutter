import Foundation
import SharedLogic

func assistantErrorMessage(_ code: AssistantUiError) -> String {
    if code == AssistantUiError.scanFailed { return String(localized: "assistant_error_scan_failed") }
    if code == AssistantUiError.wineUnknown { return String(localized: "assistant_error_wine_unknown") }
    if code == AssistantUiError.serviceUnavailable { return String(localized: "assistant_error_service_unavailable") }
    if code == AssistantUiError.sessionOpenFailed { return String(localized: "assistant_error_session_open_failed") }
    if code == AssistantUiError.storeUnavailable { return String(localized: "assistant_error_store_unavailable") }
    if code == AssistantUiError.retailAccessRequired { return String(localized: "assistant_error_retail_access") }
    if code == AssistantUiError.retailSearchFailed { return String(localized: "assistant_error_retail_search_failed") }
    if code == AssistantUiError.replacementUnavailable { return String(localized: "assistant_error_replacement_unavailable") }
    if code == AssistantUiError.dinnerSelectionUnavailable { return String(localized: "assistant_error_dinner_selection_unavailable") }
    if code == AssistantUiError.dinnerSelectionStale { return String(localized: "assistant_error_dinner_selection_stale") }
    return String(localized: "assistant_error_generic")
}
