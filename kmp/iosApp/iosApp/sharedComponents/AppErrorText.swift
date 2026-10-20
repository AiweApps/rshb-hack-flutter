import Foundation
import SharedLogic

/// Single place that maps the shared `AppError` domain model to user-facing text and
/// an SF Symbol. Keeps every screen's error branch consistent without duplicating a
/// switch per view.
enum AppErrorText {
    static func message(for error: AppError) -> String {
        switch error {
        case is AppError.Network:
            String(localized: "error_network")
        case is AppError.Timeout:
            String(localized: "error_timeout")
        case is AppError.Unauthorized:
            String(localized: "error_unauthorized")
        case is AppError.Server:
            String(localized: "error_server")
        default:
            // Covers AppError.Unknown and any future case we haven't mapped yet.
            String(localized: "error_unknown")
        }
    }

    static func symbolName(for error: AppError) -> String {
        switch error {
        case is AppError.Network:
            "wifi.slash"
        case is AppError.Timeout:
            "clock.badge.exclamationmark"
        case is AppError.Unauthorized:
            "lock.slash"
        case is AppError.Server:
            "server.rack"
        default:
            "exclamationmark.triangle"
        }
    }
}
