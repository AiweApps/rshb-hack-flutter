import SwiftUI
import SharedLogic

/// Reusable full-space error state: an icon + message matched to the `AppError` case,
/// and an optional retry button. Pass `onRetry: nil` to hide the button entirely
/// (e.g. inline errors where retrying just means submitting the form again).
struct ErrorStateView: View {
    let error: AppError
    let onRetry: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(AppErrorText.message(for: error), appSymbol: AppErrorText.symbolName(for: error), iconSize: 48)
        } actions: {
            if let onRetry {
                Button(String(localized: "action_retry"), action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
