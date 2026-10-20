import SwiftUI

/// Nothing scanned yet, with the way to the camera.
struct HistoryEmptyView: View {
    let onScanNow: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "history_empty_title"), appSymbol: "clock.arrow.circlepath", iconSize: 48)
        } description: {
            Text(String(localized: "history_empty_body"))
        } actions: {
            Button(String(localized: "history_empty_action"), action: onScanNow)
                .appPrimaryButtonStyle()
        }
    }
}
