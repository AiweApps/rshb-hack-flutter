import SwiftUI
import SharedLogic

/// The failed request: what went wrong, retry when it can help, and «New scan».
struct ResultErrorPanel: View {
    let failure: ScanFailure
    let onRetry: () -> Void
    let onNewScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                AppIcon(systemName: "exclamationmark.triangle.fill")
            }
            .foregroundStyle(AppTheme.bad)
            Text(text)
                .font(.body)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { actions }
                VStack(spacing: 10) { actions }
            }
            .controlSize(.large)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .sensoryFeedback(.warning, trigger: failure.kind)
    }

    @ViewBuilder
    private var actions: some View {
        if failure.retryable {
            Button(action: onRetry) {
                Text(String(localized: "scan_error_retry")).frame(maxWidth: .infinity)
            }
            .appPrimaryButtonStyle()
        }
        Button(action: onNewScan) {
            Text(String(localized: "result_new_scan")).frame(maxWidth: .infinity)
        }
        .appSecondaryButtonStyle()
    }

    private var title: String {
        let kind = failure.kind
        if kind == ScanFailureKind.noAccess { return String(localized: "scan_error_no_access") }
        if kind == ScanFailureKind.tooLarge { return String(localized: "scan_error_too_large") }
        if kind == ScanFailureKind.format { return String(localized: "scan_error_format") }
        if kind == ScanFailureKind.unprocessed || kind == ScanFailureKind.badRoi {
            return String(localized: "scan_error_unprocessed")
        }
        if kind == ScanFailureKind.tooMany { return String(localized: "scan_error_too_many") }
        if kind == ScanFailureKind.service { return String(localized: "scan_error_service") }
        if kind == ScanFailureKind.busy { return String(localized: "scan_error_busy") }
        if kind == ScanFailureKind.timeout { return String(localized: "scan_error_timeout") }
        if kind == ScanFailureKind.noResponse || kind == ScanFailureKind.offline {
            return String(localized: "scan_error_no_response")
        }
        if kind == ScanFailureKind.photoOpen { return String(localized: "scan_error_photo_open") }
        return String(localized: "scan_error_title_default")
    }

    private var text: String {
        let kind = failure.kind
        if kind == ScanFailureKind.noAccess { return String(localized: "scan_error_text_no_access") }
        if kind == ScanFailureKind.tooLarge { return String(localized: "scan_error_text_too_large") }
        if kind == ScanFailureKind.format { return String(localized: "scan_error_text_format") }
        if kind == ScanFailureKind.unprocessed { return String(localized: "scan_error_text_unprocessed") }
        if kind == ScanFailureKind.badRoi { return String(localized: "scan_error_text_bad_roi") }
        if kind == ScanFailureKind.tooMany { return String(localized: "scan_error_text_too_many") }
        if kind == ScanFailureKind.service { return String(localized: "scan_error_text_service") }
        if kind == ScanFailureKind.busy { return String(localized: "scan_error_text_busy") }
        if kind == ScanFailureKind.timeout { return String(localized: "scan_error_text_timeout") }
        if kind == ScanFailureKind.offline || kind == ScanFailureKind.noResponse {
            return String(localized: "scan_error_text_offline")
        }
        if kind == ScanFailureKind.photoOpen { return String(localized: "scan_error_text_photo_open") }
        return String(localized: "scan_error_text_default")
    }
}
